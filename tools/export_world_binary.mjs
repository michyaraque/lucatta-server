import fs from "node:fs";
import path from "node:path";

import { getExportRoots, loadMonsters } from "./content-export/source.mjs";

const NODE_ESC = 0xFD;
const NODE_INIT = 0xFE;
const NODE_TERM = 0xFF;

const NODE_TYPE = {
  MAP_HEADER: 0x00,
  MAP_DATA: 0x02,
  TILE_AREA: 0x04,
  TILE: 0x05,
  ITEM: 0x06,
  TOWNS: 0x0C,
  TOWN: 0x0D,
  WAYPOINTS: 0x0F,
  WAYPOINT: 0x10,
};

const ATTR = {
  DESCRIPTION: 0x01,
  TILE_FLAGS: 0x03,
  ACTION_ID: 0x04,
  UNIQUE_ID: 0x05,
  TELE_DEST: 0x08,
  EXT_SPAWN_FILE: 0x0B,
  EXT_HOUSE_FILE: 0x0D,
  COUNT: 0x0F,
};

const DEFAULT_HEADER = {
  version: 2,
  itemsMajorVersion: 3,
  itemsMinorVersion: 63,
};

function ensureDirectory(directoryPath) {
  fs.mkdirSync(directoryPath, { recursive: true });
}

function writeUInt8(value) {
  const buffer = Buffer.alloc(1);
  buffer.writeUInt8(value, 0);
  return buffer;
}

function writeUInt16LE(value) {
  const buffer = Buffer.alloc(2);
  buffer.writeUInt16LE(value, 0);
  return buffer;
}

function writeUInt32LE(value) {
  const buffer = Buffer.alloc(4);
  buffer.writeUInt32LE(value, 0);
  return buffer;
}

function writeString(value) {
  const buffer = Buffer.from(String(value), "utf8");
  return Buffer.concat([writeUInt16LE(buffer.length), buffer]);
}

function escapeBuffer(buffer) {
  const parts = [];
  for (const byte of buffer) {
    if (byte === NODE_ESC || byte === NODE_INIT || byte === NODE_TERM) {
      parts.push(writeUInt8(NODE_ESC));
    }
    parts.push(writeUInt8(byte));
  }
  return Buffer.concat(parts);
}

function serializeNode(type, ownData, children = []) {
  const payload = Buffer.concat([
    writeUInt8(type),
    ownData,
  ]);

  return Buffer.concat([
    writeUInt8(NODE_INIT),
    escapeBuffer(payload),
    ...children,
    writeUInt8(NODE_TERM),
  ]);
}

function buildItemAttributes(item) {
  const attributes = [];

  if (item.destination) {
    attributes.push(Buffer.concat([
      writeUInt8(ATTR.TELE_DEST),
      writeUInt16LE(item.destination.x),
      writeUInt16LE(item.destination.y),
      writeUInt8(item.destination.z),
    ]));
  }

  if (typeof item.actionId === "number") {
    attributes.push(Buffer.concat([
      writeUInt8(ATTR.ACTION_ID),
      writeUInt16LE(item.actionId),
    ]));
  }

  if (typeof item.uniqueId === "number") {
    attributes.push(Buffer.concat([
      writeUInt8(ATTR.UNIQUE_ID),
      writeUInt16LE(item.uniqueId),
    ]));
  }

  if (typeof item.count === "number") {
    attributes.push(Buffer.concat([
      writeUInt8(ATTR.COUNT),
      writeUInt8(item.count),
    ]));
  }

  return Buffer.concat(attributes);
}

function buildItemNode(item) {
  const children = Array.isArray(item.children) ? item.children.map(buildItemNode) : [];
  const ownData = Buffer.concat([
    writeUInt16LE(item.id),
    buildItemAttributes(item),
  ]);
  return serializeNode(NODE_TYPE.ITEM, ownData, children);
}

function buildTileAttributes(tile) {
  if (typeof tile.flags !== "number" || tile.flags === 0) {
    return Buffer.alloc(0);
  }

  return Buffer.concat([
    writeUInt8(ATTR.TILE_FLAGS),
    writeUInt32LE(tile.flags),
  ]);
}

function buildTileNode(tile) {
  const itemNodes = (tile.items || []).map(buildItemNode);
  const ownData = Buffer.concat([
    writeUInt8(tile.x),
    writeUInt8(tile.y),
    buildTileAttributes(tile),
  ]);

  return serializeNode(NODE_TYPE.TILE, ownData, itemNodes);
}

