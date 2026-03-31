const slotLabels = {
  0: "weapon",
  1: "armor",
  2: "belt",
  3: "ring1",
  4: "ring2",
  5: "amulet",
  6: "cape",
  7: "shield",
  8: "helmet",
  9: "pet",
  10: "feet",
  11: "backpack",
};

const itemXmlSlotTypes = {
  0: "hand",
  1: "body",
  5: "necklace",
  7: "left-hand",
  8: "head",
};

const resistanceCombatTypes = {
  physical: "COMBAT_PHYSICALDAMAGE",
  poison: "COMBAT_EARTHDAMAGE",
  flame: "COMBAT_FIREDAMAGE",
  lightning: "COMBAT_ENERGYDAMAGE",
  cold: "COMBAT_ICEDAMAGE",
  magic: "COMBAT_UNDEFINEDDAMAGE",
};

const spellCombatTypes = {
  1: "COMBAT_PHYSICALDAMAGE",
  2: "COMBAT_FIREDAMAGE",
  3: "COMBAT_ICEDAMAGE",
  4: "COMBAT_ENERGYDAMAGE",
  5: "COMBAT_EARTHDAMAGE",
  6: "COMBAT_LIFEDRAIN",
  7: "COMBAT_HEALING",
  8: "COMBAT_UNDEFINEDDAMAGE",
};

const supportedMonsterRaces = new Set(["venom", "blood", "undead"]);
const supportedConditions = {
  poison: "CONDITION_POISON",
  freezing: "CONDITION_FREEZING",
};

