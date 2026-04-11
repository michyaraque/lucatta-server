-- Skeleton King - Arena Trigger
-- Cuando el jugador pisa {x=71, y=11, z=8} se genera el boss si no hay uno vivo.

local TRIGGER_POS  = Position(71, 11, 8)
local BOSS_SPAWN   = Position(155, 60, 7)   -- centro de la arena
local BOSS_NAME    = "Skeleton King"

local triggerStep = MoveEvent()

function triggerStep.onStepIn(creature, item, position, fromPosition)
	if not creature:isPlayer() then
		return true
	end

	-- Buscar si ya hay un Skeleton King vivo en la arena
	local spectators = Game.getSpectators(BOSS_SPAWN, false, false, 9, 9, 11, 11)
	for _, spec in ipairs(spectators) do
		if spec:isMonster() and spec:getName() == BOSS_NAME then
			-- Ya existe, no hacer nada
			return true
		end
	end

	-- No hay boss vivo — generarlo
	local boss = Game.createMonster(BOSS_NAME, BOSS_SPAWN, false, true)
	if boss then
		BOSS_SPAWN:sendMagicEffect(CONST_ME_MORTAREA)
	end

	return true
end

triggerStep:position(TRIGGER_POS)
triggerStep:register()
