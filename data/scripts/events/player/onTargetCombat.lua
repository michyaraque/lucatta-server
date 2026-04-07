local ec = EventCallback

ec.onTargetCombat = function(self, target)
    target:registerEvent("UpgradeSystemHealth")
    target:registerEvent("UpgradeSystemDeath")
    return true
    --return RETURNVALUE_NOERROR
end

ec:register()
