#ifndef FS_CONNECTION_IO_H
#define FS_CONNECTION_IO_H

#include <string_view>

#include <boost/asio/ip/tcp.hpp>
#include <boost/beast/websocket/stream.hpp>

class ConnectionIO;
using ConnectionIO_ptr = std::shared_ptr<ConnectionIO>;

class ConnectionIO
{
public:
	using IOHandler = std::function<void(const boost::system::error_code&, std::size_t)>;
	using Address = boost::asio::ip::address;

	virtual ~ConnectionIO() = default;

	virtual void asyncRead(uint8_t* data, std::size_t size, IOHandler handler) = 0;
	virtual void asyncWrite(const uint8_t* data, std::size_t size, IOHandler handler) = 0;
	virtual void close(bool force, std::string_view reason) = 0;
	virtual Address getRemoteAddress(boost::system::error_code& error) const = 0;
	virtual boost::asio::any_io_executor getExecutor() = 0;
};

ConnectionIO_ptr make_tcp_connection_io(boost::asio::ip::tcp::socket&& socket);
ConnectionIO_ptr make_websocket_connection_io(
    boost::beast::websocket::stream<boost::asio::ip::tcp::socket>&& stream);

#endif // FS_CONNECTION_IO_H
