#include "otpch.h"

#include "connection_io.h"

#include <boost/asio/buffers_iterator.hpp>
#include <boost/beast/core/flat_buffer.hpp>
#include <boost/beast/websocket/error.hpp>

namespace asio = boost::asio;
namespace beast = boost::beast;
namespace websocket = beast::websocket;

namespace {

class TcpConnectionIO final : public ConnectionIO
{
public:
	explicit TcpConnectionIO(asio::ip::tcp::socket&& socket) : socket(std::move(socket)) {}

	void asyncRead(uint8_t* data, std::size_t size, IOHandler handler) override
	{
		asio::async_read(socket, asio::buffer(data, size), std::move(handler));
	}

	void asyncWrite(const uint8_t* data, std::size_t size, IOHandler handler) override
	{
		asio::async_write(socket, asio::buffer(data, size), std::move(handler));
	}

	void close() override
	{
		boost::system::error_code error;
		socket.shutdown(asio::ip::tcp::socket::shutdown_both, error);
		socket.close(error);
	}

	Address getRemoteAddress(boost::system::error_code& error) const override
	{
		return socket.remote_endpoint(error).address();
	}

	asio::any_io_executor getExecutor() override { return socket.get_executor(); }

private:
	asio::ip::tcp::socket socket;
};

class WebSocketConnectionIO final : public ConnectionIO, public std::enable_shared_from_this<WebSocketConnectionIO>
{
public:
	explicit WebSocketConnectionIO(websocket::stream<asio::ip::tcp::socket>&& stream) : stream(std::move(stream)) {}

	void asyncRead(uint8_t* data, std::size_t size, IOHandler handler) override
	{
		assert(!pendingRead.has_value());
		pendingRead.emplace(PendingRead{data, size, std::move(handler)});
		tryFulfillRead();
	}

	void asyncWrite(const uint8_t* data, std::size_t size, IOHandler handler) override
	{
		stream.binary(true);
		stream.async_write(asio::buffer(data, size), std::move(handler));
	}

	void close() override
	{
		boost::system::error_code error;
		stream.next_layer().shutdown(asio::ip::tcp::socket::shutdown_both, error);
		stream.next_layer().close(error);
	}

	Address getRemoteAddress(boost::system::error_code& error) const override
	{
		return stream.next_layer().remote_endpoint(error).address();
	}

	asio::any_io_executor getExecutor() override { return stream.get_executor(); }

private:
	struct PendingRead
	{
		uint8_t* data;
		std::size_t size;
		IOHandler handler;
	};

	void tryFulfillRead()
	{
		if (!pendingRead) {
			return;
		}

		const auto available = bufferedBytes.size() - bufferedOffset;
		if (available >= pendingRead->size) {
			std::memcpy(pendingRead->data, bufferedBytes.data() + bufferedOffset, pendingRead->size);
			bufferedOffset += pendingRead->size;
			compactBufferedBytes();

			auto handler = std::move(pendingRead->handler);
			const auto size = pendingRead->size;
			pendingRead.reset();

			asio::post(stream.get_executor(), [handler = std::move(handler), size]() mutable {
				handler({}, size);
			});
			return;
		}

		if (readInProgress) {
			return;
		}

		readInProgress = true;
		auto self = shared_from_this();
		stream.async_read(frameBuffer, [self](beast::error_code ec, std::size_t bytesTransferred) {
			self->onFrameRead(ec, bytesTransferred);
		});
	}

	void onFrameRead(const beast::error_code& error, std::size_t /*bytesTransferred*/)
	{
		readInProgress = false;
		if (error) {
			failPendingRead(error);
			return;
		}

		if (!stream.got_binary()) {
			failPendingRead(websocket::error::bad_data_frame);
			return;
		}

		const auto data = frameBuffer.cdata();
		bufferedBytes.insert(bufferedBytes.end(), asio::buffers_begin(data), asio::buffers_end(data));
		frameBuffer.consume(frameBuffer.size());

		tryFulfillRead();
	}

	void failPendingRead(const boost::system::error_code& error)
	{
		if (!pendingRead) {
			return;
		}

		auto handler = std::move(pendingRead->handler);
		pendingRead.reset();

		asio::post(stream.get_executor(), [handler = std::move(handler), error]() mutable { handler(error, 0); });
	}

	void compactBufferedBytes()
	{
		if (bufferedOffset == 0) {
			return;
		}

		if (bufferedOffset >= bufferedBytes.size()) {
			bufferedBytes.clear();
			bufferedOffset = 0;
			return;
		}

		if (bufferedOffset >= bufferedBytes.size() / 2) {
			bufferedBytes.erase(bufferedBytes.begin(), bufferedBytes.begin() + static_cast<std::ptrdiff_t>(bufferedOffset));
			bufferedOffset = 0;
		}
	}

	websocket::stream<asio::ip::tcp::socket> stream;
	beast::flat_buffer frameBuffer;
	std::vector<uint8_t> bufferedBytes;
	std::size_t bufferedOffset = 0;
	std::optional<PendingRead> pendingRead;
	bool readInProgress = false;
};

} // namespace

ConnectionIO_ptr make_tcp_connection_io(asio::ip::tcp::socket&& socket)
{
	return std::make_shared<TcpConnectionIO>(std::move(socket));
}

ConnectionIO_ptr make_websocket_connection_io(websocket::stream<asio::ip::tcp::socket>&& stream)
{
	return std::make_shared<WebSocketConnectionIO>(std::move(stream));
}
