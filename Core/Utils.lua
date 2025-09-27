-- Core utilities and helper functions for BiS Tracker
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- Utility Functions
BiSTracker.Utils = {}

---@param text string
---@param hexColor string Color hex code without FF prefix
---@return string colorizedText
function BiSTracker.Utils.Colorize(text, hexColor)
    if not text or not hexColor then
        return text or ""
    end
    return "|cFF" .. hexColor .. text .. "|r"
end

---@param message string
---@param color string|nil Optional color hex code
function BiSTracker.Utils.Print(message, color)
    local prefix = BiSTracker.Utils.Colorize("[BiS Tracker]", BiSTracker.Constants.COLORS.GOLD)
    local coloredMessage = color and BiSTracker.Utils.Colorize(message, color) or message
    print(prefix .. " " .. coloredMessage)
end

---@param message string
---@param color string|nil Optional color hex code
function BiSTracker.Utils.PrintError(message, color)
    BiSTracker.Utils.Print("ERROR: " .. message, color or BiSTracker.Constants.COLORS.RED)
end

---@param message string
---@param color string|nil Optional color hex code
function BiSTracker.Utils.PrintDebug(message, color)
    if BiSTrackerDB and BiSTrackerDB.debugMode then
        BiSTracker.Utils.Print("DEBUG: " .. message, color or BiSTracker.Constants.COLORS.GRAY)
    end
end

---@return string|nil classSpec Returns "class_spec" format or nil if unavailable
function BiSTracker.Utils.GetCurrentPlayerClassAndSpec()
    local _, englishClassName = UnitClass("player")
    if not englishClassName then
        return nil
    end
    
    -- Use loot specialization instead of current specialization
    local lootSpecID = GetLootSpecialization()
    local specIndex
    
    if lootSpecID == 0 then
        -- Loot spec is set to "Current Spec", so use current specialization
        specIndex = GetSpecialization()
        BiSTracker.Utils.PrintDebug("Using current specialization (loot spec set to current)")
    else
        -- Convert loot spec ID to spec index
        for i = 1, GetNumSpecializations() do
            local specID = GetSpecializationInfo(i)
            if specID == lootSpecID then
                specIndex = i
                break
            end
        end
        BiSTracker.Utils.PrintDebug("Using loot specialization ID: " .. lootSpecID)
    end
    
    if not specIndex then
        BiSTracker.Utils.PrintDebug("No valid specialization found")
        return nil
    end
    
    local _, specName = GetSpecializationInfo(specIndex)
    if not specName then
        BiSTracker.Utils.PrintDebug("Could not get specialization name for index: " .. specIndex)
        return nil
    end
    
    local result = englishClassName:lower() .. "_" .. specName:lower()
    BiSTracker.Utils.PrintDebug("Class/Spec result: " .. result)
    return result
end

-- Helper function to get loot specialization display name
---@return string specName Display name of the current loot specialization
function BiSTracker.Utils.GetLootSpecDisplayName()
    local lootSpecID = GetLootSpecialization()
    
    if lootSpecID == 0 then
        -- Loot spec is set to "Current Spec"
        local specIndex = GetSpecialization()
        if specIndex then
            local _, specName = GetSpecializationInfo(specIndex)
            return specName or "No Spec"
        end
        return "Current Spec (None Selected)"
    else
        -- Find the spec name from loot spec ID
        for i = 1, GetNumSpecializations() do
            local specID, name = GetSpecializationInfo(i)
            if specID == lootSpecID then
                return name or "Unknown"
            end
        end
        return "Unknown Loot Spec"
    end
end

---@param itemID number
---@return boolean isEquipped
function BiSTracker.Utils.IsItemEquipped(itemID)
    if not itemID then
        return false
    end
    
    for slot = 1, 18 do -- Check all equipment slots
        local equippedItemID = GetInventoryItemID("player", slot)
        if equippedItemID == itemID then
            return true
        end
    end
    return false
end

---@param itemLink string
---@return number|nil itemID
function BiSTracker.Utils.GetItemIDFromLink(itemLink)
    if not itemLink then
        return nil
    end
    
    local itemID = tonumber(itemLink:match("item:(%d+):"))
    return itemID
end

---@param func function
---@param delay number
---@return table timer
function BiSTracker.Utils.ScheduleTimer(func, delay)
    return C_Timer.NewTimer(delay, func)
end

---@param func function
---@param delay number
---@return table timer
function BiSTracker.Utils.ScheduleRepeatingTimer(func, delay)
    return C_Timer.NewTicker(delay, func)
end

---@param tbl table
---@return number count
function BiSTracker.Utils.TableCount(tbl)
    if not tbl then
        return 0
    end
    
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

---@param tbl table
---@return boolean isEmpty
function BiSTracker.Utils.IsTableEmpty(tbl)
    return not tbl or next(tbl) == nil
end

---@param source table
---@param target table
---@return table merged
function BiSTracker.Utils.MergeTables(source, target)
    target = target or {}
    if not source then
        return target
    end
    
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            target[key] = BiSTracker.Utils.MergeTables(value, target[key])
        else
            target[key] = value
        end
    end
    return target
end

---@param value any
---@param default any
---@return any result
function BiSTracker.Utils.DefaultValue(value, default)
    return value ~= nil and value or default
end

-- Export
_G.BiSTracker = BiSTracker