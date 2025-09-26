local function OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        print(event, isLogin, isReload)
    elseif event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "BiSTracker" then
            if not BiSTrackerDB then
                BiSTrackerDB = {}
            end
            -- Set default values if not already set
            if BiSTrackerDB.enableAlerts == nil then
                BiSTrackerDB.enableAlerts = true -- Default to enabled
            end

            local itemID = GetInventoryItemID("player", 1)
            BiSTrackerDB.lastEquippedHelm = itemID
            print("Saved itemID: " .. (itemID or "none"))

            -- Register CHAT_MSG_LOOT only if alerts are enabled
            UpdateLootEventRegistration()
        end
    elseif event == "CHAT_MSG_LOOT" then
        local msg = ...
        local itemLink = msg:match("|Hitem:.-|h.-|h")
        if itemLink then
            if IsItemUpgrade(itemLink) then
                SendAlert(Colorize("BiS item dropped!", "00FF00"))
            end
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)

-- Function to register/unregister CHAT_MSG_LOOT based on settings
function UpdateLootEventRegistration()
    if BiSTrackerDB and BiSTrackerDB.enableAlerts then
        f:RegisterEvent("CHAT_MSG_LOOT")
        print("BiS Tracker: Loot alerts enabled")
    else
        f:UnregisterEvent("CHAT_MSG_LOOT")
        print("BiS Tracker: Loot alerts disabled")
    end
end

--- @return string|nil
function GetCurrentPlayerClassAndSpec()
    local _, englishClassName, _ = UnitClass("player")
    local _, specName, _, _, _ = GetSpecializationInfo(GetSpecialization())
    if not specName then
        return nil
    end
    return englishClassName:lower() .. "_" .. specName:lower()
end

function Colorize(text, hex)
    return "|cFF" .. hex .. text .. "|r"
end

function SendAlert(message)
    local alert = CreateFrame("Frame", nil, UIParent)
    alert:SetSize(800, 200)
    alert:SetPoint("CENTER", UIParent, "CENTER")

    local text = alert:CreateFontString(nil, "OVERLAY", "Game72Font_Shadow")
    text:SetPoint("CENTER")
    text:SetText(message)

    PlaySound(SOUNDKIT.RAID_WARNING, "Master")

    alert:Show()
    C_Timer.After(3, function() alert:Hide() end)
end

function IsItemUpgrade(itemLink)
    local itemID = tonumber(itemLink:match("item:(%d+):"))
    if not itemID then 
        return false
    end

    local currentClassSpec = GetCurrentPlayerClassAndSpec()
    if not currentClassSpec then
        return false
    end

    local currentBiSData = GetCurrentPlayerBiSGear()
    if not currentBiSData then
        return false
    end

    for _, slotData in ipairs(currentBiSData) do
        for _, bisItem in pairs(slotData.BiSItems) do
            if bisItem.overall.itemID == itemID then
                return true
            elseif bisItem.raid.itemID == itemID then
                return true
            elseif bisItem.mythic_plus.itemID == itemID then
                return true
            end
        end
    end
    return false
end

-- Slash command to toggle alerts
SLASH_BIS_ALERTS1 = "/bis-alerts"
SlashCmdList["BIS_ALERTS"] = function(msg)
    if not BiSTrackerDB then
        BiSTrackerDB = {}
    end

    if msg == "on" then
        BiSTrackerDB.enableAlerts = true
        UpdateLootEventRegistration()
    elseif msg == "off" then
        BiSTrackerDB.enableAlerts = false
        UpdateLootEventRegistration()
    else
        -- Toggle
        BiSTrackerDB.enableAlerts = not BiSTrackerDB.enableAlerts
        UpdateLootEventRegistration()
    end

    print("BiS Tracker: Alerts are now " .. (BiSTrackerDB.enableAlerts and "enabled" or "disabled"))
end

function GetCurrentPlayerBiSGear()
    local CurrentPlayerBiSGear = BiSTrackerData[GetCurrentPlayerClassAndSpec()]
    if not CurrentPlayerBiSGear then
        return
    end
    for _, slotData in ipairs(CurrentPlayerBiSGear) do
        if IsItemEquipped(slotData.BiSItems.overall.itemID) then
            slotData.equipped = true
            slotData.upgradeable = false
            slotData.BiSItems.overall.equipped = true
        elseif IsItemEquipped(slotData.BiSItems.raid.itemID) then
            slotData.equipped = true
            slotData.upgradeable = true
            slotData.BiSItems.raid.equipped = true
        elseif IsItemEquipped(slotData.BiSItems.mythic_plus.itemID) then
            slotData.equipped = true
            slotData.upgradeable = true
            slotData.BiSItems.mythic_plus.equipped = true
        else
            slotData.equipped = false
            slotData.upgradeable = true
        end
    end
    return CurrentPlayerBiSGear
end

SLASH_BIS1 = "/bis"
SlashCmdList["BIS"] = function()
    local CurrentPlayerBiSGear = GetCurrentPlayerBiSGear()
    if not CurrentPlayerBiSGear then
        return
    end

    print(Colorize("Missing BiS Gear for " .. GetCurrentPlayerClassAndSpec() .. ":", "FFD700"))
    for _, slotData in ipairs(CurrentPlayerBiSGear) do
        if not slotData.equipped then
            print(Colorize(slotData.Slot, "00BFFF") .. ":") -- slot = light blue
            print("  Overall BiS: " .. Colorize(slotData.BiSItems.overall.name, "00FF00")
                .. " - Source: " .. Colorize(slotData.BiSItems.overall.source, "FFFFFF"))
            print("  Raid BiS: " .. Colorize(slotData.BiSItems.raid.name, "00FF00")
                .. " - Source: " .. Colorize(slotData.BiSItems.raid.source, "FFFFFF"))
            print("  Mythic+ BiS: " .. Colorize(slotData.BiSItems.mythic_plus.name, "00FF00")
                .. " - Source: " .. Colorize(slotData.BiSItems.mythic_plus.source, "FFFFFF"))
        elseif slotData.upgradeable then
            print(Colorize(slotData.Slot, "00BFFF") .. ": " .. Colorize("Upgrade available!", "FF8C00"))
            if not slotData.BiSItems.overall.equipped then
                print("  Overall BiS: " .. Colorize(slotData.BiSItems.overall.name, "00FF00")
                    .. " - Source: " .. Colorize(slotData.BiSItems.overall.source, "FFFFFF"))
            end
            if not slotData.BiSItems.raid.equipped then
                print("  Raid BiS: " .. Colorize(slotData.BiSItems.raid.name, "00FF00")
                    .. " - Source: " .. Colorize(slotData.BiSItems.raid.source, "FFFFFF"))
            end
            if not slotData.BiSItems.mythic_plus.equipped then
                print("  Mythic+ BiS: " .. Colorize(slotData.BiSItems.mythic_plus.name, "00FF00")
                    .. " - Source: " .. Colorize(slotData.BiSItems.mythic_plus.source, "FFFFFF"))
            end
        end
    end
end

function IsItemEquipped(itemID)
    for slot = 1, 17 do
        local equippedItemID = GetInventoryItemID("player", slot)
        if equippedItemID == itemID then
            return true
        end
    end
    return false
end
