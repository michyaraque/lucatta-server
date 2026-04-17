local CODE_TOOLTIP = 105

local vocationNames = {
    ["none"] = 0,
    ["warrior"] = 1,
    ["archer"] = 2,
    ["mage"] = 3,
    ["shaman"] = 4,
    ["elite warrior"] = 11,
    ["royal archer"] = 12,
    ["master mage"] = 13,
    ["elder shaman"] = 14
}

local specialSkills = {
  [SPECIALSKILL_CRITICALHITCHANCE] = "cc",
  [SPECIALSKILL_CRITICALHITAMOUNT] = "ca",
  [SPECIALSKILL_LIFELEECHCHANCE] = "lc",
  [SPECIALSKILL_LIFELEECHAMOUNT] = "la",
  [SPECIALSKILL_MANALEECHCHANCE] = "mc",
  [SPECIALSKILL_MANALEECHAMOUNT] = "ma"
}

local skills = {
  [SKILL_FIST] = "fist",
  [SKILL_AXE] = "axe",
  [SKILL_SWORD] = "sword",
  [SKILL_CLUB] = "club",
  [SKILL_DISTANCE] = "dist",
  [SKILL_SHIELD] = "shield",
  [SKILL_FISHING] = "fish"
}

local stats = {
  [STAT_MAGICPOINTS] = "mag",
  [STAT_MAXHITPOINTS] = "maxhp",
  [STAT_MAXMANAPOINTS] = "maxmp"
}

local statsPercent = {
  [STAT_MAXHITPOINTS] = "maxhp_p",
  [STAT_MAXMANAPOINTS] = "maxmp_p"
}

local combatTypeNames = {
  [COMBAT_PHYSICALDAMAGE] = "Physical",
  [COMBAT_ENERGYDAMAGE] = "Energy",
  [COMBAT_EARTHDAMAGE] = "Earth",
  [COMBAT_FIREDAMAGE] = "Fire",
  [COMBAT_LIFEDRAIN] = "Lifedrain",
  [COMBAT_MANADRAIN] = "Manadrain",
  [COMBAT_HEALING] = "Healing",
  [COMBAT_DROWNDAMAGE] = "Drown",
  [COMBAT_ICEDAMAGE] = "Ice",
  [COMBAT_HOLYDAMAGE] = "Holy",
  [COMBAT_DEATHDAMAGE] = "Death"
}

local combatShortNames = {
  [COMBAT_PHYSICALDAMAGE] = "a_phys",
  [COMBAT_ENERGYDAMAGE] = "a_ene",
  [COMBAT_EARTHDAMAGE] = "a_earth",
  [COMBAT_FIREDAMAGE] = "a_fire",
  [COMBAT_LIFEDRAIN] = "a_ldrain",
  [COMBAT_MANADRAIN] = "a_mdrain",
  [COMBAT_HEALING] = "a_heal",
  [COMBAT_DROWNDAMAGE] = "a_drown",
  [COMBAT_ICEDAMAGE] = "a_ice",
  [COMBAT_HOLYDAMAGE] = "a_holy",
  [COMBAT_DEATHDAMAGE] = "a_death"
}

local LoginEvent = CreatureEvent("TooltipsLogin")

function LoginEvent.onLogin(player)
  player:registerEvent("TooltipsExtended")
  return true
end

local ExtendedEvent = CreatureEvent("TooltipsExtended")

function ExtendedEvent.onExtendedOpcode(player, opcode, buffer)
  if opcode == CODE_TOOLTIP then
    local status, data =
        pcall(
          function()
            return json.decode(buffer)
          end
        )
    if not status or not data then
      return
    end

    if #data == 4 then
      local pos = Position(
        tonumber(data[1]) or 0,
        tonumber(data[2]) or 0,
        tonumber(data[3]) or 0,
        tonumber(data[4]) or 0
      )
      local item = player:getItem(pos)
      player:sendItemTooltip(item)
    elseif #data == 1 then
      local item = Item(tonumber(data[1]) or 0)
      if item then
        player:sendItemTooltip(item)
      end
    end
  end
end

