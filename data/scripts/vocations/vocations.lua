-- ============================================================
-- VOCACIONES DEL SERVIDOR  —  fuente de verdad única
-- ============================================================
-- Para renombrar una vocación en el futuro:
--   1. Cambia el campo `name` en su bloque Game.createVocationType()
--   2. Actualiza VOC_GROUPS / VOC_DESC en data/lib/core/vocation.lua
--   3. Reinicia el servidor.  Nada más.
--
-- Para agregar una vocación nueva:
--   1. Define su constante aquí (VOCATION_XXX = N)
--   2. Agrega su bloque Game.createVocationType()
--   3. Si es promovida, ajusta el `fromvoc` de la base también
--
-- Skills array (indexado desde 1): fist, club, sword, axe, distance, shield, fishing
-- gaincap        → valor visible al cliente (el engine lo multiplica ×100 internamente)
-- noPongKickTime → tiempo en segundos
-- fromvoc        → ID de la vocación base; mismo ID que el propio = sin promoción
-- ============================================================

-- ── Constantes numéricas de vocación ──────────────────────────
-- Úsalas en cualquier script: VOCATION_WARRIOR, VOCATION_MAGE, etc.

VOCATION_NONE          = 0
VOCATION_MAGE          = 1
VOCATION_SHAMAN        = 2
VOCATION_ARCHER        = 3
VOCATION_WARRIOR       = 4
VOCATION_MASTER_MAGE   = 5
VOCATION_ELDER_SHAMAN  = 6
VOCATION_ROYAL_ARCHER  = 7
VOCATION_ELITE_WARRIOR = 8

-- ── Definición de vocaciones ───────────────────────────────────

-- None (reservada por el engine, nunca se asigna a un jugador)
Game.createVocationType({
    id             = VOCATION_NONE,
    clientid       = 0,
    name           = "None",
    description    = "none",
    magicShield    = false,
    allowPvp       = false,
    fromvoc        = VOCATION_NONE,
    gaincap        = 10,
    gainhp         = 5,
    gainmana       = 5,
    gainhpticks    = 6,
    gainhpamount   = 1,
    gainmanaticks  = 6,
    gainmanaamount = 1,
    manamultiplier = 4.0,
    attackspeed    = 2000,
    basespeed      = 220,
    soulmax        = 100,
    gainsoulticks  = 120,
    formula        = { meleeDamage = 1.0, distDamage = 1.0, defense = 1.0, armor = 1.0 },
    skills         = { 1.5, 2.0, 2.0, 2.0, 2.0, 1.5, 1.1 },
})

-- Mage
Game.createVocationType({
    id             = VOCATION_MAGE,
    clientid       = 3,
    name           = "Mage",
    description    = "a mage",
    magicShield    = true,
    allowPvp       = true,
    fromvoc        = VOCATION_MAGE,   -- sin promoción automática (usa la propia)
    noPongKickTime = 40,
    gaincap        = 10,
    gainhp         = 5,
    gainmana       = 30,
    gainhpticks    = 6,
    gainhpamount   = 5,
    gainmanaticks  = 3,
    gainmanaamount = 5,
    manamultiplier = 1.1,
    attackspeed    = 2000,
    basespeed      = 220,
    soulmax        = 100,
    gainsoulticks  = 120,
    formula        = { meleeDamage = 1.0, distDamage = 1.0, defense = 1.0, armor = 1.0 },
    skills         = { 1.5, 2.0, 2.0, 2.0, 2.0, 1.5, 1.1 },
})

-- Shaman
Game.createVocationType({
    id             = VOCATION_SHAMAN,
    clientid       = 4,
    name           = "Shaman",
    description    = "a shaman",
    magicShield    = true,
    allowPvp       = true,
    fromvoc        = VOCATION_SHAMAN,
    noPongKickTime = 40,
    gaincap        = 10,
    gainhp         = 5,
    gainmana       = 30,
    gainhpticks    = 6,
    gainhpamount   = 5,
    gainmanaticks  = 3,
    gainmanaamount = 5,
    manamultiplier = 1.1,
    attackspeed    = 2000,
    basespeed      = 220,
    soulmax        = 100,
    gainsoulticks  = 120,
    formula        = { meleeDamage = 1.0, distDamage = 1.0, defense = 1.0, armor = 1.0 },
    skills         = { 1.5, 1.8, 1.8, 1.8, 1.8, 1.5, 1.1 },
})

-- Archer
Game.createVocationType({
    id             = VOCATION_ARCHER,
    clientid       = 2,
    name           = "Archer",
    description    = "an archer",
    magicShield    = false,
    allowPvp       = true,
    fromvoc        = VOCATION_ARCHER,
    noPongKickTime = 50,
    gaincap        = 20,
    gainhp         = 10,
    gainmana       = 15,
    gainhpticks    = 4,
    gainhpamount   = 5,
    gainmanaticks  = 4,
    gainmanaamount = 5,
    manamultiplier = 1.4,
    attackspeed    = 2000,
    basespeed      = 220,
    soulmax        = 100,
    gainsoulticks  = 120,
    formula        = { meleeDamage = 1.0, distDamage = 1.0, defense = 1.0, armor = 1.0 },
    skills         = { 1.2, 1.2, 1.2, 1.2, 1.1, 1.1, 1.1 },
})

