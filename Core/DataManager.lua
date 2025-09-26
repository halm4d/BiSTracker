-- Data manager for BiS Tracker
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- Data Manager
BiSTracker.DataManager = {}

---@return table|nil bisData Current player's BiS data
function BiSTracker.DataManager.GetCurrentPlayerBiSData()
    local classSpec = BiSTracker.Utils.GetCurrentPlayerClassAndSpec()
    if not classSpec or not BiSTrackerData then
        return nil
    end
    
    return BiSTrackerData[classSpec]
end

---@return table|nil processedData Processed BiS data with equipped status
function BiSTracker.DataManager.GetCurrentPlayerBiSGear()
    local rawData = BiSTracker.DataManager.GetCurrentPlayerBiSData()
    if not rawData then
        return nil
    end
    
    -- Deep copy the data to avoid modifying the original
    local processedData = {}
    for i, slotData in ipairs(rawData) do
        processedData[i] = BiSTracker.DataManager.ProcessSlotData(slotData)
    end
    
    return processedData
end

---@param slotData table Original slot data
---@return table processedSlot Processed slot data with equipped flags
function BiSTracker.DataManager.ProcessSlotData(slotData)
    local processed = {
        Slot = slotData.Slot,
        equipped = false,
        upgradeable = false,
        BiSItems = {
            overall = BiSTracker.DataManager.ProcessItemData(slotData.BiSItems.overall),
            raid = BiSTracker.DataManager.ProcessItemData(slotData.BiSItems.raid),
            mythic_plus = BiSTracker.DataManager.ProcessItemData(slotData.BiSItems.mythic_plus),
        }
    }
    
    -- Check if any variant is equipped
    if processed.BiSItems.overall.equipped then
        processed.equipped = true
        processed.upgradeable = false
    elseif processed.BiSItems.raid.equipped or processed.BiSItems.mythic_plus.equipped then
        processed.equipped = true
        processed.upgradeable = true
    else
        processed.equipped = false
        processed.upgradeable = true
    end
    
    return processed
end

---@param itemData table Original item data
---@return table processedItem Processed item data with equipped flag
function BiSTracker.DataManager.ProcessItemData(itemData)
    if not itemData then
        return {}
    end
    
    local processed = {
        itemID = itemData.itemID,
        name = itemData.name or "Unknown Item",
        source = itemData.source or "Unknown Source",
        equipped = false,
    }
    
    if processed.itemID then
        processed.equipped = BiSTracker.Utils.IsItemEquipped(processed.itemID)
    end
    
    return processed
end

---@param itemID number Item ID to check
---@return boolean isBiS True if item is BiS for current spec
function BiSTracker.DataManager.IsItemBiSForCurrentSpec(itemID)
    if not itemID then
        return false
    end
    
    local bisData = BiSTracker.DataManager.GetCurrentPlayerBiSData()
    if not bisData then
        return false
    end
    
    for _, slotData in ipairs(bisData) do
        local bisItems = slotData.BiSItems
        if bisItems then
            if (bisItems.overall and bisItems.overall.itemID == itemID) or
               (bisItems.raid and bisItems.raid.itemID == itemID) or
               (bisItems.mythic_plus and bisItems.mythic_plus.itemID == itemID) then
                return true
            end
        end
    end
    
    return false
end

---@param showEquipped boolean Whether to include equipped items
---@return table filteredData Filtered BiS data
function BiSTracker.DataManager.GetFilteredBiSData(showEquipped)
    local allData = BiSTracker.DataManager.GetCurrentPlayerBiSGear()
    if not allData then
        return {}
    end
    
    if showEquipped then
        return allData
    end
    
    local filtered = {}
    for _, slotData in ipairs(allData) do
        if not slotData.equipped or slotData.upgradeable then
            table.insert(filtered, slotData)
        end
    end
    
    return filtered
end

---@return table stats Statistics about BiS gear
function BiSTracker.DataManager.GetBiSStats()
    local bisData = BiSTracker.DataManager.GetCurrentPlayerBiSGear()
    if not bisData then
        return {
            total = 0,
            equipped = 0,
            missing = 0,
            upgradeable = 0,
        }
    end
    
    local stats = {
        total = #bisData,
        equipped = 0,
        missing = 0,
        upgradeable = 0,
    }
    
    for _, slotData in ipairs(bisData) do
        if slotData.equipped then
            stats.equipped = stats.equipped + 1
            if slotData.upgradeable then
                stats.upgradeable = stats.upgradeable + 1
            end
        else
            stats.missing = stats.missing + 1
        end
    end
    
    return stats
end

-- Export
_G.BiSTracker = BiSTracker