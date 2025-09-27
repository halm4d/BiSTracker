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

    -- Initialize core systems first
    if self.Settings and self.Settings.Initialize then
        self.Settings.Initialize()
    end

    -- Initialize all UI components via UIManager
    if self.UIManager and self.UIManager.Initialize then
        self.UIManager.Initialize()
    else
        -- Fallback initialization if UIManager isn't available
        if self.ModernUI and self.ModernUI.Initialize then
            self.ModernUI.Initialize()
        end
        if self.MinimapUI and self.MinimapUI.Initialize then
            self.MinimapUI.Initialize()
        end
        if self.SettingsUI and self.SettingsUI.Initialize then
            self.SettingsUI.Initialize()
        end
    end

    -- Mark as initialized
    self.initialized = true
    
    print("BiS Tracker loaded successfully")
end

-- Register initialization event
BiSTracker.Events.RegisterEvent("PLAYER_LOGIN", function()
    BiSTracker:Initialize()
end)

-- Export
_G.BiSTracker = BiSTracker
