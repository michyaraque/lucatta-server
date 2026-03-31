#include "router.h"

#include "cacheinfo.h"
#include "error.h"
#include "login.h"

#include <boost/json/monotonic_resource.hpp>
#include <boost/json/parse.hpp>
#include <boost/json/serialize.hpp>

namespace beast = boost::beast;
namespace json = boost::json;

namespace {

auto router(std::string_view type, const json::object& body, std::string_view ip)
{
	using namespace tfs::http;

	if (type == "cacheinfo") {
		return handle_cacheinfo(body, ip);
	}
	if (type == "login") {
		return handle_login(body, ip);
	}

	return make_error_response();
}

thread_local json::monotonic_resource mr;

} // namespace

beast::http::message_generator tfs::http::handle_request(const beast::http::request<beast::http::string_body>& req,
                                                         std::string_view ip)
{
	if (req.method() == beast::http::verb::options) {
		beast::http::response<beast::http::string_body> res{beast::http::status::no_content, req.version()};
		auto origin = req[beast::http::field::origin];
		res.set("Access-Control-Allow-Origin", origin.empty() ? "*" : origin);
		res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
		res.set("Access-Control-Allow-Headers", "Content-Type");
		res.set("Access-Control-Allow-Credentials", "true");
		res.set("Vary", "Origin");
		res.keep_alive(req.keep_alive());
		return res;
	}

	auto&& [status, responseBody] = [&req, ip]() {
		boost::system::error_code ec;
		auto requestBody = json::parse(req.body(), ec, &mr);
		if (ec || !requestBody.is_object()) {
			return make_error_response({.code = 2, .message = "Invalid request body."});
		}

		const auto& requestBodyObj = requestBody.get_object();
		auto typeField = requestBodyObj.if_contains("type");
		if (!typeField || !typeField->is_string()) {
			return make_error_response({.code = 2, .message = "Invalid request type."});
		}

		return router(typeField->get_string(), requestBodyObj, ip);
	}();

	beast::http::response<beast::http::string_body> res{status, req.version()};
	auto origin = req[beast::http::field::origin];
	res.set("Access-Control-Allow-Origin", origin.empty() ? "*" : origin);
	res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
	res.set("Access-Control-Allow-Headers", "Content-Type");
	res.set("Access-Control-Allow-Credentials", "true");
	res.set("Vary", "Origin");
	res.body() = json::serialize(responseBody);
	res.keep_alive(req.keep_alive());
	res.prepare_payload();
	return res;
}
