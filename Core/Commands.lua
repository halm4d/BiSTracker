-- Slash commands for BiS Tracker
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- Commands Manager
BiSTracker.Commands = {}

-- Main BiS Tracker command
SLASH_BISTRACKER1 = "/bistracker"
SLASH_BISTRACKER2 = "/bisui"
SlashCmdList["BISTRACKER"] = function(msg)
    local args = {strsplit(" ", msg:lower())}
    local command = args[1] or ""
    
    if command == "show" or command == "" then
        BiSTracker.Commands.ShowBiSList()
    elseif command == "ui" or command == "window" then
        if BiSTracker.ModernUI and BiSTracker.ModernUI.ToggleMainFrame then
            BiSTracker.ModernUI.ToggleMainFrame()
        elseif BiSTracker.UI and BiSTracker.UI.ToggleMainFrame then
            BiSTracker.UI.ToggleMainFrame()
        else
            BiSTracker.Utils.PrintError("UI module not loaded")
        end
    elseif command == "stats" then
        BiSTracker.Commands.ShowStats()
    elseif command == "help" then
        BiSTracker.Commands.ShowHelp()
    else
        BiSTracker.Commands.ShowBiSList()
    end
end

-- BiS list command
SLASH_BIS1 = "/bis"
SlashCmdList["BIS"] = function()
    BiSTracker.Commands.ShowBiSList()
end

-- Settings command
SLASH_BISSETTINGS1 = "/bissettings"
SLASH_BISSETTINGS2 = "/bistrackersettings"
SlashCmdList["BISSETTINGS"] = function()
    BiSTracker.SettingsUI.OpenSettings()
end

-- Alerts toggle command
SLASH_BISALERTS1 = "/bis-alerts"
SlashCmdList["BISALERTS"] = function(msg)
    local command = msg:lower():trim()
    local currentSetting = BiSTracker.Settings.IsAlertsEnabled()
    
    if command == "on" then
        BiSTracker.Settings.Set("enableAlerts", true)
    elseif command == "off" then
        BiSTracker.Settings.Set("enableAlerts", false)
    elseif command == "test" then
        BiSTracker.Alerts.SendTestAlert()
    else
        -- Toggle
        BiSTracker.Settings.Set("enableAlerts", not currentSetting)
    end
    
    local newSetting = BiSTracker.Settings.IsAlertsEnabled()
    BiSTracker.Utils.Print("Alerts are now " .. (newSetting and "enabled" or "disabled"))
end

-- Command implementations

function BiSTracker.Commands.ShowBiSList()
    local bisData = BiSTracker.DataManager.GetCurrentPlayerBiSGear()
    if not bisData then
        local classSpec = BiSTracker.Utils.GetCurrentPlayerClassAndSpec()
        BiSTracker.Utils.PrintError("No BiS data available for " .. (classSpec or "unknown spec"))
        return
    end
    
    local classSpec = BiSTracker.Utils.GetCurrentPlayerClassAndSpec()
    local title = BiSTracker.Utils.Colorize("BiS Gear for " .. classSpec .. ":", BiSTracker.Constants.COLORS.GOLD)
    print(title)
    
    local hasItems = false
    
    for _, slotData in ipairs(bisData) do
        if not slotData.equipped then
            hasItems = true
            BiSTracker.Commands.PrintSlotInfo(slotData, "missing")
        elseif slotData.upgradeable then
            hasItems = true
            BiSTracker.Commands.PrintSlotInfo(slotData, "upgradeable")
        end
    end
    
    if not hasItems then
        local congrats = BiSTracker.Utils.Colorize("Congratulations! You have all BiS items equipped!", BiSTracker.Constants.COLORS.GREEN)
        print(congrats)
    end
end

---@param slotData table Slot data to print
---@param status string Status: "missing" or "upgradeable"
function BiSTracker.Commands.PrintSlotInfo(slotData, status)
    local slotName = BiSTracker.Utils.Colorize(slotData.Slot, BiSTracker.Constants.COLORS.LIGHT_BLUE)
    
    if status == "missing" then
        print(slotName .. ":")
    else
        local upgradeText = BiSTracker.Utils.Colorize("Upgrade available!", BiSTracker.Constants.COLORS.ORANGE)
        print(slotName .. ": " .. upgradeText)
    end
    
    -- Show available options
    if not slotData.BiSItems.overall.equipped then
        BiSTracker.Commands.PrintItemInfo("Overall BiS", slotData.BiSItems.overall)
    end
    if not slotData.BiSItems.raid.equipped then
        BiSTracker.Commands.PrintItemInfo("Raid BiS", slotData.BiSItems.raid)
    end
    if not slotData.BiSItems.mythic_plus.equipped then
        BiSTracker.Commands.PrintItemInfo("M+ BiS", slotData.BiSItems.mythic_plus)
    end
end

---@param label string Item label
---@param itemData table Item data
function BiSTracker.Commands.PrintItemInfo(label, itemData)
    if not itemData or not itemData.name then
        return
    end
    
    local itemName = BiSTracker.Utils.Colorize(itemData.name, BiSTracker.Constants.COLORS.GREEN)
    local source = BiSTracker.Utils.Colorize(itemData.source, BiSTracker.Constants.COLORS.WHITE)
    print("  " .. label .. ": " .. itemName .. " - Source: " .. source)
end

function BiSTracker.Commands.ShowStats()
    local stats = BiSTracker.DataManager.GetBiSStats()
    
    local title = BiSTracker.Utils.Colorize("BiS Gear Statistics:", BiSTracker.Constants.COLORS.GOLD)
    print(title)
    
    print("Total BiS slots: " .. BiSTracker.Utils.Colorize(tostring(stats.total), BiSTracker.Constants.COLORS.WHITE))
    print("Equipped: " .. BiSTracker.Utils.Colorize(tostring(stats.equipped), BiSTracker.Constants.COLORS.GREEN))
    print("Missing: " .. BiSTracker.Utils.Colorize(tostring(stats.missing), BiSTracker.Constants.COLORS.RED))
    print("Upgradeable: " .. BiSTracker.Utils.Colorize(tostring(stats.upgradeable), BiSTracker.Constants.COLORS.ORANGE))
    
    if stats.total > 0 then
        local percentage = math.floor((stats.equipped / stats.total) * 100)
        local percentColor = percentage >= 75 and BiSTracker.Constants.COLORS.GREEN or 
                            percentage >= 50 and BiSTracker.Constants.COLORS.ORANGE or 
                            BiSTracker.Constants.COLORS.RED
        print("Completion: " .. BiSTracker.Utils.Colorize(percentage .. "%", percentColor))
    end
end

function BiSTracker.Commands.ShowHelp()
    local title = BiSTracker.Utils.Colorize("BiS Tracker Commands:", BiSTracker.Constants.COLORS.GOLD)
    print(title)
    
    print("/bis or /bistracker - Show missing BiS items")
    print("/bis ui - Toggle UI window")
    print("/bis stats - Show BiS gear statistics")
    print("/bis help - Show this help")
    print("/bis-alerts [on|off|test] - Toggle alerts or send test")
    print("/bissettings - Open settings panel")
end

-- Export
_G.BiSTracker = BiSTracker