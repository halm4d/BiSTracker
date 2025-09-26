-- Event manager for BiS Tracker
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- Event Manager
BiSTracker.Events = {}

local eventFrame = CreateFrame("Frame", "BiSTrackerEventFrame")
local registeredEvents = {}

---@param event string Event name
---@param handler function Event handler function
function BiSTracker.Events.RegisterEvent(event, handler)
    if not registeredEvents[event] then
        registeredEvents[event] = {}
        eventFrame:RegisterEvent(event)
    end
    
    table.insert(registeredEvents[event], handler)
end

---@param event string Event name
---@param handler function|nil Specific handler to unregister, or nil for all
function BiSTracker.Events.UnregisterEvent(event, handler)
    if not registeredEvents[event] then
        return
    end
    
    if handler then
        for i, h in ipairs(registeredEvents[event]) do
            if h == handler then
                table.remove(registeredEvents[event], i)
                break
            end
        end
        
        if #registeredEvents[event] == 0 then
            eventFrame:UnregisterEvent(event)
            registeredEvents[event] = nil
        end
    else
        eventFrame:UnregisterEvent(event)
        registeredEvents[event] = nil
    end
end

---Main event handler
local function OnEvent(self, event, ...)
    local handlers = registeredEvents[event]
    if handlers then
        for _, handler in ipairs(handlers) do
            local success, error = pcall(handler, event, ...)
            if not success then
                BiSTracker.Utils.PrintError("Error in event handler for " .. event .. ": " .. tostring(error))
            end
        end
    end
end

eventFrame:SetScript("OnEvent", OnEvent)

-- Specific Event Handlers

---@param event string
---@param addonName string
function BiSTracker.Events.OnAddonLoaded(event, addonName)
    if addonName ~= "BiSTracker" then
        return
    end
    
    -- Initialize settings
    BiSTracker.Settings.Initialize()
    
    -- Update loot event registration based on settings
    BiSTracker.Events.UpdateLootEventRegistration()
    
    -- Debug info
    local itemID = GetInventoryItemID("player", BiSTracker.Constants.INVENTORY_SLOTS.HEAD)
    if itemID then
        BiSTracker.Utils.PrintDebug("Helm item ID: " .. itemID)
    end
    
    BiSTracker.Utils.Print("Addon loaded successfully!")
end

---@param event string
---@param isLogin boolean
---@param isReload boolean
function BiSTracker.Events.OnPlayerEnteringWorld(event, isLogin, isReload)
    BiSTracker.Utils.PrintDebug("Player entering world - Login: " .. tostring(isLogin) .. ", Reload: " .. tostring(isReload))
    
    if isLogin then
        -- Initialize UI after login
        if BiSTracker.UI and BiSTracker.UI.Initialize then
            BiSTracker.UI.Initialize()
        end
    end
end

---@param event string
---@param message string
function BiSTracker.Events.OnLootMessage(event, message)
    if not BiSTracker.Settings.IsAlertsEnabled() then
        return
    end
    
    local itemLink = message:match("|Hitem:.-|h.-|h")
    if not itemLink then
        return
    end
    
    local itemID = BiSTracker.Utils.GetItemIDFromLink(itemLink)
    if itemID and BiSTracker.DataManager.IsItemBiSForCurrentSpec(itemID) then
        local itemName = itemLink:match("|h%[(.-)%]|h") or "Unknown Item"
        local alertMessage = BiSTracker.Utils.Colorize("BiS item dropped: " .. itemName, BiSTracker.Constants.COLORS.GREEN)
        BiSTracker.Alerts.SendAlert(alertMessage)
    end
end

---Update loot event registration based on settings
function BiSTracker.Events.UpdateLootEventRegistration()
    if BiSTracker.Settings.IsAlertsEnabled() then
        BiSTracker.Events.RegisterEvent("CHAT_MSG_LOOT", BiSTracker.Events.OnLootMessage)
        BiSTracker.Utils.Print("Loot alerts enabled")
    else
        BiSTracker.Events.UnregisterEvent("CHAT_MSG_LOOT", BiSTracker.Events.OnLootMessage)
        BiSTracker.Utils.Print("Loot alerts disabled")
    end
end

-- Initialize core events
BiSTracker.Events.RegisterEvent("ADDON_LOADED", BiSTracker.Events.OnAddonLoaded)
BiSTracker.Events.RegisterEvent("PLAYER_ENTERING_WORLD", BiSTracker.Events.OnPlayerEnteringWorld)

-- Export
_G.BiSTracker = BiSTracker