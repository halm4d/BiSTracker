-- BiS Tracker - Refactored Main Entry Point
-- This file maintains backward compatibility while loading the new modular structure

local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- Initialize the addon
function BiSTracker:Initialize()
    if self.initialized then
        return
    end

    -- Initialize settings first
    self.Settings.Initialize()

    -- Initialize UI components
    self.UI.Initialize()
    self.ModernUI.Initialize()  -- Initialize the new modern UI
    self.SettingsUI.Initialize()

    -- Mark as initialized
    self.initialized = true

end

-- Register initialization event
BiSTracker.Events.RegisterEvent("PLAYER_LOGIN", function()
    BiSTracker:Initialize()
end)

-- Export
_G.BiSTracker = BiSTracker
