// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#include "otpch.h"

#include "appearance_catalog.h"

#include <appearances.pb.h>

#include <fstream>

namespace {

AppearanceItemGroup getAppearanceItemGroup(const Canary::protobuf::appearances::AppearanceFlags& flags)
{
	if (flags.show_off_socket()) {
		return AppearanceItemGroup::Podium;
	}
	if (flags.container()) {
		return AppearanceItemGroup::Container;
	}
	if (flags.has_bank()) {
		return AppearanceItemGroup::Ground;
	}
	if (flags.liquidcontainer()) {
		return AppearanceItemGroup::Fluid;
	}
	if (flags.liquidpool()) {
		return AppearanceItemGroup::Splash;
	}
	return AppearanceItemGroup::None;
}

bool isAppearanceMoveable(const auto& flags)
{
	if (flags.unmove()) {
		return false;
	}

	return flags.take();
}

} // namespace

bool AppearanceCatalog::load(const std::string& file, std::string& error)
{
	using namespace Canary::protobuf::appearances;

	clear();

	std::fstream fileStream(file, std::ios::in | std::ios::binary);
	if (!fileStream.is_open()) {
		error = fmt::format("Failed to open appearance catalog: {}", file);
		return false;
	}

	GOOGLE_PROTOBUF_VERIFY_VERSION;

	Appearances appearances;
	if (!appearances.ParseFromIstream(&fileStream)) {
		error = fmt::format("Failed to parse appearance catalog: {}", file);
		return false;
	}

	for (int index = 0; index < appearances.object_size(); ++index) {
		const Appearance& object = appearances.object(index);
		if (!object.has_id() || !object.has_flags()) {
			continue;
		}

		const uint32_t rawId = object.id();
		if (rawId > std::numeric_limits<uint16_t>::max()) {
			continue;
		}

		if (rawId >= items_.size()) {
			items_.resize(rawId + 1);
		}

		const AppearanceFlags& flags = object.flags();
		AppearanceItemMetadata& item = items_[rawId];
		item.id = static_cast<uint16_t>(rawId);
		item.group = getAppearanceItemGroup(flags);
		item.name = object.name();
		item.description = object.description();
		item.speed = flags.has_bank() ? static_cast<uint16_t>(flags.bank().waypoints()) : 0;
		item.wareId = flags.has_market() ? static_cast<uint16_t>(flags.market().trade_as_object_id()) : 0;
		item.alwaysOnTopOrder = flags.clip() ? 1 : (flags.bottom() ? 2 : (flags.top() ? 3 : 0));
		item.lightLevel = flags.has_light() ? static_cast<uint8_t>(flags.light().brightness()) : 0;
		item.lightColor = flags.has_light() ? static_cast<uint8_t>(flags.light().color()) : 0;
		item.classification =
		    flags.has_upgradeclassification() ? static_cast<uint8_t>(flags.upgradeclassification().upgrade_classification())
		                                      : 0;
		item.stackable = flags.cumulative();
		item.useable = flags.usable();
		item.forceUse = flags.forceuse();
		item.multiUse = flags.multiuse();
		item.hasHeight = flags.has_height();
		item.blockSolid = flags.unpass();
		item.blockProjectile = flags.unsight();
		item.blockPathFind = flags.avoid();
		item.pickupable = flags.take();
		item.moveable = isAppearanceMoveable(flags);
		item.alwaysOnTop = item.alwaysOnTopOrder != 0;
		item.canWriteText = flags.has_write() || flags.has_write_once();
		item.canReadText = item.canWriteText || (flags.has_lenshelp() && flags.lenshelp().id() == 1112);
		item.isVertical = flags.has_hook() && flags.hook().direction() == HOOK_TYPE_SOUTH;
		item.isHorizontal = flags.has_hook() && flags.hook().direction() == HOOK_TYPE_EAST;
		item.isHangable = flags.hang();
		item.lookThrough = flags.ignore_look();
		item.rotatable = flags.rotate();
		item.showClientCharges = flags.wearout();
		item.showClientDuration = flags.expire() || flags.expirestop() || flags.clockexpire();
		item.isPodium = flags.show_off_socket();

		for (int frameIndex = 0; frameIndex < object.frame_group_size(); ++frameIndex) {
			const FrameGroup& frameGroup = object.frame_group(frameIndex);
			if (frameGroup.has_sprite_info() && frameGroup.sprite_info().has_animation()) {
				item.isAnimation = true;
				break;
			}
		}
	}

	return true;
}

void AppearanceCatalog::clear()
{
	items_.clear();
}
