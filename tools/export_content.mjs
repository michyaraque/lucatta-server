import fs from "node:fs";
import path from "node:path";

import { emitItemsXml, emitMonsterLua, emitMonsterSpellLua, getGeneratedMonsterFileName, getGeneratedSpellFileName } from "./content-export/emitters.mjs";
import { getExportRoots, loadItems, loadMonsters, loadMonsterSpells } from "./content-export/source.mjs";

const { tibiaServerRoot } = getExportRoots();
const items = loadItems();
const monsters = loadMonsters();
const spells = loadMonsterSpells();

const outputFiles = {
  itemsXml: path.join(tibiaServerRoot, "data", "items", "items.xml"),
  monsterDirectory: path.join(tibiaServerRoot, "data", "scripts", "monsters", "generated"),
  spellDirectory: path.join(tibiaServerRoot, "data", "scripts", "spells", "monster", "generated"),
};

function ensureDirectory(directoryPath) {
  fs.mkdirSync(directoryPath, { recursive: true });
}

function writeFile(filePath, content) {
  ensureDirectory(path.dirname(filePath));
  fs.writeFileSync(filePath, content, "utf8");
}

function cleanGeneratedLuaFiles(directoryPath) {
  ensureDirectory(directoryPath);
  for (const entry of fs.readdirSync(directoryPath, { withFileTypes: true })) {
    if (!entry.isFile() || !entry.name.endsWith(".lua")) {
      continue;
    }
    fs.unlinkSync(path.join(directoryPath, entry.name));
  }
}

const itemKindToId = new Map(items.map((item) => [item.kind, item.itemId]));

writeFile(outputFiles.itemsXml, emitItemsXml(items));

cleanGeneratedLuaFiles(outputFiles.spellDirectory);
for (const spell of spells.values()) {
  const fileName = getGeneratedSpellFileName(spell);
  const filePath = path.join(outputFiles.spellDirectory, fileName);
  writeFile(filePath, emitMonsterSpellLua(spell));
}

cleanGeneratedLuaFiles(outputFiles.monsterDirectory);
for (const monster of monsters) {
  const fileName = getGeneratedMonsterFileName(monster);
  const filePath = path.join(outputFiles.monsterDirectory, fileName);
  writeFile(filePath, emitMonsterLua(monster, spells, itemKindToId));
}

console.log(JSON.stringify({
  items: items.length,
  monsters: monsters.length,
  spells: spells.size,
  outputs: outputFiles,
}, null, 2));
