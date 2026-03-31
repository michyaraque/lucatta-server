#include "otpch.h"

#include "websocket.h"

#include "connection.h"
#include "connection_io.h"
#include "protocolgame.h"

#include <boost/asio/strand.hpp>
#include <boost/beast/http/field.hpp>
#include <boost/beast/websocket.hpp>
#include <fmt/core.h>

namespace asio = boost::asio;
namespace beast = boost::beast;
namespace websocket = beast::websocket;

namespace tfs::ws {

namespace {

struct ConnectBlock
{
	uint64_t lastAttempt;
	uint64_t blockTime = 0;
	uint32_t count = 1;
};

bool acceptConnection(const Connection::Address& clientIP)
{
	static std::recursive_mutex mutex;
	std::lock_guard lock{mutex};

	const uint64_t currentTime = OTSYS_TIME();
	static std::map<Connection::Address, ConnectBlock> ipConnectMap;

	auto it = ipConnectMap.find(clientIP);
	if (it == ipConnectMap.end()) {
		ipConnectMap.emplace(clientIP, ConnectBlock{.lastAttempt = currentTime});
		return true;
	}

	auto& connectBlock = it->second;
	if (connectBlock.blockTime > currentTime) {
		connectBlock.blockTime += 250;
		return false;
	}

	const int64_t timeDiff = currentTime - connectBlock.lastAttempt;
	connectBlock.lastAttempt = currentTime;
	if (timeDiff <= 5000) {
		if (++connectBlock.count > 5) {
			connectBlock.count = 0;
			if (timeDiff <= 500) {
				connectBlock.blockTime = currentTime + 3000;
				return false;
			}
		}
	} else {
		connectBlock.count = 1;
	}

	return true;
}

class Session final : public std::enable_shared_from_this<Session>
{
public:
	explicit Session(asio::ip::tcp::socket&& socket) : stream(std::move(socket)) {}

	void run()
	{
		stream.set_option(websocket::stream_base::timeout::suggested(beast::role_type::server));
		stream.set_option(websocket::stream_base::decorator([](websocket::response_type& response) {
			response.set(beast::http::field::server, "The Forgotten Server WebSocket");
		}));
		stream.binary(true);
		stream.read_message_max(NETWORKMESSAGE_MAXSIZE);

		stream.async_accept([self = shared_from_this()](beast::error_code ec) { self->onAccept(ec); });
	}

private:
	void onAccept(const beast::error_code& error)
	{
		if (error) {
			fmt::print(stderr, "[websocket] accept failed: {}\n", error.message());
			return;
		}

		auto connection =
		    ConnectionManager::getInstance().createConnection(make_websocket_connection_io(std::move(stream)), nullptr);
		connection->accept(std::make_shared<ProtocolGame>(connection));
	}

	websocket::stream<asio::ip::tcp::socket> stream;
};

class Listener final : public std::enable_shared_from_this<Listener>
{
public:
	Listener(asio::io_context& ioc, asio::ip::tcp::acceptor&& acceptor) : ioc(ioc), acceptor(std::move(acceptor)) {}

	void run() { accept(); }

private:
	void accept()
	{
		acceptor.async_accept(asio::make_strand(ioc),
		                      [self = shared_from_this()](beast::error_code ec, asio::ip::tcp::socket socket) {
			                      self->onAccept(ec, std::move(socket));
		                      });
	}

	void onAccept(const beast::error_code& error, asio::ip::tcp::socket socket)
	{
		if (error) {
			if (error != asio::error::operation_aborted) {
				fmt::print(stderr, "[websocket] listener accept failed: {}\n", error.message());
				accept();
			}
			return;
		}

		boost::system::error_code remoteEndpointError;
		const auto remoteIp = socket.remote_endpoint(remoteEndpointError).address();
		boost::system::error_code socketOptionError;
		socket.set_option(asio::ip::tcp::no_delay{true}, socketOptionError);
		if (remoteEndpointError || socketOptionError || !acceptConnection(remoteIp)) {
			boost::system::error_code closeError;
			socket.shutdown(asio::ip::tcp::socket::shutdown_both, closeError);
			socket.close(closeError);
			accept();
			return;
		}

		std::make_shared<Session>(std::move(socket))->run();
		accept();
	}

	asio::io_context& ioc;
	asio::ip::tcp::acceptor acceptor;
};

std::shared_ptr<Listener> makeListener(asio::io_context& ioc, asio::ip::tcp::endpoint endpoint)
{
	asio::ip::tcp::acceptor acceptor{asio::make_strand(ioc)};

	beast::error_code error;
	if (acceptor.open(endpoint.protocol(), error); error) {
		throw std::runtime_error(error.message());
	}

	if (endpoint.address().is_v6()) {
		asio::ip::v6_only option;
		acceptor.get_option(option, error);
		if (error) {
			throw std::runtime_error(error.message());
		}

		if (option) {
			acceptor.set_option(asio::ip::v6_only{false}, error);
			if (error) {
				throw std::runtime_error(error.message());
			}
		}
	}

	if (acceptor.set_option(asio::socket_base::reuse_address(true), error); error) {
		throw std::runtime_error(error.message());
	}

	if (acceptor.bind(endpoint, error); error) {
		throw std::runtime_error(error.message());
	}

	if (acceptor.listen(asio::socket_base::max_listen_connections, error); error) {
		throw std::runtime_error(error.message());
	}

	return std::make_shared<Listener>(ioc, std::move(acceptor));
}

asio::io_context ioc;
std::vector<std::thread> workers;

} // namespace

void start(bool bindOnlyOtsIP, std::string_view otsIP, unsigned short port /*= 0*/, int threads /*= 1*/)
{
	if (port == 0 || threads < 1 || !workers.empty()) {
		return;
	}

	ioc.restart();

	asio::ip::address address = asio::ip::address_v6::any();
	if (bindOnlyOtsIP) {
		address = asio::ip::make_address(otsIP);
	}

	fmt::print(">> Starting WebSocket server on {:s}:{:d} with {:d} threads.\n", address.to_string(), port, threads);

	auto listener = makeListener(ioc, {address, port});
	listener->run();

	workers.reserve(threads);
	for (auto i = 0; i < threads; ++i) {
		workers.emplace_back([] { ioc.run(); });
	}
}

void stop()
{
	if (workers.empty()) {
		return;
	}

	fmt::print(">> Stopping WebSocket server...\n");

	ioc.stop();
	for (auto& worker : workers) {
		worker.join();
	}
	workers.clear();

	fmt::print(">> Stopped WebSocket server.\n");
}

} // namespace tfs::ws
