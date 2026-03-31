// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#ifndef FS_APPEARANCE_CATALOG_H
#define FS_APPEARANCE_CATALOG_H

#include <cstdint>
#include <string>
#include <vector>

enum class AppearanceItemGroup : uint8_t {
	None,
	Ground,
	Container,
	Splash,
	Fluid,
	Podium,
};

struct AppearanceItemMetadata {
	uint16_t id = 0;
	AppearanceItemGroup group = AppearanceItemGroup::None;
	std::string name;
	std::string description;
	uint16_t speed = 0;
	uint16_t wareId = 0;
	uint8_t alwaysOnTopOrder = 0;
	uint8_t lightLevel = 0;
	uint8_t lightColor = 0;
	uint8_t classification = 0;
	bool stackable = false;
	bool isAnimation = false;
	bool useable = false;
	bool forceUse = false;
	bool multiUse = false;
	bool hasHeight = false;
	bool blockSolid = false;
	bool blockProjectile = false;
	bool blockPathFind = false;
	bool pickupable = false;
	bool moveable = true;
	bool alwaysOnTop = false;
	bool canReadText = false;
	bool canWriteText = false;
	bool isVertical = false;
	bool isHorizontal = false;
	bool isHangable = false;
	bool lookThrough = false;
	bool rotatable = false;
	bool showClientCharges = false;
	bool showClientDuration = false;
	bool isPodium = false;
};

class AppearanceCatalog {
public:
	bool load(const std::string& file, std::string& error);
	const std::vector<AppearanceItemMetadata>& items() const { return items_; }
	void clear();

private:
	std::vector<AppearanceItemMetadata> items_;
};

#endif // FS_APPEARANCE_CATALOG_H
