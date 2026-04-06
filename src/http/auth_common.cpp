#include "../otpch.h"

#include "auth_common.h"

#include "../base64.h"
#include "../creature.h"
#include "../definitions.h"
#include "../game.h"
#include "../item.h"
#include "../rsa.h"
#include "../tools.h"

#include <fmt/format.h>

extern Game g_game;
extern Vocations g_vocations;

namespace beast = boost::beast;
namespace json = boost::json;
using boost::beast::http::status;

namespace {

int getPvpType()
{
	switch (g_game.getWorldType()) {
		case WORLD_TYPE_PVP:
			return 0;
		case WORLD_TYPE_NO_PVP:
			return 1;
		case WORLD_TYPE_PVP_ENFORCED:
			return 2;
	}

	std::unreachable();
}

json::array buildVocations()
{
	json::array vocations;

	for (const auto& [id, vocation] : g_vocations.getVocations()) {
		if (id == VOCATION_NONE) {
			continue;
		}

		vocations.push_back({
		    {"id", id},
		    {"name", vocation.getVocName()},
		});
	}

	return vocations;
}

uint8_t readRarityId(const Item* item)
{
	if (!item) {
		return 0;
	}

	const auto* rarityAttribute = item->getCustomAttribute("rarity");
	if (!rarityAttribute) {
		return 0;
	}

	if (const auto* value = boost::get<int64_t>(&rarityAttribute->value)) {
		return static_cast<uint8_t>(std::clamp<int64_t>(*value, 0, UINT8_MAX));
	}

	if (const auto* value = boost::get<double>(&rarityAttribute->value)) {
		return static_cast<uint8_t>(std::clamp<int32_t>(static_cast<int32_t>(std::lround(*value)), 0, UINT8_MAX));
	}

	if (const auto* value = boost::get<bool>(&rarityAttribute->value)) {
		return *value ? 1 : 0;
	}

	return 0;
}

json::value buildEquipmentVisualEntry(const Item* item)
{
	if (!item) {
		return json::value(nullptr);
	}

	const ItemType& itemType = Item::items[item->getID()];
	return json::object{
	    {"itemId", item->getID()},
	    {"outfitId", itemType.paperdollOutfitId},
	    {"rarity", readRarityId(item)},
	};
}

json::object buildAppearanceEquipment(Database& db, uint32_t playerId)
{
	json::object equipment{
	    {"weapon", nullptr},
	    {"helmet", nullptr},
	    {"armor", nullptr},
	    {"shield", nullptr},
	};

	auto result = db.storeQuery(fmt::format(
	    "SELECT `pid`, `itemtype`, `count`, `attributes` FROM `player_items` WHERE `player_id` = {:d} AND `pid` IN ({:d}, {:d}, {:d}, {:d})",
	    playerId, static_cast<uint32_t>(CONST_SLOT_HEAD), static_cast<uint32_t>(CONST_SLOT_ARMOR),
	    static_cast<uint32_t>(CONST_SLOT_RIGHT), static_cast<uint32_t>(CONST_SLOT_LEFT)));
	if (!result) {
		return equipment;
	}

	do {
		const uint32_t pid = result->getNumber<uint32_t>("pid");
		const uint16_t type = result->getNumber<uint16_t>("itemtype");
		const uint16_t count = result->getNumber<uint16_t>("count");
		const auto attributes = result->getString("attributes");

		PropStream propStream;
		propStream.init(attributes.data(), attributes.size());

		Item* item = Item::CreateItem(type, count);
		if (!item) {
			continue;
		}

		if (!item->unserializeAttr(propStream)) {
			std::cout << "WARNING: Serialize error in login equipment snapshot" << std::endl;
		}

		switch (pid) {
			case CONST_SLOT_HEAD:
				equipment["helmet"] = buildEquipmentVisualEntry(item);
				break;
			case CONST_SLOT_ARMOR:
				equipment["armor"] = buildEquipmentVisualEntry(item);
				break;
			case CONST_SLOT_RIGHT:
				equipment["weapon"] = buildEquipmentVisualEntry(item);
				break;
			case CONST_SLOT_LEFT:
				equipment["shield"] = buildEquipmentVisualEntry(item);
				break;
			default:
				break;
		}

		item->decrementReferenceCounter();
	} while (result->next());

	return equipment;
}

json::array buildCharacters(Database& db, uint32_t accountId, uint32_t& lastLogin)
{
	auto result = db.storeQuery(fmt::format(
	    "SELECT `id`, `name`, `level`, `vocation`, `lastlogin`, `sex`, `looktype`, `lookhead`, `lookbody`, `looklegs`, `lookfeet`, `lookaddons` FROM `players` WHERE `account_id` = {:d}",
	    accountId));

	json::array characters;
	lastLogin = 0;
	if (!result) {
		return characters;
	}

	do {
		auto vocation = g_vocations.getVocation(result->getNumber<uint32_t>("vocation"));
		assert(vocation);

		characters.push_back({
		    {"worldid", 0},
		    {"name", result->getString("name")},
		    {"level", result->getNumber<uint32_t>("level")},
		    {"vocationId", vocation->getId()},
		    {"vocation", vocation->getVocName()},
		    {"lastlogin", result->getNumber<uint64_t>("lastlogin")},
		    {"ismale", result->getNumber<uint16_t>("sex") == PLAYERSEX_MALE},
		    {"ishidden", false},
		    {"ismaincharacter", false},
		    {"tutorial", false},
		    {"outfitid", result->getNumber<uint32_t>("looktype")},
		    {"headcolor", result->getNumber<uint32_t>("lookhead")},
		    {"torsocolor", result->getNumber<uint32_t>("lookbody")},
		    {"legscolor", result->getNumber<uint32_t>("looklegs")},
		    {"detailcolor", result->getNumber<uint32_t>("lookfeet")},
		    {"addonsflags", result->getNumber<uint32_t>("lookaddons")},
		    {"appearance",
		     {
		         {"baseKind", result->getNumber<uint32_t>("looktype")},
		         {"weaponKind", 0},
		         {"helmetKind", 0},
		         {"armorKind", 0},
		         {"shieldKind", 0},
		         {"equipment", buildAppearanceEquipment(db, result->getNumber<uint32_t>("id"))},
		     }},
		    {"dailyrewardstate", 0},
		});

		lastLogin = std::max(lastLogin, result->getNumber<uint32_t>("lastlogin"));
	} while (result->next());

	return characters;
}

json::array buildWorlds()
{
	const auto websocketPort = getNumber(ConfigManager::WEBSOCKET_PORT);
	return json::array{
	    {
	        {"id", 0},
	        {"name", getString(ConfigManager::SERVER_NAME)},
	        {"externaladdressprotected", getString(ConfigManager::IP)},
	        {"externalportprotected", getNumber(ConfigManager::GAME_PORT)},
	        {"externaladdressunprotected", getString(ConfigManager::IP)},
	        {"externalportunprotected", getNumber(ConfigManager::GAME_PORT)},
	        {"websocketaddressprotected", getString(ConfigManager::IP)},
	        {"websocketportprotected", websocketPort},
	        {"websocketaddressunprotected", getString(ConfigManager::IP)},
	        {"websocketportunprotected", websocketPort},
	        {"previewstate", 0},
	        {"location", getString(ConfigManager::LOCATION)},
	        {"anticheatprotection", false},
	        {"pvptype", getPvpType()},
	    },
	};
}

std::string toLowerCopy(std::string_view value)
{
	std::string result(value);
	std::transform(result.begin(), result.end(), result.begin(),
	               [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
	return result;
}

} // namespace

std::string tfs::http::auth::trimCopy(std::string_view value)
{
	size_t start = 0;
	size_t end = value.size();

	while (start < end && std::isspace(static_cast<unsigned char>(value[start])) != 0) {
		++start;
	}

	while (end > start && std::isspace(static_cast<unsigned char>(value[end - 1])) != 0) {
		--end;
	}

	return std::string(value.substr(start, end - start));
}

std::string tfs::http::auth::normalizeEmail(std::string_view email)
{
	return toLowerCopy(trimCopy(email));
}

std::string tfs::http::auth::normalizeCharacterName(std::string_view value)
{
	return trimCopy(value);
}

bool tfs::http::auth::isValidEmail(std::string_view email)
{
	if (email.size() < 5 || email.size() > 254) {
		return false;
	}

	const auto atPos = email.find('@');
	if (atPos == std::string_view::npos || atPos == 0 || atPos + 1 >= email.size()) {
		return false;
	}

	if (email.find('@', atPos + 1) != std::string_view::npos) {
		return false;
	}

	const auto dotPos = email.find('.', atPos + 1);
	return dotPos != std::string_view::npos && dotPos + 1 < email.size();
}

bool tfs::http::auth::isValidPassword(std::string_view password)
{
	return password.size() >= 4 && password.size() <= 24;
}

bool tfs::http::auth::isValidCharacterName(std::string_view name)
{
	if (name.size() < 3 || name.size() > 16) {
		return false;
	}

	bool previousWasSpace = false;
	for (size_t i = 0; i < name.size(); ++i) {
		const unsigned char ch = static_cast<unsigned char>(name[i]);
		const bool isLetter = std::isalpha(ch) != 0;
		const bool isSpace = ch == ' ';
		const bool isHyphen = ch == '-';

		if (!isLetter && !isSpace && !isHyphen) {
			return false;
		}

		if (i == 0 && !isLetter) {
			return false;
		}

		if (isSpace) {
			if (previousWasSpace) {
				return false;
			}
			previousWasSpace = true;
			continue;
		}

		if (isHyphen && (i == 0 || i + 1 == name.size())) {
			return false;
		}

		previousWasSpace = false;
	}

	return true;
}

bool tfs::http::auth::accountEmailExists(Database& db, std::string_view email)
{
	return static_cast<bool>(
	    db.storeQuery(fmt::format("SELECT 1 FROM `accounts` WHERE `email` = {:s}", db.escapeString(email))));
}

bool tfs::http::auth::characterNameExists(Database& db, std::string_view name)
{
	return static_cast<bool>(db.storeQuery(
	    fmt::format("SELECT 1 FROM `players` WHERE LOWER(`name`) = LOWER({:s})", db.escapeString(name))));
}

std::string tfs::http::auth::buildInternalAccountName(Database& db, std::string_view email)
{
	std::string base;
	const auto atPos = email.find('@');
	const auto localPart = email.substr(0, atPos);

	for (const unsigned char ch : localPart) {
		if (std::isalnum(ch) != 0) {
			base.push_back(static_cast<char>(std::tolower(ch)));
		} else if (ch == '.' || ch == '_' || ch == '-') {
			base.push_back('_');
		}
	}

	if (base.empty()) {
		base = "account";
	}

	if (base.size() > 28) {
		base.resize(28);
	}

	std::string candidate = base;
	uint32_t suffix = 1;
	while (db.storeQuery(fmt::format("SELECT 1 FROM `accounts` WHERE `name` = {:s}", db.escapeString(candidate)))) {
		const std::string suffixText = fmt::format("_{:d}", suffix++);
		const size_t maxBaseLength = 32 > suffixText.size() ? 32 - suffixText.size() : 1;
		candidate = base.substr(0, std::min(base.size(), maxBaseLength)) + suffixText;
	}

	return candidate;
}

uint16_t tfs::http::auth::getDefaultLookType(PlayerSex_t sex)
{
	return 125;
	//return sex == PLAYERSEX_MALE ? 128 : 136;
}

std::optional<std::string> tfs::http::auth::createSession(Database& db, uint32_t accountId, std::string_view ip)
{
	std::string sessionKey = randomBytes(16);
	if (!db.executeQuery(
	        fmt::format("INSERT INTO `sessions` (`token`, `account_id`, `ip`) VALUES ({:s}, {:d}, INET6_ATON({:s}))",
	                    db.escapeString(sessionKey), accountId, db.escapeString(ip)))) {
		return std::nullopt;
	}

	return sessionKey;
}

std::optional<tfs::http::auth::SessionAccount> tfs::http::auth::loadSessionAccount(Database& db,
                                                                                    std::string_view encodedSessionKey)
{
	const std::string sessionKey = tfs::base64::decode(encodedSessionKey);
	if (sessionKey.empty()) {
		return std::nullopt;
	}

	auto result = db.storeQuery(fmt::format(
	    "SELECT `a`.`id` AS `account_id`, `a`.`premium_ends_at`, INET6_NTOA(`s`.`ip`) AS `session_ip` "
	    "FROM `accounts` `a` JOIN `sessions` `s` ON `a`.`id` = `s`.`account_id` "
	    "WHERE `s`.`token` = {:s} AND `s`.`expired_at` IS NULL",
	    db.escapeString(sessionKey)));
	if (!result) {
		return std::nullopt;
	}

	return SessionAccount{
	    .accountId = result->getNumber<uint32_t>("account_id"),
	    .premiumEndsAt = result->getNumber<int64_t>("premium_ends_at"),
	    .ip = boost::asio::ip::make_address(result->getString("session_ip")),
	    .sessionKey = sessionKey,
	};
}

std::pair<status, json::value> tfs::http::auth::buildLoginResponse(Database& db, uint32_t accountId,
                                                                   std::string_view sessionKey, int64_t premiumEndsAt)
{
	using namespace std::chrono;

	const auto now = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();
	uint32_t lastLogin = 0;
	json::array characters = buildCharacters(db, accountId, lastLogin);
	json::array worlds = buildWorlds();

	return {
	    status::ok,
	    {
	        {"session",
	         {
	             {"sessionkey", tfs::base64::encode(sessionKey)},
	             {"lastlogintime", lastLogin},
	             {"ispremium", premiumEndsAt >= now},
	             {"premiumuntil", premiumEndsAt},
	             {"status", "active"},
	             {"returnernotification", false},
	             {"showrewardnews", true},
	             {"isreturner", true},
	             {"recoverysetupcomplete", true},
	             {"fpstracking", false},
	             {"optiontracking", false},
	         }},
	        {"playdata",
	         {
	             {"worlds", worlds},
	             {"vocations", buildVocations()},
	             {"characters", characters},
	             {"transport",
	              {
	                  {"login", "session"},
	                  {"socket", "websocket"},
	                  {"clientversionmin", CLIENT_VERSION_MIN},
	                  {"clientversionmax", CLIENT_VERSION_MAX},
	                  {"clientversionstring", CLIENT_VERSION_STR},
	                  {"security",
	                   {
	                       {"algorithm", "rsa-xtea"},
	                       {"modulus", tfs::rsa::getPublicModulus()},
	                       {"exponent", tfs::rsa::getPublicExponent()},
	                       {"keybytes", tfs::rsa::getKeySize()},
	                   }},
	              }},
	         }},
	    },
	};
}