function buildTileAreaNode(tileArea) {
  const tileNodes = (tileArea.tiles || []).map(buildTileNode);
  const ownData = Buffer.concat([
    writeUInt16LE(tileArea.x),
    writeUInt16LE(tileArea.y),
    writeUInt8(tileArea.z),
  ]);

  return serializeNode(NODE_TYPE.TILE_AREA, ownData, tileNodes);
}

function buildTownNode(town) {
  const ownData = Buffer.concat([
    writeUInt32LE(town.id),
    writeString(town.name),
    writeUInt16LE(town.temple.x),
    writeUInt16LE(town.temple.y),
    writeUInt8(town.temple.z),
  ]);

  return serializeNode(NODE_TYPE.TOWN, ownData);
}

function buildTownsNode(worldDocument) {
  const towns = Array.isArray(worldDocument.map.towns) ? worldDocument.map.towns : [];
  if (towns.length === 0) {
    return null;
  }

  return serializeNode(NODE_TYPE.TOWNS, Buffer.alloc(0), towns.map(buildTownNode));
}

function buildWaypointNode(waypoint) {
  const ownData = Buffer.concat([
    writeString(waypoint.name),
    writeUInt16LE(waypoint.position.x),
    writeUInt16LE(waypoint.position.y),
    writeUInt8(waypoint.position.z),
  ]);

  return serializeNode(NODE_TYPE.WAYPOINT, ownData);
}

function buildWaypointsNode(worldDocument) {
  const waypoints = Array.isArray(worldDocument.map.waypoints) ? worldDocument.map.waypoints : [];
  if (waypoints.length === 0) {
    return null;
  }

  return serializeNode(NODE_TYPE.WAYPOINTS, Buffer.alloc(0), waypoints.map(buildWaypointNode));
}

function buildMapDataAttributes({ description, spawnFileName, houseFileName }) {
  return Buffer.concat([
    writeUInt8(ATTR.DESCRIPTION),
    writeString(description),
    writeUInt8(ATTR.EXT_SPAWN_FILE),
    writeString(spawnFileName),
    writeUInt8(ATTR.EXT_HOUSE_FILE),
    writeString(houseFileName),
  ]);
}

function buildMapDataNode(worldDocument, fileNames) {
  const ownData = buildMapDataAttributes({
    description: "Generated from world.json",
    spawnFileName: fileNames.spawn,
    houseFileName: fileNames.house,
  });

  const children = [
    ...(worldDocument.map.tileAreas || []).map(buildTileAreaNode),
  ];

  const townsNode = buildTownsNode(worldDocument);
  if (townsNode) {
    children.push(townsNode);
  }

  const waypointsNode = buildWaypointsNode(worldDocument);
  if (waypointsNode) {
    children.push(waypointsNode);
  }

  return serializeNode(NODE_TYPE.MAP_DATA, ownData, children);
}

function buildRootNode(worldDocument, headerTemplate, fileNames) {
  const ownData = Buffer.concat([
    writeUInt32LE(headerTemplate.version),
    writeUInt16LE(worldDocument.map.width),
    writeUInt16LE(worldDocument.map.height),
    writeUInt32LE(headerTemplate.itemsMajorVersion),
    writeUInt32LE(headerTemplate.itemsMinorVersion),
  ]);

  const child = buildMapDataNode(worldDocument, fileNames);
  return serializeNode(NODE_TYPE.MAP_HEADER, ownData, [child]);
}

function readHeaderTemplate(mapFilePath) {
  if (!fs.existsSync(mapFilePath)) {
    return DEFAULT_HEADER;
  }

  const buffer = fs.readFileSync(mapFilePath);
  if (buffer.length < 22) {
    return DEFAULT_HEADER;
  }

  return {
    version: buffer.readUInt32LE(6),
    itemsMajorVersion: buffer.readUInt32LE(14),
    itemsMinorVersion: buffer.readUInt32LE(18),
  };
}

function serializeWorldToBinary(worldDocument, headerTemplate, fileNames) {
  const identifier = Buffer.alloc(4, 0x00);
  const rootNode = buildRootNode(worldDocument, headerTemplate, fileNames);
  return Buffer.concat([identifier, rootNode]);
}

