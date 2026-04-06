#pragma once

#include "../connection.h"
#include "../database.h"
#include "../enums.h"

#include <boost/beast/http/status.hpp>
#include <boost/json/value.hpp>

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace tfs::http::auth {

// Shared account/session helpers for the session-based HTTP flows.
struct SessionAccount
{
	uint32_t accountId = 0;
	int64_t premiumEndsAt = 0;
	Connection::Address ip;
	std::string sessionKey;
};

std::string trimCopy(std::string_view value);
std::string normalizeEmail(std::string_view email);
std::string normalizeCharacterName(std::string_view value);

bool isValidEmail(std::string_view email);
bool isValidPassword(std::string_view password);
bool isValidCharacterName(std::string_view name);

bool accountEmailExists(Database& db, std::string_view email);
bool characterNameExists(Database& db, std::string_view name);

std::string buildInternalAccountName(Database& db, std::string_view email);
uint16_t getDefaultLookType(PlayerSex_t sex);

std::optional<std::string> createSession(Database& db, uint32_t accountId, std::string_view ip);
std::optional<SessionAccount> loadSessionAccount(Database& db, std::string_view encodedSessionKey);

std::pair<boost::beast::http::status, boost::json::value> buildLoginResponse(Database& db, uint32_t accountId,
                                                                              std::string_view sessionKey,
                                                                              int64_t premiumEndsAt);

} // namespace tfs::http::auth
