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

const spellConditionTypes = {
  haste: "CONDITION_HASTE",
  poison: "CONDITION_POISON",
  freezing: "CONDITION_FREEZING",
};

const supportedMonsterRaces = new Set(["venom", "blood", "undead"]);

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

function sanitizeIdentifier(value) {
  return String(value)
    .replace(/^monster[-_]?/i, "")
    .replace(/[^A-Za-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .toLowerCase();
}

function generatedSpellFileName(spell) {
  return `${sanitizeIdentifier(spell.id || spell.name)}.lua`;
}

function generatedMonsterFileName(monster) {
  return monster.__relativeFile.replaceAll("/", "__").replace(/\.ts$/i, ".lua");
}

function combatTypeFromSpell(spell) {
  const combatType = spellCombatTypes[spell.combat?.type];
  if (!combatType) {
    throw new Error(`Unsupported combat type for ${spell.id}`);
  }
  return combatType;
}

function effectFromSpell(spell) {
  return spell.combat?.effectId ?? spell.combat?.impactEffectId;
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

  const effect = effectFromSpell(spellDefinition);
  if (typeof effect === "number") {
    ability.effect = effect;
  }

  if (Array.isArray(spellDefinition.area) && spellDefinition.area.length === 3 && spellDefinition.area[0]?.length === 3) {
    ability.radius = 1;
  }

  const condition = spellDefinition.combat?.condition;
  if (condition) {
    const conditionType = spellConditionTypes[condition.type];
    if (conditionType) {
      ability.condition = {
        type: luaRaw(conditionType),
      };

      if (typeof condition.duration === "number") {
        ability.duration = condition.duration;
        ability.condition.duration = condition.duration;
      }

      if (typeof condition.damagePerTick === "number") {
        ability.condition.minDamage = Math.abs(Math.round(condition.damagePerTick));
        ability.condition.maxDamage = Math.abs(Math.round(condition.damagePerTick));
        ability.condition.interval = typeof condition.tickInterval === "number" && condition.tickInterval > 0
          ? condition.tickInterval
          : 1000;
      }

      if (typeof condition.speedChange === "number") {
        ability.speed = Math.round(condition.speedChange);
      }
    }
  }

  return {
    section: isHealing ? "defenses" : "attacks",
    ability,
  };
}

function emitAreaLiteral(area) {
  return toLua(area, 0);
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

export function emitItemsXml(items) {
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

export function emitMonsterSpellLua(spell) {
  const lines = [
    "-- Generated by tools/export_content.mjs. Do not edit by hand.",
    `-- Source: ${spell.__source}`,
  ];

  if (Array.isArray(spell.area) && spell.area.length > 0) {
    lines.push(`local area = ${emitAreaLiteral(spell.area)}`);
    lines.push("");
  }

  lines.push("local combat = Combat()");
  lines.push(`combat:setParameter(COMBAT_PARAM_TYPE, ${combatTypeFromSpell(spell)})`);

  const effect = effectFromSpell(spell);
  if (typeof effect === "number") {
    lines.push(`combat:setParameter(COMBAT_PARAM_EFFECT, ${effect})`);
  }

  if (spell.combat?.type === 7) {
    lines.push("combat:setParameter(COMBAT_PARAM_AGGRESSIVE, false)");
  }

  if (Array.isArray(spell.area) && spell.area.length > 0) {
    lines.push("combat:setArea(createCombatArea(area))");
  }

  const condition = spell.combat?.condition;
  if (condition) {
    const conditionType = spellConditionTypes[condition.type];
    if (conditionType) {
      lines.push("");
      lines.push(`local condition = Condition(${conditionType})`);
      if (typeof condition.duration === "number") {
        lines.push(`condition:setParameter(CONDITION_PARAM_TICKS, ${condition.duration})`);
      }

      if (typeof condition.damagePerTick === "number") {
        const tickInterval = typeof condition.tickInterval === "number" && condition.tickInterval > 0
          ? condition.tickInterval
          : 1000;
        const ticks = typeof condition.duration === "number"
          ? Math.max(1, Math.floor(condition.duration / tickInterval))
          : 1;
        lines.push("condition:setParameter(CONDITION_PARAM_DELAYED, 1)");
        lines.push(`condition:addDamage(${ticks}, ${tickInterval}, ${-Math.abs(Math.round(condition.damagePerTick))})`);
      }

      lines.push("combat:addCondition(condition)");

      if (typeof condition.speedChange === "number") {
        const speedConditionType = condition.speedChange >= 0 ? "CONDITION_HASTE" : "CONDITION_PARALYZE";
        lines.push("");
        lines.push(`local speed = Condition(${speedConditionType})`);
        if (typeof condition.duration === "number") {
          lines.push(`speed:setParameter(CONDITION_PARAM_TICKS, ${condition.duration})`);
        }
        lines.push(`speed:setParameter(CONDITION_PARAM_SPEED, ${Math.round(condition.speedChange)})`);
        lines.push("combat:addCondition(speed)");
      }
    }
  }

  lines.push("");
  lines.push("local spell = Spell(SPELL_INSTANT)");
  lines.push("");
  lines.push("function spell.onCastSpell(creature, variant)");
  lines.push("  return combat:execute(creature, variant)");
  lines.push("end");
  lines.push("");
  lines.push(`spell:name("${luaEscape(spell.name)}")`);
  lines.push(`spell:words("###generated_${sanitizeIdentifier(spell.id)}")`);

  if (spell.targetMode === "target") {
    lines.push("spell:needTarget(true)");
    if (typeof spell.range === "number" && spell.range > 0) {
      lines.push(`spell:range(${spell.range})`);
    }
  } else {
    lines.push("spell:isSelfTarget(true)");
  }

  if (!spell.aggressive) {
    lines.push("spell:isAggressive(false)");
  }

  lines.push("spell:blockWalls(true)");
  lines.push("spell:needLearn(true)");
  lines.push("spell:register()");
  lines.push("");

  return lines.join("\n");
}

export function emitMonsterLua(monster, spells, itemKindToId) {
  const comments = [
    "-- Generated by tools/export_content.mjs. Do not edit by hand.",
    `-- Source: ${monster.__source}`,
  ];

  if (monster.script) {
    comments.push("-- Source monster callbacks still need a dedicated Lua port.");
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

export function getGeneratedMonsterFileName(monster) {
  return generatedMonsterFileName(monster);
}

export function getGeneratedSpellFileName(spell) {
  return generatedSpellFileName(spell);
}