-- Warrior
Game.createVocationType({
    id             = VOCATION_WARRIOR,
    clientid       = 1,
    name           = "Warrior",
    description    = "a warrior",
    magicShield    = false,
    allowPvp       = true,
    fromvoc        = VOCATION_WARRIOR,
    gaincap        = 25,
    gainhp         = 15,
    gainmana       = 5,
    gainhpticks    = 3,
    gainhpamount   = 5,
    gainmanaticks  = 6,
    gainmanaamount = 5,
    manamultiplier = 3.0,
    attackspeed    = 2000,
    basespeed      = 220,
    soulmax        = 100,
    gainsoulticks  = 120,
    formula        = { meleeDamage = 1.0, distDamage = 1.0, defense = 1.0, armor = 1.0 },
    skills         = { 1.1, 1.1, 1.1, 1.1, 1.4, 1.1, 1.1 },
})

-- Master Mage  (promoción de Mage)
Game.createVocationType({
    id             = VOCATION_MASTER_MAGE,
    clientid       = 13,
    name           = "Master Mage",
    description    = "a master mage",
    magicShield    = true,
    allowPvp       = true,
    fromvoc        = VOCATION_MAGE,   -- ← apunta a la vocación base
    noPongKickTime = 40,
    gaincap        = 10,
    gainhp         = 5,
    gainmana       = 30,
    gainhpticks    = 4,
    gainhpamount   = 10,
    gainmanaticks  = 2,
    gainmanaamount = 10,
    manamultiplier = 1.1,
    attackspeed    = 2000,
    basespeed      = 220,
    soulmax        = 200,
    gainsoulticks  = 15,
    formula        = { meleeDamage = 1.0, distDamage = 1.0, defense = 1.0, armor = 1.0 },
    skills         = { 1.5, 2.0, 2.0, 2.0, 2.0, 1.5, 1.1 },
})

-- Elder Shaman  (promoción de Shaman)
Game.createVocationType({
    id             = VOCATION_ELDER_SHAMAN,
    clientid       = 14,
    name           = "Elder Shaman",
    description    = "an elder shaman",
    magicShield    = true,
    allowPvp       = true,
    fromvoc        = VOCATION_SHAMAN,
    noPongKickTime = 40,
    gaincap        = 10,
    gainhp         = 5,
    gainmana       = 30,
    gainhpticks    = 4,
    gainhpamount   = 10,
    gainmanaticks  = 2,
    gainmanaamount = 10,
    manamultiplier = 1.1,
    attackspeed    = 2000,
    basespeed      = 220,
    soulmax        = 200,
    gainsoulticks  = 15,
    formula        = { meleeDamage = 1.0, distDamage = 1.0, defense = 1.0, armor = 1.0 },
    skills         = { 1.5, 1.8, 1.8, 1.8, 1.8, 1.5, 1.1 },
})

-- Royal Archer  (promoción de Archer)
Game.createVocationType({
    id             = VOCATION_ROYAL_ARCHER,
    clientid       = 12,
    name           = "Royal Archer",
    description    = "a royal archer",
    magicShield    = false,
    allowPvp       = true,
    fromvoc        = VOCATION_ARCHER,
    noPongKickTime = 50,
    gaincap        = 20,
    gainhp         = 10,
    gainmana       = 15,
    gainhpticks    = 3,
    gainhpamount   = 10,
    gainmanaticks  = 3,
    gainmanaamount = 10,
    manamultiplier = 1.4,
    attackspeed    = 2000,
    basespeed      = 220,
    soulmax        = 200,
    gainsoulticks  = 15,
    formula        = { meleeDamage = 1.0, distDamage = 1.0, defense = 1.0, armor = 1.0 },
    skills         = { 1.2, 1.2, 1.2, 1.2, 1.1, 1.1, 1.1 },
})

-- Elite Warrior  (promoción de Warrior)
Game.createVocationType({
    id             = VOCATION_ELITE_WARRIOR,
    clientid       = 11,
    name           = "Elite Warrior",
    description    = "an elite warrior",
    magicShield    = false,
    allowPvp       = true,
    fromvoc        = VOCATION_WARRIOR,
    gaincap        = 25,
    gainhp         = 15,
    gainmana       = 5,
    gainhpticks    = 2,
    gainhpamount   = 10,
    gainmanaticks  = 4,
    gainmanaamount = 10,
    manamultiplier = 3.0,
    attackspeed    = 2000,
    basespeed      = 220,
    soulmax        = 200,
    gainsoulticks  = 15,
    formula        = { meleeDamage = 1.0, distDamage = 1.0, defense = 1.0, armor = 1.0 },
    skills         = { 1.1, 1.1, 1.1, 1.1, 1.4, 1.1, 1.1 },
})