local function formatWorth(value)
  if not value or value <= 0 then
    return nil
  end

  local function fmt(n)
    if n >= 1000000000 then
      local main = math.floor(n / 1000000000)
      local rem  = n % 1000000000
      local s = main .. "kkk"
      if rem > 0 then s = s .. " and " .. fmt(rem) end
      return s
    elseif n >= 1000000 then
      local main = math.floor(n / 1000000)
      local rem  = n % 1000000
      local s = main .. "kk"
      if rem > 0 then s = s .. " and " .. fmt(rem) end
      return s
    elseif n >= 1000 then
      local main = math.floor(n / 1000)
      local rem  = n % 1000
      local s = main .. "k"
      if rem > 0 then s = s .. " and " .. fmt(rem) end
      return s
    else
      return tostring(n)
    end
  end

  return fmt(value)
end

function Player:sendItemTooltip(item)
  if item then
    local item_data = item:buildTooltip()
    if item_data then
      self:sendExtendedOpcode(CODE_TOOLTIP, json.encode({ action = "new", data = item_data }))
    end
  end
end

function Item:buildTooltip()
  local uid = self:getUniqueId()
  local itemType = self:getType()

	local name = itemType:getName()
	if self:getCount() > 1 then
		name = itemType:getPluralName()
	end

  local item_data = {
    uid = uid,
    itemName = name,
    itemId = itemType:getId()
  }

  if itemType:getDescription():len() > 0 then
    item_data.desc = itemType:getDescription()
  end

  if self:getType():isUpgradable() or self:getType():canHaveItemLevel() then
    item_data.itemLevel = self:getItemLevel()
  end

  local requiredLevel = itemType:getRequiredLevel()
  if US_CONFIG and US_CONFIG.REQUIRE_LEVEL and (itemType:isUpgradable() or itemType:canHaveItemLevel()) and not self:isLimitless() then
    requiredLevel = math.max(requiredLevel, self:getItemLevel())
  end

  if requiredLevel >= 1 then
    item_data.reqLvl = requiredLevel
  end

  if itemType:getVocationString():len() > 0 then
    local vocString = itemType:getVocationString()
    local vocs = {}

    vocString = vocString:gsub("%s+and%s+", ",")

    for voc in vocString:gmatch("([^,]+)") do
      voc = voc:match("^%s*(.-)%s*$"):lower():gsub("s$", "")
      if vocationNames[voc] then
        table.insert(vocs, vocationNames[voc])
      end
    end

    item_data.vocWield = vocs
  end

  local implicit = {}

  if itemType:getElementType() ~= COMBAT_NONE and combatTypeNames[itemType:getElementType()] then
    implicit.eleDmg = {
      type = combatTypeNames[itemType:getElementType()],
      value = itemType:getElementDamage()
    }
  end

  local allprot = itemType:getAbsorbPercent(0)

  if allprot ~= 0 then
    for i = 0, COMBAT_COUNT - 1 do
      if itemType:getAbsorbPercent(i) ~= allprot then
        allprot = 0
        break
      end
    end
  end

  if allprot == 0 then
    for i = 0, COMBAT_COUNT - 1 do
      if itemType:getAbsorbPercent(i) ~= 0 then
        local combatType = bit.lshift(1, i)
        if combatType ~= COMBAT_UNDEFINEDDAMAGE then
          implicit[combatShortNames[combatType]] = itemType:getAbsorbPercent(i)
        end
      end
    end
  else
    implicit.a_all = allprot
  end

  for key, value in pairs(specialSkills) do
    local s = itemType:getSpecialSkill(key)
    if s and s >= 1 then
      implicit[value] = s
    end
  end

  for key, value in pairs(skills) do
    local s = itemType:getSkill(key)
    if s and s >= 1 then
      implicit[value] = s
    end
  end

  for key, value in pairs(stats) do
    local s = itemType:getStat(key)
    if s and s >= 1 then
      implicit[value] = s
    end
  end

  for key, value in pairs(statsPercent) do
    local s = itemType:getStatPercent(key)
    if s and s >= 1 then
      implicit[value] = s - 100
    end
  end

  local healthGain = itemType:getHealthGain()
  if healthGain and healthGain > 0 then
    implicit.hpgain = healthGain
  end

  local healthTicks = itemType:getHealthTicks()
  if healthTicks and healthTicks > 0 then
    implicit.hpticks = healthTicks
  end

  local manaGain = itemType:getManaGain()
  if manaGain and manaGain > 0 then
    implicit.mpgain = manaGain
  end

  local manaTicks = itemType:getManaTicks()
  if manaTicks and manaTicks > 0 then
    implicit.mpticks = manaTicks
  end

  local speed = itemType:getSpeed()
  if speed and speed > 0 then
    implicit.speed = speed
  end

  --[[ if self:isContainer() then
    implicit.cap = self:getCapacity()
  end ]]

  if next(implicit) ~= nil then
    item_data.imp = implicit
  end

  if self:getType():isUpgradable() then
    if self:isUnidentified() then
      item_data.unidentified = true
    else
      item_data.uLevel = self:getUpgradeLevel()
      if self:isMirrored() then
        item_data.mirrored = true
      end
      if self:hasItemUniqueName() then
        item_data.superUnique = true
        item_data.uniqueName = self:getUniqueName()
      elseif self:getUnique() then
        item_data.unique = true
        item_data.uniqueName = self:getUniqueName()
      end
      if self:isSuperior() then
        item_data.superior = true
      end
      item_data.rarityId = self:getRarityId()
      item_data.maxAttr = self:getMaxSockets()
      item_data.attr = {}
      item_data.socketedSkulls = {}

      -- Aggregate bonuses by enchantId to combine duplicates
      -- Key: enchantId, Value: {total = sum, attr = US_ENCHANTMENT entry, isTrigger = bool}
      local aggregatedBonuses = {}

      -- First: Collect native bonuses (Slot{i}) - these are permanent
      for i = 1, self:getMaxSockets() do
        local enchant = self:getBonusAttribute(i)
        if enchant then
          local enchantId = enchant[1]
          local value = enchant[2]
          local attr = US_ENCHANTMENTS[enchantId]
          if attr then
            if not aggregatedBonuses[enchantId] then
              aggregatedBonuses[enchantId] = {
                total = 0,
                attr = attr,
                isTrigger = (attr.combatType == US_TYPES.TRIGGER)
              }
            end
            aggregatedBonuses[enchantId].total = aggregatedBonuses[enchantId].total + value
          end
        end
      end

      -- Second: Collect socketed jewel skull bonuses (SocketedSkull{i}) - these are removable
      for i = 1, self:getMaxSockets() do
        local skullId = self:getSocketedSkull(i)
        if skullId then
          local skullItemId = ItemType(skullId):getId()
          -- Use string key to avoid sparse array issues in JSON
          item_data.socketedSkulls[tostring(i)] = skullItemId
          local bonuses = self:getSocketedSkullBonuses(i)
          if bonuses then
            for _, bonus in ipairs(bonuses) do
              local enchantId = bonus.enchantId
              local value = bonus.value
              local attr = US_ENCHANTMENTS[enchantId]
              if attr then
                if not aggregatedBonuses[enchantId] then
                  aggregatedBonuses[enchantId] = {
                    total = 0,
                    attr = attr,
                    isTrigger = (attr.combatType == US_TYPES.TRIGGER)
                  }
                end
                aggregatedBonuses[enchantId].total = aggregatedBonuses[enchantId].total + value
              end
            end
          end
        end
      end

      -- Format aggregated bonuses, separating regular from trigger types
      local regularAttrs = {}
      local conditionAttrs = {}
      local triggerAttrs = {}

      for enchantId, data in pairs(aggregatedBonuses) do
        local formattedAttr = (data.attr.format(data.total):gsub("%%%%", "%%"))
        if data.attr.combatType == US_TYPES.CONDITION then
          table.insert(conditionAttrs, formattedAttr)
        elseif data.isTrigger then
          table.insert(triggerAttrs, formattedAttr)
        else
          table.insert(regularAttrs, formattedAttr)
        end
      end

      -- Add regular attributes first, then trigger attributes
      if self:isSuperior() then
        table.insert(item_data.attr, "Superior")
      end
      if self:hasItemUniqueName() then
        table.insert(item_data.attr, "Super Unique")
      elseif self:getUnique() then
        table.insert(item_data.attr, "Unique")
      end
      for _, attrText in ipairs(regularAttrs) do
        table.insert(item_data.attr, attrText)
      end
      for _, attrText in ipairs(conditionAttrs) do
        table.insert(item_data.attr, attrText)
      end
      for _, attrText in ipairs(triggerAttrs) do
        table.insert(item_data.attr, attrText)
      end
    end
  end

  if self:isJewelSkull() then
    initJewelSkullEnchantments()
    local config = self:getJewelSkullConfig()
    if config then
      item_data.isJewelSkull = true
      item_data.skullRarity = config.name
    end
    item_data.jewelBonuses = {}
    local bonuses = self:getJewelSkullBonuses()
    if bonuses then
      for _, bonus in ipairs(bonuses) do
        local attr = US_ENCHANTMENTS[bonus.enchantId]
        if attr then
          table.insert(item_data.jewelBonuses, (attr.format(bonus.value):gsub("%%%%", "%%")))
        end
      end
    end
  end

  item_data.stackable = itemType:isStackable()
  item_data.itemType = formatItemType(itemType)
  if itemType:getArmor() > 0 then
    if self:getAttribute(ITEM_ATTRIBUTE_ARMOR) > 0 then
      item_data.armor = self:getAttribute(ITEM_ATTRIBUTE_ARMOR)
    else
      item_data.armor = itemType:getArmor()
    end
  elseif itemType:getShootRange() > 1 then
    if self:getAttribute(ITEM_ATTRIBUTE_ATTACK) > 0 then
      item_data.attack = self:getAttribute(ITEM_ATTRIBUTE_ATTACK)
    else
      item_data.attack = itemType:getAttack()
    end
    if self:getAttribute(ITEM_ATTRIBUTE_HITCHANCE) > 0 then
      item_data.hitChance = self:getAttribute(ITEM_ATTRIBUTE_HITCHANCE)
    else
      item_data.hitChance = itemType:getHitChance()
    end
    item_data.shootRange = itemType:getShootRange()
  elseif itemType:getAttack() > 0 then
    if self:getAttribute(ITEM_ATTRIBUTE_ATTACK) > 0 then
      item_data.attack = self:getAttribute(ITEM_ATTRIBUTE_ATTACK)
    else
      item_data.attack = itemType:getAttack()
    end
    if self:getAttribute(ITEM_ATTRIBUTE_DEFENSE) > 0 then
      item_data.defense = self:getAttribute(ITEM_ATTRIBUTE_DEFENSE)
    else
      item_data.defense = itemType:getDefense()
    end
    if self:getAttribute(ITEM_ATTRIBUTE_EXTRADEFENSE) > 0 then
      item_data.extraDefense = self:getAttribute(ITEM_ATTRIBUTE_EXTRADEFENSE)
    else
      item_data.extraDefense = itemType:getExtraDefense()
    end
  elseif itemType:getDefense() > 0 then
    if self:getAttribute(ITEM_ATTRIBUTE_DEFENSE) > 0 then
      item_data.defense = self:getAttribute(ITEM_ATTRIBUTE_DEFENSE)
    else
      item_data.defense = itemType:getDefense()
    end
    if self:getAttribute(ITEM_ATTRIBUTE_EXTRADEFENSE) > 0 then
      item_data.extraDefense = self:getAttribute(ITEM_ATTRIBUTE_EXTRADEFENSE)
    else
      item_data.extraDefense = itemType:getExtraDefense()
    end
  end

  item_data.weight = self:getWeight()

  local worthValue = itemType:getWorth()
  if worthValue and worthValue > 0 then
    local count = self:getCount() or 1
    item_data.worth = formatWorth(worthValue * count)
  end

  return item_data
