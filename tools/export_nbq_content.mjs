import fs from "node:fs";
import path from "node:path";

import { emitItemRegistryLua, emitItemsOverlayXml, emitMonsterLua, emitMonsterRegistryLua } from "./nbq-export/emitters.mjs";
import { getExportRoots, loadNbqItems, loadNbqMonsters, loadNbqMonsterSpells } from "./nbq-export/source.mjs";

const { tibiaServerRoot } = getExportRoots();
const items = loadNbqItems();
const monsters = loadNbqMonsters();
const spells = loadNbqMonsterSpells();

const outputFiles = {
  itemsXml: path.join(tibiaServerRoot, "data", "items", "items.xml"),
  itemRegistry: path.join(tibiaServerRoot, "data", "scripts", "lib", "nbq", "item_registry.lua"),
  monsterRegistry: path.join(tibiaServerRoot, "data", "scripts", "lib", "nbq", "monster_registry.lua"),
  monsterDirectory: path.join(tibiaServerRoot, "data", "scripts", "monsters", "nbq"),
};

function ensureDirectory(directoryPath) {
  fs.mkdirSync(directoryPath, { recursive: true });
}

function writeFile(filePath, content) {
  ensureDirectory(path.dirname(filePath));
  fs.writeFileSync(filePath, content, "utf8");
}

function cleanGeneratedMonsterFiles(directoryPath) {
  ensureDirectory(directoryPath);
  for (const entry of fs.readdirSync(directoryPath, { withFileTypes: true })) {
    if (!entry.isFile() || !entry.name.endsWith(".lua")) {
      continue;
    }
    fs.unlinkSync(path.join(directoryPath, entry.name));
  }
}

function fileNameFromMonster(monster) {
  return monster.__relativeFile.replaceAll("/", "__").replace(/\.ts$/i, ".lua");
}

const itemKindToId = new Map(items.map((item) => [item.kind, item.itemId]));

writeFile(outputFiles.itemsXml, emitItemsOverlayXml(items));
writeFile(outputFiles.itemRegistry, emitItemRegistryLua(items));
writeFile(outputFiles.monsterRegistry, emitMonsterRegistryLua(monsters, spells));

cleanGeneratedMonsterFiles(outputFiles.monsterDirectory);
for (const monster of monsters) {
  const fileName = fileNameFromMonster(monster);
  const filePath = path.join(outputFiles.monsterDirectory, fileName);
  writeFile(filePath, emitMonsterLua(monster, spells, itemKindToId));
}

console.log(JSON.stringify({
  items: items.length,
  monsters: monsters.length,
  spells: spells.size,
  outputs: {
    itemsXml: outputFiles.itemsXml,
    itemRegistry: outputFiles.itemRegistry,
    monsterRegistry: outputFiles.monsterRegistry,
    monsterDirectory: outputFiles.monsterDirectory,
  },
}, null, 2));
