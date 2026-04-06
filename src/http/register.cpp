#include "../otpch.h"

#include "register.h"

#include "auth_common.h"
#include "error.h"

#include "../tools.h"

#include <fmt/format.h>

extern Vocations g_vocations;

namespace json = boost::json;
using boost::beast::http::status;

std::pair<status, json::value> tfs::http::handle_register(const json::object& body, std::string_view ip)
{
	using namespace tfs::http::auth;

	auto emailField = body.if_contains("email");
	if (!emailField || !emailField->is_string()) {
		return make_error_response({.code = 4, .message = "Enter a valid email address."});
	}

	auto passwordField = body.if_contains("password");
	if (!passwordField || !passwordField->is_string()) {
		return make_error_response({.code = 4, .message = "Enter a valid password."});
	}

	const std::string email = normalizeEmail(emailField->get_string());
	if (!isValidEmail(email)) {
		return make_error_response({.code = 4, .message = "Enter a valid email address."});
	}

	const std::string password = trimCopy(passwordField->get_string());
	if (!isValidPassword(password)) {
		return make_error_response({.code = 4, .message = "Password must be between 4 and 24 characters."});
	}

	thread_local auto& db = Database::getInstance();
	if (accountEmailExists(db, email)) {
		return make_error_response({.code = 5, .message = "Email address is already registered."});
	}

	const std::string accountName = buildInternalAccountName(db, email);
	const std::string passwordHash = hashPassword(password);
	const int64_t createdAt = std::chrono::duration_cast<std::chrono::seconds>(
	                             std::chrono::system_clock::now().time_since_epoch())
	                             .count();

	if (!db.executeQuery(fmt::format(
	        "INSERT INTO `accounts` (`name`, `email`, `password`, `creation`) VALUES ({:s}, {:s}, {:s}, {:d})",
	        db.escapeString(accountName), db.escapeString(email), db.escapeString(passwordHash), createdAt))) {
		return make_error_response();
	}

	auto accountResult = db.storeQuery(
	    fmt::format("SELECT `id`, `premium_ends_at` FROM `accounts` WHERE `email` = {:s}", db.escapeString(email)));
	if (!accountResult) {
		return make_error_response();
	}

	const uint32_t accountId = accountResult->getNumber<uint32_t>("id");
	const int64_t premiumEndsAt = accountResult->getNumber<int64_t>("premium_ends_at");

	const auto sessionKey = createSession(db, accountId, ip);
	if (!sessionKey) {
		return make_error_response();
	}

	return buildLoginResponse(db, accountId, *sessionKey, premiumEndsAt);
}

std::pair<status, json::value> tfs::http::handle_new_character(const json::object& body, std::string_view ip)
{
	using namespace tfs::http::auth;

	auto sessionKeyField = body.if_contains("sessionkey");
	if (!sessionKeyField || !sessionKeyField->is_string()) {
		return make_error_response({.code = 7, .message = "Session expired. Please login again."});
	}

	thread_local auto& db = Database::getInstance();
	auto sessionAccount = loadSessionAccount(db, sessionKeyField->get_string());
	if (!sessionAccount || sessionAccount->accountId == 0) {
		return make_error_response({.code = 7, .message = "Session expired. Please login again."});
	}

	Connection::Address requestIP = boost::asio::ip::make_address(std::string(ip));
	if (!sessionAccount->ip.is_loopback() && sessionAccount->ip != requestIP) {
		return make_error_response({.code = 7, .message = "Session expired. Please login again."});
	}

	auto characterNameField = body.if_contains("characterName");
	if (!characterNameField || !characterNameField->is_string()) {
		return make_error_response({.code = 4, .message = "Character name format is invalid."});
	}

	const std::string characterName = normalizeCharacterName(characterNameField->get_string());
	if (!isValidCharacterName(characterName)) {
		return make_error_response({.code = 4, .message = "Character name format is invalid."});
	}

	auto countResult = db.storeQuery(fmt::format("SELECT COUNT(*) AS `count` FROM `players` WHERE `account_id` = {:d}",
	                                             sessionAccount->accountId));
	if (countResult && countResult->getNumber<uint32_t>("count") >= 5) {
		return make_error_response({.code = 5, .message = "You can only create up to 5 characters on this account."});
	}

	if (characterNameExists(db, characterName)) {
		return make_error_response({.code = 6, .message = "Character name is already taken."});
	}

	const auto sexValue = body.if_contains("sex");
	const PlayerSex_t sex =
	    sexValue && sexValue->is_int64() && sexValue->as_int64() == PLAYERSEX_MALE ? PLAYERSEX_MALE : PLAYERSEX_FEMALE;

	uint16_t vocationId = 1;
	if (const auto vocationValue = body.if_contains("vocationId"); vocationValue && vocationValue->is_int64()) {
		vocationId = static_cast<uint16_t>(vocationValue->as_int64());
	}

	if (vocationId == VOCATION_NONE || !g_vocations.getVocation(vocationId)) {
		return make_error_response({.code = 4, .message = "Invalid vocation selected."});
	}

	if (!db.executeQuery(fmt::format(
	        "INSERT INTO `players` (`name`, `account_id`, `group_id`, `sex`, `vocation`, `health`, `healthmax`, `mana`, "
	        "`manamax`, `looktype`, `lookhead`, `lookbody`, `looklegs`, `lookfeet`, `town_id`, `lastip`) "
	        "VALUES ({:s}, {:d}, 1, {:d}, {:d}, 150, 150, 55, 55, {:d}, 78, 132, 114, 0, 1, INET6_ATON({:s}))",
	        db.escapeString(characterName), sessionAccount->accountId, static_cast<uint16_t>(sex), vocationId,
	        getDefaultLookType(sex), db.escapeString(ip)))) {
		return make_error_response();
	}

	return buildLoginResponse(db, sessionAccount->accountId, sessionAccount->sessionKey, sessionAccount->premiumEndsAt);
}
