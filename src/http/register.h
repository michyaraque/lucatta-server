#pragma once

#include <boost/beast/http/status.hpp>
#include <boost/json/value.hpp>

#include <string_view>
#include <utility>

namespace tfs::http {

std::pair<boost::beast::http::status, boost::json::value> handle_register(const boost::json::object& body,
                                                                          std::string_view ip);
std::pair<boost::beast::http::status, boost::json::value> handle_new_character(const boost::json::object& body,
                                                                               std::string_view ip);

} // namespace tfs::http
