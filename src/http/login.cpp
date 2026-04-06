#include "../otpch.h"

#include "login.h"

#include "auth_common.h"
#include "error.h"

#include "../definitions.h"
#include "../tools.h"

#include <fmt/format.h>

namespace json = boost::json;
using boost::beast::http::status;

std::pair<status, json::value> tfs::http::handle_login(const json::object& body, std::string_view ip)
{
	using namespace std::chrono;
	using namespace tfs::http::auth;

	auto emailField = body.if_contains("email");
	if (!emailField || !emailField->is_string()) {
		return make_error_response({.code = 3, .message = "Account email address or password is not correct."});
	}

	auto passwordField = body.if_contains("password");
	if (!passwordField || !passwordField->is_string()) {
		return make_error_response({.code = 3, .message = "Account email address or password is not correct."});
	}

	const std::string email = normalizeEmail(emailField->get_string());

	thread_local auto& db = Database::getInstance();
	auto result = db.storeQuery(fmt::format(
	    "SELECT `id`, `password`, `secret`, `premium_ends_at` FROM `accounts` WHERE `email` = {:s}",
	    db.escapeString(email)));
	if (!result) {
		return make_error_response({.code = 3, .message = "Account email address or password is not correct."});
	}

	const auto password = result->getString("password");
	if (!verifyPassword(password, passwordField->get_string())) {
		return make_error_response({.code = 3, .message = "Account email address or password is not correct."});
	}

	const auto now = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
	const auto secret = result->getString("secret");
	if (!secret.empty()) {
		auto token = body.if_contains("token");
		if (!token || !token->is_string()) {
			return make_error_response({.code = 6, .message = "Two-factor token required for authentication."});
		}

		uint64_t ticks = now / AUTHENTICATOR_PERIOD;
		if (token->get_string() != generateToken(secret, ticks) &&
		    token->get_string() != generateToken(secret, ticks - 1) &&
		    token->get_string() != generateToken(secret, ticks + 1)) {
			return make_error_response({.code = 6, .message = "Two-factor token required for authentication."});
		}
	}

	const uint32_t accountId = result->getNumber<uint32_t>("id");
	const int64_t premiumEndsAt = result->getNumber<int64_t>("premium_ends_at");

	const auto sessionKey = createSession(db, accountId, ip);
	if (!sessionKey) {
		return make_error_response();
	}

	return buildLoginResponse(db, accountId, *sessionKey, premiumEndsAt);
}