function xmlEscape(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("\"", "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function normalizeLookupKey(value) {
  return String(value)
    .trim()
    .toLowerCase()
    .replaceAll(/[^a-z0-9]+/g, "");
}

function createMonsterNameMap() {
  const monsters = loadMonsters();
  const map = new Map();

  for (const monster of monsters) {
    map.set(normalizeLookupKey(monster.kind), monster.name);
  }

  return map;
}

function createNpcNameMap(npcDirectory) {
  const map = new Map();
  if (!fs.existsSync(npcDirectory)) {
    return map;
  }

  for (const entry of fs.readdirSync(npcDirectory, { withFileTypes: true })) {
    if (!entry.isFile() || !entry.name.endsWith(".xml")) {
      continue;
    }

    const displayName = entry.name.replace(/\.xml$/i, "");
    map.set(normalizeLookupKey(displayName), displayName);
  }

  return map;
}

function resolveCreatureKind(kind, monsterNames, npcNames) {
  const normalizedKind = normalizeLookupKey(kind);
  if (monsterNames.has(normalizedKind)) {
    return { type: "monster", name: monsterNames.get(normalizedKind) };
  }

  if (npcNames.has(normalizedKind)) {
    return { type: "npc", name: npcNames.get(normalizedKind) };
  }

  return null;
}

function buildSpawnXml(spawnDocument, monsterNames, npcNames) {
  const lines = [
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
    "<spawns>",
  ];

  const skippedKinds = new Map();
  let exportedSpawns = 0;

  for (const spawn of spawnDocument.spawns?.creatureSpawns || []) {
    const resolved = resolveCreatureKind(spawn.kind, monsterNames, npcNames);
    if (!resolved) {
      skippedKinds.set(spawn.kind, (skippedKinds.get(spawn.kind) || 0) + 1);
      continue;
    }

    lines.push(`\t<spawn centerx="${spawn.x}" centery="${spawn.y}" centerz="${spawn.z}" radius="0">`);
    if (resolved.type === "npc") {
      lines.push(`\t\t<npc name="${xmlEscape(resolved.name)}" x="0" y="0" />`);
    } else {
      lines.push(`\t\t<monster name="${xmlEscape(resolved.name)}" x="0" y="0" spawntime="60"></monster>`);
    }
    lines.push("\t</spawn>");
    exportedSpawns += 1;
  }

  lines.push("</spawns>", "");

  return {
    xml: lines.join("\n"),
    exportedSpawns,
    skippedKinds: Object.fromEntries([...skippedKinds.entries()].sort((left, right) => left[0].localeCompare(right[0]))),
    skippedSpawnAreas: spawnDocument.spawns?.spawnAreas?.length || 0,
  };
}

function parseMapName(configPath) {
  const config = fs.readFileSync(configPath, "utf8");
  const match = config.match(/mapName\s*=\s*"([^"]+)"/);
  return match?.[1] || "forgotten";
}

function writeFile(filePath, content) {
  ensureDirectory(path.dirname(filePath));
  fs.writeFileSync(filePath, content);
}

const { workspaceRoot, gameRoot, tibiaServerRoot } = getExportRoots();
const mapName = process.argv[2] || parseMapName(path.join(tibiaServerRoot, "config.lua"));

const worldJsonPath = path.join(gameRoot, "packages", "server", "data", "world", "world.json");
const spawnJsonPath = path.join(gameRoot, "packages", "server", "data", "world", "spawns.json");
const worldOutputPath = path.join(tibiaServerRoot, "data", "world", `${mapName}.lbm`);
const spawnOutputPath = path.join(tibiaServerRoot, "data", "world", `${mapName}-spawn.xml`);
const houseOutputPath = path.join(tibiaServerRoot, "data", "world", `${mapName}-house.xml`);

const worldDocument = JSON.parse(fs.readFileSync(worldJsonPath, "utf8"));
const spawnDocument = JSON.parse(fs.readFileSync(spawnJsonPath, "utf8"));
const headerTemplate = readHeaderTemplate(worldOutputPath);
const fileNames = {
  spawn: `${mapName}-spawn.xml`,
  house: `${mapName}-house.xml`,
};

const mapBuffer = serializeWorldToBinary(worldDocument, headerTemplate, fileNames);
const monsterNames = createMonsterNameMap();
const npcNames = createNpcNameMap(path.join(tibiaServerRoot, "data", "npc"));
const spawnExport = buildSpawnXml(spawnDocument, monsterNames, npcNames);

writeFile(worldOutputPath, mapBuffer);
writeFile(spawnOutputPath, spawnExport.xml);
writeFile(houseOutputPath, "<?xml version=\"1.0\"?>\n<houses />\n");

console.log(JSON.stringify({
  workspaceRoot,
  mapName,
  worldJsonPath,
  spawnJsonPath,
  outputs: {
    map: worldOutputPath,
    spawns: spawnOutputPath,
    houses: houseOutputPath,
  },
  tileAreas: worldDocument.map.tileAreas.length,
  creatureSpawnsExported: spawnExport.exportedSpawns,
  spawnAreasSkipped: spawnExport.skippedSpawnAreas,
  unresolvedKinds: spawnExport.skippedKinds,
}, null, 2));
