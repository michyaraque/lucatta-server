local talk = TalkAction("/stats", "!stats")

function talk.onSay(player, words, param)

    local message = "Character Stats:\n"
    -- Usamos .. para concatenar el valor anterior con el nuevo
    message = message .. string.format("Speed: %d\n", player:getSpeed())
    message = message .. string.format("Sword Level: %d\n", player:getSkillLevel(SKILL_SWORD))
    message = message .. string.format("Axe Level: %d\n", player:getSkillLevel(SKILL_AXE))
    message = message .. string.format("Club Level: %d\n", player:getSkillLevel(SKILL_CLUB))
    message = message .. string.format("Distance Level: %d\n", player:getSkillLevel(SKILL_DISTANCE))
    message = message .. string.format("Shield Level: %d\n", player:getSkillLevel(SKILL_SHIELD))
    message = message .. string.format("Magic Level: %d", player:getMagicLevel())

    player:sendTextMessage(MESSAGE_INFO_DESCR, message)
    return true
end

talk:separator(" ")
talk:register()
