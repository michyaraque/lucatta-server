import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);

const workspaceRoot = path.resolve(import.meta.dirname, "..", "..");
const nbqRoot = path.resolve(workspaceRoot, "..", "LucattaQuestNBQ");
const commonRoot = path.join(nbqRoot, "packages", "common");
const serverRoot = path.join(nbqRoot, "packages", "server");
const commonDistTypesRoot = path.join(commonRoot, "dist", "types");
const ts = require(path.join(nbqRoot, "node_modules", "typescript"));
const commonConst = require(path.join(commonDistTypesRoot, "const.js"));
const commonMagicEffect = require(path.join(commonDistTypesRoot, "magicEffect.js"));

const moduleCache = new Map();

const equipmentSlot = {
  WEAPON: 0,
  ARMOR: 1,
  BELT: 2,
  RING1: 3,
  RING2: 4,
  AMULET: 5,
  CAPE: 6,
  SHIELD: 7,
  HELMET: 8,
  PET: 9,
  FEET: 10,
  BACKPACK: 11,
};

const rarity = {
  Common: 0,
  Uncommon: 1,
  Rare: 2,
  Epic: 3,
  Legendary: 4,
};

const combatType = {
  COMBAT_NONE: 0,
  COMBAT_PHYSICAL: 1,
  COMBAT_FIRE: 2,
  COMBAT_ICE: 3,
  COMBAT_LIGHTNING: 4,
  COMBAT_POISON: 5,
  COMBAT_LIFEDRAIN: 6,
  COMBAT_HEALING: 7,
  COMBAT_MAGIC: 8,
};

const monsterRace = {
  VENOM: "venom",
  BLOOD: "blood",
  UNDEAD: "undead",
  ICE: "ice",
};

const monsterElementMode = {
  FIXED: "fixed",
  RANDOM: "random",
  RANDOM_POOL: "random_pool",
};

function resolveCandidate(specifier, fromFile) {
  if (!specifier.startsWith(".")) {
    return null;
  }

  const base = path.resolve(path.dirname(fromFile), specifier);
  const candidates = [
    base,
    `${base}.ts`,
    `${base}.js`,
    path.join(base, "index.ts"),
    path.join(base, "index.js"),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  return null;
}

function createDependencyMap() {
  return {
    "@lucatta/common/game": () => loadItemsModule(),
    "@lucatta/common/utils/itemRarity": () => ({ Rarity: rarity }),
    "@lucatta/common/utils/slots": () => ({ EquipmentSlot: equipmentSlot }),
    "@lucatta/common/types/const": () => commonConst,
    "@lucatta/common/types/magicEffect": () => commonMagicEffect,
    "@lucatta/server/types/IMonster": () => ({
      MonsterRace: monsterRace,
      MonsterElementMode: monsterElementMode,
    }),
    "@lucatta/server/game/combat/combatDefines": () => ({ CombatType: combatType }),
  };
}

function evaluateTypeScriptModule(filePath) {
  const normalizedPath = path.normalize(filePath);
  if (moduleCache.has(normalizedPath)) {
    return moduleCache.get(normalizedPath);
  }

  const source = fs.readFileSync(normalizedPath, "utf8");
  const transpiled = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
      esModuleInterop: true,
    },
    fileName: normalizedPath,
  });

  const module = { exports: {} };
  const dependencyMap = createDependencyMap();

  const sandboxRequire = (specifier) => {
    if (dependencyMap[specifier]) {
      return dependencyMap[specifier]();
    }

    const relativePath = resolveCandidate(specifier, normalizedPath);
    if (relativePath) {
      return evaluateTypeScriptModule(relativePath);
    }

    return {};
  };

  const context = {
    module,
    exports: module.exports,
    require: sandboxRequire,
    __dirname: path.dirname(normalizedPath),
    __filename: normalizedPath,
    console,
    process,
    Buffer,
    Set,
    Map,
    WeakMap,
    WeakSet,
    Math,
    Date,
    JSON,
  };

  vm.runInNewContext(transpiled.outputText, context, { filename: normalizedPath });
  const exportsValue = module.exports.default ?? module.exports;
  moduleCache.set(normalizedPath, exportsValue);
  return exportsValue;
}

function listTypeScriptFiles(rootDirectory) {
  const files = [];
  const stack = [rootDirectory];

  while (stack.length > 0) {
    const current = stack.pop();
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      if (entry.name.startsWith(".")) {
        continue;
      }

      const absolutePath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(absolutePath);
        continue;
      }

      if (entry.isFile() && entry.name.endsWith(".ts") && entry.name !== "index.ts") {
        files.push(absolutePath);
      }
    }
  }

  files.sort((left, right) => left.localeCompare(right));
  return files;
}

let itemsModuleCache = null;

export function loadItemsModule() {
  if (!itemsModuleCache) {
    itemsModuleCache = evaluateTypeScriptModule(path.join(commonRoot, "game", "itemsData.ts"));
  }
  return itemsModuleCache;
}

export function loadNbqItems() {
  const { ItemsData } = loadItemsModule();
  return Object.values(ItemsData).sort((left, right) => left.itemId - right.itemId);
}

export function loadNbqMonsterSpells() {
  const rootDirectory = path.join(serverRoot, "data", "spells", "monster");
  const spells = new Map();

  for (const filePath of listTypeScriptFiles(rootDirectory)) {
    const spell = evaluateTypeScriptModule(filePath);
    spells.set(spell.id, {
      ...spell,
      __source: path.relative(serverRoot, filePath).replaceAll("\\", "/"),
    });
  }

  return spells;
}

export function loadNbqMonsters() {
  const rootDirectory = path.join(serverRoot, "data", "monster", "monsters");
  return listTypeScriptFiles(rootDirectory).map((filePath) => {
    const monster = evaluateTypeScriptModule(filePath);
    return {
      ...monster,
      __source: path.relative(serverRoot, filePath).replaceAll("\\", "/"),
      __relativeFile: path.relative(rootDirectory, filePath).replaceAll("\\", "/"),
    };
  });
}

export function getExportRoots() {
  return {
    workspaceRoot,
    nbqRoot,
    tibiaServerRoot: workspaceRoot,
  };
}
