#include "../otpch.h"

#include "login.h"

#include "../base64.h"
#include "../creature.h"
#include "../definitions.h"
#include "../game.h"
#include "../item.h"
#include "../rsa.h"
#include "error.h"

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
			std::cout << "WARNING: Serialize error in handle_login equipment snapshot" << std::endl;
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

} // namespace

std::pair<status, json::value> tfs::http::handle_login(const json::object& body, std::string_view ip)
{
	using namespace std::chrono;

	auto emailField = body.if_contains("email");
	if (!emailField || !emailField->is_string()) {
		return make_error_response(
		    {.code = 3, .message = "Account email address or password is not correct."});
	}

	auto passwordField = body.if_contains("password");
	if (!passwordField || !passwordField->is_string()) {
		return make_error_response(
		    {.code = 3, .message = "Account email address or password is not correct."});
	}

	thread_local auto& db = Database::getInstance();
	auto result = db.storeQuery(fmt::format(
	    "SELECT `id`, `password`, `secret`, `premium_ends_at` FROM `accounts` WHERE `email` = {:s}",
	    db.escapeString(emailField->get_string())));
	if (!result) {
		return make_error_response(
		    {.code = 3, .message = "Account email address or password is not correct."});
	}

	auto password = result->getString("password");
	if (!verifyPassword(password, passwordField->get_string())) {
		return make_error_response(
		    {.code = 3, .message = "Account email address or password is not correct."});
	}

	auto now = duration_cast<seconds>(system_clock::now().time_since_epoch()).count();

	auto secret = result->getString("secret");
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

	auto accountId = result->getNumber<uint64_t>("id");
	auto premiumEndsAt = result->getNumber<int64_t>("premium_ends_at");
	const auto websocketPort = getNumber(ConfigManager::WEBSOCKET_PORT);

	std::string sessionKey = randomBytes(16);
	if (!db.executeQuery(
	        fmt::format("INSERT INTO `sessions` (`token`, `account_id`, `ip`) VALUES ({:s}, {:d}, INET6_ATON({:s}))",
	                    db.escapeString(sessionKey), accountId, db.escapeString(ip)))) {
		return make_error_response();
	}

	result = db.storeQuery(fmt::format(
	    "SELECT `id`, `name`, `level`, `vocation`, `lastlogin`, `sex`, `looktype`, `lookhead`, `lookbody`, `looklegs`, `lookfeet`, `lookaddons` FROM `players` WHERE `account_id` = {:d}",
	    accountId));

	json::array characters;
	uint32_t lastLogin = 0;
	if (result) {
		do {
			auto vocation = g_vocations.getVocation(result->getNumber<uint32_t>("vocation"));
			assert(vocation);

			characters.push_back({
			    {"worldid", 0}, // not implemented
			    {"name", result->getString("name")},
			    {"level", result->getNumber<uint32_t>("level")},
			    {"vocationId", vocation->getId()},
			    {"vocation", vocation->getVocName()},
			    {"lastlogin", result->getNumber<uint64_t>("lastlogin")},
			    {"ismale", result->getNumber<uint16_t>("sex") == PLAYERSEX_MALE},
			    {"ishidden", false},        // not implemented
			    {"ismaincharacter", false}, // not implemented
			    {"tutorial", false},        // not implemented
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
			    {"dailyrewardstate", 0}, // not implemented
			});

			lastLogin = std::max(lastLogin, result->getNumber<uint32_t>("lastlogin"));
		} while (result->next());
	}

	json::array worlds{
	    {
	        {"id", 0}, // not implemented
	        {"name", getString(ConfigManager::SERVER_NAME)},
	        {"externaladdressprotected", getString(ConfigManager::IP)},
	        {"externalportprotected", getNumber(ConfigManager::GAME_PORT)},
	        {"externaladdressunprotected", getString(ConfigManager::IP)},
	        {"externalportunprotected", getNumber(ConfigManager::GAME_PORT)},
	        {"websocketaddressprotected", getString(ConfigManager::IP)},
	        {"websocketportprotected", websocketPort},
	        {"websocketaddressunprotected", getString(ConfigManager::IP)},
	        {"websocketportunprotected", websocketPort},
	        {"previewstate", 0}, // not implemented
	        {"location", getString(ConfigManager::LOCATION)},
	        {"anticheatprotection", false}, // not implemented
	        {"pvptype", getPvpType()},
	    },
	};

	return {
	    status::ok,
	    {
	        {"session",
	         {
	             {"sessionkey", tfs::base64::encode(sessionKey)},
	             {"lastlogintime", lastLogin},
	             {"ispremium", premiumEndsAt >= now},
	             {"premiumuntil", premiumEndsAt},
	             // not implemented
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
