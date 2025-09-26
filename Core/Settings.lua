-- Settings manager for BiS Tracker
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- Settings Manager
BiSTracker.Settings = {}

local defaults = {
    enableAlerts = true,
    showAllItems = true,
    showMinimap = true,
    minimapPosition = 45,
    debugMode = false,
    alertSound = true,
    alertDuration = 3,
}

---Initialize settings with defaults
function BiSTracker.Settings.Initialize()
    BiSTrackerDB = BiSTrackerDB or {}
    
    -- Merge defaults with existing settings
    for key, value in pairs(defaults) do
        if BiSTrackerDB[key] == nil then
            BiSTrackerDB[key] = value
        end
    end
end

---@param key string Setting key
---@return any value Setting value or nil
function BiSTracker.Settings.Get(key)
    if not BiSTrackerDB then
        BiSTracker.Settings.Initialize()
    end
    return BiSTrackerDB[key]
end

---@param key string Setting key
---@param value any Setting value
function BiSTracker.Settings.Set(key, value)
    if not BiSTrackerDB then
        BiSTracker.Settings.Initialize()
    end
    BiSTrackerDB[key] = value
    
    -- Trigger setting-specific callbacks
    BiSTracker.Settings.OnSettingChanged(key, value)
end

---@param key string Setting key
---@param value any New value
function BiSTracker.Settings.OnSettingChanged(key, value)
    if key == "enableAlerts" then
        BiSTracker.Events.UpdateLootEventRegistration()
    elseif key == "showMinimap" then
        BiSTracker.UI.UpdateMinimapButtonVisibility()
    elseif key == "debugMode" then
        BiSTracker.Utils.PrintDebug("Debug mode " .. (value and "enabled" or "disabled"))
    end
end

---Reset all settings to defaults
function BiSTracker.Settings.Reset()
    if not BiSTrackerDB then
        BiSTracker.Settings.Initialize()
        return
    end
    
    for key, value in pairs(defaults) do
        BiSTrackerDB[key] = value
    end
    
    BiSTracker.Utils.Print("Settings reset to defaults")
end

---@return boolean enabled
function BiSTracker.Settings.IsAlertsEnabled()
    return BiSTracker.Settings.Get("enableAlerts") == true
end

---@return boolean showAll
function BiSTracker.Settings.ShouldShowAllItems()
    return BiSTracker.Settings.Get("showAllItems") == true
end

---@return boolean showMinimap
function BiSTracker.Settings.ShouldShowMinimap()
    return BiSTracker.Settings.Get("showMinimap") == true
end

---@return boolean debugMode
function BiSTracker.Settings.IsDebugMode()
    return BiSTracker.Settings.Get("debugMode") == true
end

-- Export
_G.BiSTracker = BiSTracker