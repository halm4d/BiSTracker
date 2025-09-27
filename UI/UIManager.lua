-- UI Manager for BiS Tracker - Coordinates all UI components
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- UI Manager
BiSTracker.UIManager = {}

-- UI state
local initialized = false

-- Initialize all UI components
function BiSTracker.UIManager.Initialize()
    if initialized then
        return
    end

    -- Initialize UI components in order
    if BiSTracker.ModernUI and BiSTracker.ModernUI.Initialize then
        BiSTracker.ModernUI.Initialize()
    end

    if BiSTracker.MinimapUI and BiSTracker.MinimapUI.Initialize then
        BiSTracker.MinimapUI.Initialize()
    end

    if BiSTracker.SettingsUI and BiSTracker.SettingsUI.Initialize then
        BiSTracker.SettingsUI.Initialize()
    end

    initialized = true
    if BiSTracker.Utils and BiSTracker.Utils.PrintDebug then
        BiSTracker.Utils.PrintDebug("UI Manager initialized all components")
    end
end

-- Handle settings changes that affect multiple UI components
function BiSTracker.UIManager.OnSettingChanged(settingKey, value)
    if settingKey == "showMinimap" then
        if BiSTracker.MinimapUI and BiSTracker.MinimapUI.UpdateMinimapButtonVisibility then
            BiSTracker.MinimapUI.UpdateMinimapButtonVisibility()
        end
    end
    
    -- Refresh settings UI if it exists
    if BiSTracker.SettingsUI and BiSTracker.SettingsUI.RefreshSettingsUI then
        BiSTracker.SettingsUI.RefreshSettingsUI()
    end
end

-- Toggle the main BiS Tracker window
function BiSTracker.UIManager.ToggleMainWindow()
    if BiSTracker.ModernUI and BiSTracker.ModernUI.ToggleMainFrame then
        BiSTracker.ModernUI.ToggleMainFrame()
    else
        print("BiS Tracker: Main UI not available")
    end
end

-- Open settings interface
function BiSTracker.UIManager.OpenSettings()
    if BiSTracker.SettingsUI and BiSTracker.SettingsUI.OpenSettings then
        BiSTracker.SettingsUI.OpenSettings()
    else
        print("BiS Tracker: Settings UI not available")
    end
end

-- Export
_G.BiSTracker = BiSTracker