end

function ItemType:buildTooltip(count)
  if not count then
    count = 1
  end

  local item_data = {
    itemId = self:getId(),
    count = count,
    itemName = self:getName()
  }

  if self:getDescription():len() > 0 then
    item_data.desc = self:getDescription()
  end

  if self:getRequiredLevel() >= 1 then
    item_data.reqLvl = self:getRequiredLevel()
  end

  if self:getVocationString():len() > 0 then
    local vocString = self:getVocationString()
    local vocs = {}

    vocString = vocString:gsub("%s+and%s+", ",")

    for voc in vocString:gmatch("([^,]+)") do
      voc = voc:match("^%s*(.-)%s*$"):lower():gsub("s$", "")
      if vocationNames[voc] then
        table.insert(vocs, vocationNames[voc])
      end
    end

    item_data.vocWield = vocs
  end


  local implicit = {}

  if self:getElementType() ~= COMBAT_NONE and combatTypeNames[self:getElementType()] then
    implicit.eleDmg = {
      type = combatTypeNames[self:getElementType()],
      value = self:getElementDamage()
    }
  end

  local allprot = self:getAbsorbPercent(0)

  if allprot ~= 0 then
    for i = 0, COMBAT_COUNT - 1 do
      if self:getAbsorbPercent(i) ~= allprot then
        allprot = 0
        break
      end
    end
  end

  if allprot == 0 then
    for i = 0, COMBAT_COUNT - 1 do
      if self:getAbsorbPercent(i) ~= 0 then
        local combatType = bit.lshift(1, i)
        if combatType ~= COMBAT_UNDEFINEDDAMAGE then
          implicit[combatShortNames[combatType]] = self:getAbsorbPercent(i)
        end
      end
    end
  else
    implicit.a_all = allprot
  end

  for key, value in pairs(specialSkills) do
    local s = self:getSpecialSkill(key)
    if s and s >= 1 then
      implicit[value] = s
    end
  end

  for key, value in pairs(skills) do
    local s = self:getSkill(key)
    if s and s >= 1 then
      implicit[value] = s
    end
  end

  for key, value in pairs(stats) do
    local s = self:getStat(key)
    if s and s >= 1 then
      implicit[value] = s
    end
  end

  for key, value in pairs(statsPercent) do
    local s = self:getStatPercent(key)
    if s and s >= 1 then
      implicit[value] = s - 100
    end
  end

  local healthGain = self:getHealthGain()
  if healthGain and healthGain > 0 then
    implicit.hpgain = healthGain
  end

  local healthTicks = self:getHealthTicks()
  if healthTicks and healthTicks > 0 then
    implicit.hpticks = healthTicks
  end

  local manaGain = self:getManaGain()
  if manaGain and manaGain > 0 then
    implicit.mpgain = manaGain
  end

  local manaTicks = self:getManaTicks()
  if manaTicks and manaTicks > 0 then
    implicit.mpticks = manaTicks
  end

  local speed = self:getSpeed()
  if speed and speed > 0 then
    implicit.speed = speed
  end

  if self:isContainer() then
    implicit.cap = "Capacity " .. self:getCapacity()
  end


  if next(implicit) ~= nil then
    item_data.imp = implicit
  end

  item_data.itemType = formatItemType(self)
  if self:getArmor() > 0 then
    item_data.armor = self:getArmor()
  elseif self:getShootRange() > 1 then
    item_data.attack = self:getAttack()
    item_data.hitChance = self:getHitChance()
    item_data.shootRange = self:getShootRange()
  elseif self:getAttack() > 0 then
    item_data.attack = self:getAttack()
    item_data.defense = self:getDefense()
    item_data.extraDefense = self:getExtraDefense()
  elseif self:getDefense() > 0 then
    item_data.defense = self:getDefense()
    item_data.extraDefense = self:getExtraDefense()
  end

  item_data.weight = self:getWeight() * item_data.count

  local worthValue = self:getWorth()
  if worthValue and worthValue > 0 then
    item_data.worth = formatWorth(worthValue * item_data.count)
  end

  return item_data