function xmlEscape(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("\"", "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function sanitizeDescription(value) {
  return String(value).replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
}

function luaEscape(value) {
  return String(value)
    .replaceAll("\\", "\\\\")
    .replaceAll("\"", "\\\"")
    .replaceAll("\r", "\\r")
    .replaceAll("\n", "\\n");
}

function indent(level) {
  return "  ".repeat(level);
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function luaRaw(value) {
  return { __luaRaw: value };
}

function formatLuaKey(key) {
  return /^[A-Za-z_][A-Za-z0-9_]*$/.test(key) ? key : `["${luaEscape(key)}"]`;
}

function toLua(value, level = 0) {
  if (value === null || value === undefined) {
    return "nil";
  }

  if (typeof value === "string") {
    return `"${luaEscape(value)}"`;
  }

  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  if (isPlainObject(value) && typeof value.__luaRaw === "string") {
    return value.__luaRaw;
  }

  if (Array.isArray(value)) {
    if (value.length === 0) {
      return "{}";
    }

    const lines = value.map((entry) => `${indent(level + 1)}${toLua(entry, level + 1)}`);
    return `{\n${lines.join(",\n")}\n${indent(level)}}`;
  }

  if (isPlainObject(value)) {
    const entries = Object.entries(value).filter(([, entryValue]) => entryValue !== undefined);
    if (entries.length === 0) {
      return "{}";
    }

    const lines = entries.map(([key, entryValue]) => {
      return `${indent(level + 1)}${formatLuaKey(key)} = ${toLua(entryValue, level + 1)}`;
    });

    return `{\n${lines.join(",\n")}\n${indent(level)}}`;
  }

  return "nil";
}

function buildItemXmlAttributes(item) {
  const attributes = [];
  const description = item.attributes?.description ? sanitizeDescription(item.attributes.description) : null;
  if (description) {
    attributes.push({ key: "description", value: description });
  }

  const slotType = itemXmlSlotTypes[item.slotType];
  if (slotType) {
    attributes.push({ key: "slotType", value: slotType });
  }

  if (item.slotType === 0 && typeof item.attributes?.attack === "number") {
    attributes.push({ key: "attack", value: item.attributes.attack });
  }

  if (item.slotType === 7 && typeof item.attributes?.defense === "number") {
    attributes.push({ key: "defense", value: item.attributes.defense });
  }

  if ((item.slotType === 1 || item.slotType === 8) && typeof item.attributes?.defense === "number") {
    attributes.push({ key: "armor", value: item.attributes.defense });
  }

  return attributes;
}

export function emitItemXmlNode(item) {
  const attributes = buildItemXmlAttributes(item);
  if (attributes.length === 0) {
    return `  <item id="${item.itemId}" name="${xmlEscape(item.name)}" />`;
  }

  const lines = [`  <item id="${item.itemId}" name="${xmlEscape(item.name)}">`];
  for (const attribute of attributes) {
    lines.push(`    <attribute key="${xmlEscape(attribute.key)}" value="${xmlEscape(attribute.value)}" />`);
  }
  lines.push("  </item>");
  return lines.join("\n");
}

export function emitItemsOverlayXml(items) {
  const lines = [
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
    "<items>",
  ];

  for (const item of items) {
    lines.push(emitItemXmlNode(item));
  }

  lines.push("</items>", "");
  return lines.join("\n");
}

export function emitItemRegistryLua(items) {
  const byId = {};
  const byKind = {};

  for (const item of items) {
    byKind[item.kind] = item.itemId;
    byId[item.itemId] = {
      kind: item.kind,
      name: item.name,
      slotType: item.slotType !== undefined ? slotLabels[item.slotType] ?? item.slotType : undefined,
      requiredLevel: item.requiredLevel,
      price: item.price,
      flags: item.flags,
      stackable: item.stackable,
      maxStack: item.maxStack,
      rarity: item.rarity,
      attributes: item.attributes,
      customAttributes: item.customAttributes,
      source: "packages/common/game/itemsData.ts",
    };
  }

  return [
    "-- Generated by tools/export_nbq_content.mjs. Do not edit by hand.",
    "NBQItemRegistry = {",
    `  byId = ${toLua(byId, 1)},`,
    `  byKind = ${toLua(byKind, 1)},`,
    "}",
    "",
  ].join("\n");
}

function buildMonsterElements(monster) {
  if (!monster.damageModifier) {
    return [];
  }

  return Object.entries(monster.damageModifier)
    .map(([key, percent]) => {
      const combatType = resistanceCombatTypes[key];
      if (!combatType || typeof percent !== "number") {
        return null;
      }

      return { type: luaRaw(combatType), percent };
    })
    .filter(Boolean);
}

function buildLuaSpellAbility(spellEntry, spellDefinition) {
  if (!spellDefinition) {
    return null;
  }

  const type = spellCombatTypes[spellDefinition.combat?.type];
  if (!type) {
    return null;
  }

  const isHealing = spellDefinition.combat?.type === 7;
  const ability = {
    name: "combat",
    type: luaRaw(type),
    chance: spellEntry.chance,
    interval: spellEntry.interval,
    target: spellDefinition.targetMode === "target",
    range: spellEntry.range ?? spellDefinition.range,
  };

  if (typeof spellEntry.min === "number" && typeof spellEntry.max === "number") {
    if (isHealing) {
      ability.minDamage = Math.round(spellEntry.min);
      ability.maxDamage = Math.round(spellEntry.max);
    } else {
      ability.minDamage = -Math.round(spellEntry.max);
      ability.maxDamage = -Math.round(spellEntry.min);
    }
  }

  const effect = spellDefinition.combat?.effectId ?? spellDefinition.combat?.impactEffectId;
  if (typeof effect === "number") {
    ability.effect = effect;
  }

  if (Array.isArray(spellDefinition.area) && spellDefinition.area.length === 3 && spellDefinition.area[0]?.length === 3) {
    ability.radius = 1;
  }

  const condition = spellDefinition.combat?.condition;
  if (condition) {
    const conditionType = supportedConditions[condition.type];
    if (conditionType) {
      ability.condition = {
        type: luaRaw(conditionType),
        duration: condition.duration,
      };

      if (typeof condition.damagePerTick === "number") {
        ability.condition.minDamage = condition.damagePerTick;
        ability.condition.maxDamage = condition.damagePerTick;
        ability.condition.interval = 1000;
      }
    }
  }

  return {
    section: isHealing ? "defenses" : "attacks",
    ability,
  };
}

export function emitMonsterRegistryLua(monsters, spells) {
  const byKind = {};

  for (const monster of monsters) {
    byKind[monster.kind] = {
      name: monster.name,
      race: monster.race,
      level: monster.level,
      damageModifier: monster.damageModifier,
      enchantments: monster.enchantments,
      spawnBehavior: monster.spawnBehavior,
      hasScript: Boolean(monster.script),
      source: monster.__source,
      spells: (monster.attacks?.spells ?? []).map((spellEntry) => {
        const spell = spells.get(spellEntry.spellId);
        return {
          id: spellEntry.spellId,
          source: spell?.__source,
          targetMode: spell?.targetMode,
          combatType: spell?.combat?.type,
          area: Array.isArray(spell?.area) ? spell.area : undefined,
          condition: spell?.combat?.condition,
          unsupportedConditionSpeedChange: spell?.combat?.condition?.speedChange,
        };
      }),
    };
  }

  return [
    "-- Generated by tools/export_nbq_content.mjs. Do not edit by hand.",
    "NBQMonsterRegistry = {",
    `  byKind = ${toLua(byKind, 1)},`,
    "}",
    "",
  ].join("\n");
}

export function emitMonsterLua(monster, spells, itemKindToId) {
  const comments = [
    "-- Generated by tools/export_nbq_content.mjs. Do not edit by hand.",
    `-- Source: ${monster.__source}`,
  ];

  if (monster.script) {
    comments.push("-- NBQ script callbacks are preserved in NBQMonsterRegistry.byKind and still need a dedicated Lua port.");
  }

  const lines = [...comments, `local mType = Game.createMonsterType("${luaEscape(monster.name)}")`, "local monster = {}", ""];

  lines.push(`monster.name = "${luaEscape(monster.name)}"`);
  lines.push(`monster.experience = ${monster.exp}`);
  if (typeof monster.lookTypeId === "number") {
    lines.push("monster.outfit = {");
    lines.push(`  lookType = ${monster.lookTypeId},`);
    lines.push("}");
  }
  lines.push(`monster.health = ${monster.health}`);
  lines.push(`monster.maxHealth = ${monster.maxHealth}`);
  if (supportedMonsterRaces.has(monster.race)) {
    lines.push(`monster.race = "${monster.race}"`);
  }
  lines.push(`monster.speed = ${monster.speed}`);
  lines.push(`monster.runHealth = ${monster.flags.runOnHealth}`);
  if (monster.targetChange) {
    lines.push("monster.changeTarget = {");
    lines.push(`  interval = ${monster.targetChange.interval},`);
    lines.push(`  chance = ${monster.targetChange.chance},`);
    lines.push("}");
  }

  lines.push("monster.flags = {");
  lines.push(`  attackable = ${monster.flags.attackable ? "true" : "false"},`);
  lines.push(`  hostile = ${monster.flags.hostile ? "true" : "false"},`);
  lines.push(`  targetDistance = ${monster.flags.targetDistance},`);
  if (monster.flags.isBoss) {
    lines.push("  boss = true,");
  }
  lines.push("}");

  lines.push("monster.loot = {");
  for (const loot of monster.loot) {
    const itemId = itemKindToId.get(loot.item);
    if (!itemId) {
      continue;
    }
    lines.push(`  {id = ${itemId}, chance = ${loot.chance}, maxCount = ${loot.countmax}},`);
  }
  lines.push("}");

  const attackAbilities = [];
  if (monster.attacks?.melee) {
    attackAbilities.push({
      name: "melee",
      interval: monster.attacks.melee.interval,
      minDamage: -Math.round(monster.attacks.melee.max),
      maxDamage: -Math.round(monster.attacks.melee.min),
    });
  }
  if (monster.attacks?.physical) {
    attackAbilities.push({
      name: "combat",
      type: luaRaw("COMBAT_PHYSICALDAMAGE"),
      interval: monster.attacks.physical.interval,
      chance: 100,
      target: true,
      range: 1,
      minDamage: -Math.round(monster.attacks.physical.max),
      maxDamage: -Math.round(monster.attacks.physical.min),
    });
  }

  const defenseAbilities = [];
  for (const spellEntry of monster.attacks?.spells ?? []) {
    const builtSpell = buildLuaSpellAbility(spellEntry, spells.get(spellEntry.spellId));
    if (!builtSpell) {
      continue;
    }
    if (builtSpell.section === "defenses") {
      defenseAbilities.push(builtSpell.ability);
    } else {
      attackAbilities.push(builtSpell.ability);
    }
  }

  lines.push("monster.attacks = {");
  for (const ability of attackAbilities) {
    lines.push(`  ${toLua(ability, 1)},`);
  }
  lines.push("}");

  lines.push("monster.defenses = {");
  lines.push(`  defense = ${monster.defenses.defense},`);
  lines.push(`  armor = ${monster.defenses.armor},`);
  for (const ability of defenseAbilities) {
    lines.push(`  ${toLua(ability, 1)},`);
  }
  lines.push("}");

  const elements = buildMonsterElements(monster);
  if (elements.length > 0) {
    lines.push("monster.elements = {");
    for (const element of elements) {
      lines.push(`  ${toLua(element, 1)},`);
    }
    lines.push("}");
  }

  lines.push("", "mType:register(monster)", "");
  return lines.join("\n");
}
