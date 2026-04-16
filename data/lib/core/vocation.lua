-- ============================================================
-- SISTEMA CENTRALIZADO DE VOCACIONES
-- Para renombrar una vocación en el futuro: cambia SOLO aquí
-- (más el name/description en data/XML/vocations.xml)
-- ============================================================

-- Nombres canónicos (deben coincidir exactamente con vocations.xml)
local VOC_NAME = {
	MAGE          = "mage",
	MASTER_MAGE   = "master mage",
	WARRIOR       = "warrior",
	ELITE_WARRIOR = "elite warrior",
	SHAMAN        = "shaman",
	ELDER_SHAMAN  = "elder shaman",
	ARCHER        = "archer",
	ROYAL_ARCHER  = "royal archer",
}

-- Grupos listos para usar en spell:vocation()
-- Uso: spell:vocation(table.unpack(VOC_GROUPS.WARRIORS))
-- El patrón "name;true" muestra la vocación base en la descripción del hechizo.
-- El patrón "name" (sin ;true) oculta la vocación promovida de la descripción.
VOC_GROUPS = {
	-- Base shown, promoted hidden (patrón estándar para runas/hechizos)
	MAGES         = {VOC_NAME.MAGE .. ";true",    VOC_NAME.MASTER_MAGE},
	WARRIORS      = {VOC_NAME.WARRIOR .. ";true",  VOC_NAME.ELITE_WARRIOR},
	SHAMANS       = {VOC_NAME.SHAMAN .. ";true",   VOC_NAME.ELDER_SHAMAN},
	ARCHERS       = {VOC_NAME.ARCHER .. ";true",   VOC_NAME.ROYAL_ARCHER},
	-- Ambas mostradas en descripción (hechizos exclusivos de voc promovida)
	MAGES_ALL     = {VOC_NAME.MAGE .. ";true",    VOC_NAME.MASTER_MAGE .. ";true"},
	WARRIORS_ALL  = {VOC_NAME.WARRIOR .. ";true",  VOC_NAME.ELITE_WARRIOR .. ";true"},
	SHAMANS_ALL   = {VOC_NAME.SHAMAN .. ";true",   VOC_NAME.ELDER_SHAMAN .. ";true"},
	ARCHERS_ALL   = {VOC_NAME.ARCHER .. ";true",   VOC_NAME.ROYAL_ARCHER .. ";true"},
	-- Combinaciones frecuentes
	MAGIC         = {VOC_NAME.MAGE .. ";true", VOC_NAME.MASTER_MAGE .. ";true",
	                 VOC_NAME.SHAMAN .. ";true", VOC_NAME.ELDER_SHAMAN .. ";true"},
	PHYSICAL      = {VOC_NAME.WARRIOR .. ";true", VOC_NAME.ELITE_WARRIOR .. ";true",
	                 VOC_NAME.ARCHER .. ";true",  VOC_NAME.ROYAL_ARCHER .. ";true"},
	ALL           = {VOC_NAME.MAGE .. ";true",    VOC_NAME.MASTER_MAGE .. ";true",
	                 VOC_NAME.WARRIOR .. ";true",  VOC_NAME.ELITE_WARRIOR .. ";true",
	                 VOC_NAME.SHAMAN .. ";true",   VOC_NAME.ELDER_SHAMAN .. ";true",
	                 VOC_NAME.ARCHER .. ";true",   VOC_NAME.ROYAL_ARCHER .. ";true"},
}

-- Textos para mensajes de restricción (potions, items, NPCs)
-- Uso: "Only " .. VOC_DESC.WARRIORS .. " may drink this."
VOC_DESC = {
	MAGE          = "mage",
	MASTER_MAGE   = "master mage",
	WARRIOR       = "warrior",
	ELITE_WARRIOR = "elite warrior",
	SHAMAN        = "shaman",
	ELDER_SHAMAN  = "elder shaman",
	ARCHER        = "archer",
	ROYAL_ARCHER  = "royal archer",
	-- Grupos
	MAGES         = "mages and master mages",
	WARRIORS      = "warriors and elite warriors",
	SHAMANS       = "shamans and elder shamans",
	ARCHERS       = "archers and royal archers",
	MAGIC         = "mages, master mages, shamans and elder shamans",
	PHYSICAL      = "warriors, elite warriors, archers and royal archers",
}

-- ============================================================

function Vocation.getBase(self)
	local base = self
	while base:getDemotion() do
		base = base:getDemotion()
	end
	return base
end

function Vocation.getFromVocation(self)
	local demotion = self:getDemotion()
	if demotion then
		return demotion
	end
	return self
end

function Vocation.getRelated(self)
	local vocations = {}
	local related = self
	repeat
		vocations[#vocations + 1] = related
		related = related:getPromotion()
	until not related
	return vocations
end