end

function formatItemType(itemType)
  local weaponType = itemType:getWeaponType()

  if weaponType ~= WEAPON_SHIELD then
    local slotPosition = itemType:getSlotPosition() - SLOTP_LEFT - SLOTP_RIGHT

    if slotPosition == SLOTP_TWO_HAND and weaponType == WEAPON_SWORD then
      return "Two-Handed Sword"
    elseif slotPosition == SLOTP_TWO_HAND and weaponType == WEAPON_CLUB then
      return "Two-Handed Club"
    elseif slotPosition == SLOTP_TWO_HAND and weaponType == WEAPON_AXE then
      return "Two-Handed Axe"
    elseif weaponType == WEAPON_SWORD then
      return "Sword"
    elseif weaponType == WEAPON_CLUB then
      return "Club"
    elseif weaponType == WEAPON_AXE then
      return "Axe"
    elseif weaponType == WEAPON_DISTANCE then
      return "Distance"
    elseif weaponType == WEAPON_WAND then
      return "Wand"
    elseif slotPosition == SLOTP_HEAD then
      return "Helmet"
    elseif slotPosition == SLOTP_NECKLACE then
      return "Necklace"
    elseif slotPosition == SLOTP_ARMOR then
      return "Armor"
    elseif slotPosition == SLOTP_LEGS then
      return "Legs"
    elseif slotPosition == SLOTP_FEET then
      return "Boots"
    elseif slotPosition == SLOTP_RING or slotPosition == SLOTP_RING1 or slotPosition == SLOTP_RING2 then
      return "Ring"
    elseif slotPosition == SLOTP_AMMO and itemType:getAmmoType() > 0 then
      return "Ammunition"
    elseif itemType:isRune() then
      return "Rune"
    elseif itemType:isContainer() then
      return "Container"
    elseif itemType:isFluidContainer() then
      return "Potion"
    elseif itemType:isUseable() then
      return "Usable"
    end
  else
    return "Shield"
  end

  return "Common"
end

LoginEvent:type("login")
LoginEvent:register()
ExtendedEvent:type("extendedopcode")
ExtendedEvent:register()
