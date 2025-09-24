local function OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        print(event, isLogin, isReload)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", OnEvent)
f:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "BiSTracker" then
        if not BiSTrackerDB then
            BiSTrackerDB = {}
        end
        local itemID = GetInventoryItemID("player", 1)
        BiSTrackerDB.lastEquippedHelm = itemID
        print("Saved itemID: " .. (itemID or "none"))
    end
end)

--- @return string|nil 
local function GetCurrentPlayerClassAndSpec()
    local _, englishClass, _ = UnitClass("player")
    local _, specName, _, _, _ = GetSpecializationInfo(GetSpecialization())
    if not specName then
        print("Could not determine specialization.")
        return nil
    end
    return englishClass:lower() .. "_" .. specName:lower()
end

local function Colorize(text, hex)
    return "|cFF" .. hex .. text .. "|r"
end

local function IsItemUpgrade(itemLink)
    local itemID = tonumber(itemLink:match("item:(%d+):"))
    if not itemID then 
        print("Invalid item link. " .. (itemID or "no itemID found") .. " in link: " .. itemLink)
        return false
    end

    local currentClassSpec = GetCurrentPlayerClassAndSpec()
    if not currentClassSpec then 
        print("Could not determine class/spec.")
        return false
    end

    local currentBiSData = BiSTrackerData[currentClassSpec]
    if not currentBiSData then 
        print("No BiS data available for your class/spec.")
        return false
    end

    for _, slotData in ipairs(currentBiSData) do
        for _, bisItem in pairs(slotData.BiSItems) do
            if bisItem.itemID == itemID then
                return true
            end
        end
    end
    return false
end

f:RegisterEvent("CHAT_MSG_LOOT")
f:SetScript("OnEvent", function(self, event, msg, ...)
    if event ~= "CHAT_MSG_LOOT" then return end
    local itemLink = msg:match("|Hitem:.-|h.-|h")
    if itemLink then
        print("New loot detected: " .. itemLink)
        if IsItemUpgrade(itemLink) then
            print(Colorize("This item is an upgrade!", "00FF00"))
        end
    end
end)

SLASH_BIS1 = "/bis"
SlashCmdList["BIS"] = function()
    local CurrentPlayerBiSGear = BiSTrackerData[GetCurrentPlayerClassAndSpec()]
    if not CurrentPlayerBiSGear then
        print("No BiS data available for your class/spec.")
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
