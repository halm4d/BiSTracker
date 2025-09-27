-- Modern UI for BiS Tracker
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- Modern UI Manager
BiSTracker.ModernUI = {}

-- Helper function to check if all required modules are loaded
local function AreRequiredModulesLoaded()
    return BiSTracker and
        BiSTracker.Utils and
        BiSTracker.Settings and
        BiSTracker.DataManager
end

-- UI state
local mainFrame = nil
local currentTab = "bisitems"
local currentSubTab = "overall"
local currentDungeonFilter = "all" -- New: current dungeon filter
local initialized = false

-- Current TWW Season 1 Mythic+ Dungeons
local MYTHIC_PLUS_DUNGEONS = {
    "all",
    "Ara-Kara, City of Echoes",
    "Dawnbreaker", 
    "Priory of the Sacred Flame",
    "Eco-Dome Al'dani",
    "Halls of Atonement",
    "Operation: Floodgate",
    "Tazavesh: So'leah's Gambit",
    "Tazavesh: Streets of Wonder"
}

-- Constants for modern UI
local MODERN_UI = {
    MAIN_WIDTH = 650,
    MAIN_HEIGHT = 550,
    MIN_WIDTH = 500,
    MIN_HEIGHT = 400,
    MAX_WIDTH = 1000,
    MAX_HEIGHT = 800,
    TAB_HEIGHT = 35,
    SUBTAB_HEIGHT = 28,
    CONTENT_PADDING = 15,
    ITEM_HEIGHT = 70,
    SCROLLBAR_WIDTH = 18,
}

-- Color scheme for modern UI
local COLORS = {
    BACKGROUND = { 0.1, 0.1, 0.1, 0.95 },
    HEADER = { 0.15, 0.15, 0.15, 1 },
    TAB_ACTIVE = { 0.2, 0.4, 0.8, 1 },
    TAB_INACTIVE = { 0.25, 0.25, 0.25, 1 },
    TAB_HOVER = { 0.35, 0.35, 0.35, 1 },
    BORDER = { 0.4, 0.4, 0.4, 1 },
    TEXT_LIGHT = { 1, 1, 1, 1 },
    TEXT_GOLD = { 1, 0.82, 0, 1 },
    TEXT_GREEN = { 0, 1, 0, 1 },
    TEXT_RED = { 1, 0.2, 0.2, 1 },
    TEXT_ORANGE = { 1, 0.6, 0, 1 },
    TEXT_GRAY = { 0.7, 0.7, 0.7, 1 },
    ITEM_BG = { 0.2, 0.2, 0.2, 0.8 },
    ITEM_BG_HOVER = { 0.3, 0.3, 0.3, 0.8 },
}

-- Utility functions
local function CreateStandardBackdrop(withBorder)
    local backdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true,
        tileSize = 16,
    }
    if withBorder then
        backdrop.edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"
        backdrop.edgeSize = 8
        backdrop.insets = { left = 2, right = 2, top = 2, bottom = 2 }
    end
    return backdrop
end

local function HandleItemClick(itemID)
    if not itemID then return end
    local itemLink = select(2, C_Item.GetItemInfo(itemID))
    if itemLink and ChatEdit_GetActiveWindow() then
        ChatEdit_InsertLink(itemLink)
    elseif itemLink then
        print("Item Link: " .. itemLink)
    end
end

local function ShowItemTooltipSafely(itemID, frame)
    if itemID and BiSTracker.Utils and BiSTracker.Utils.ShowItemTooltip then
        BiSTracker.Utils.ShowItemTooltip(itemID, frame)
    end
end

local function HideItemTooltipSafely()
    if BiSTracker.Utils and BiSTracker.Utils.HideItemTooltip then
        BiSTracker.Utils.HideItemTooltip()
    end
end

local function CreateButtonWithMouseEvents(parent, template)
    local button = CreateFrame("Button", nil, parent, template)
    button:EnableMouse(true)
    button:SetFrameLevel(parent:GetFrameLevel() + 1)
    return button
end

-- Clean up keyboard handling utility
local function CleanupKeyboardHandling(frame)
    frame:EnableKeyboard(false)
    frame:SetPropagateKeyboardInput(false)
end

-- Initialize Modern UI
function BiSTracker.ModernUI.Initialize()
    if initialized then
        return
    end

    -- Safety checks
    if not AreRequiredModulesLoaded() then
        print("BiS Tracker: Core modules not loaded, ModernUI initialization delayed")
        -- Try again in a moment
        C_Timer.After(1, BiSTracker.ModernUI.Initialize)
        return
    end

    BiSTracker.ModernUI.CreateMainFrame()
    initialized = true
    BiSTracker.Utils.PrintDebug("Modern UI initialized")
end

-- Main Frame Creation
function BiSTracker.ModernUI.CreateMainFrame()
    if mainFrame then
        return mainFrame
    end

    -- Create main frame
    mainFrame = CreateFrame("Frame", "BiSTrackerModernFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(MODERN_UI.MAIN_WIDTH, MODERN_UI.MAIN_HEIGHT)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetClampedToScreen(true)

    -- Set backdrop
    local backdrop = CreateStandardBackdrop(true)
    backdrop.edgeSize = 16
    backdrop.insets = { left = 4, right = 4, top = 4, bottom = 4 }
    mainFrame:SetBackdrop(backdrop)
    mainFrame:SetBackdropColor(unpack(COLORS.BACKGROUND))
    mainFrame:SetBackdropBorderColor(unpack(COLORS.BORDER))

    -- Drag functionality
    mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Set resizable
    mainFrame:SetResizable(true)
    mainFrame:SetResizeBounds(MODERN_UI.MIN_WIDTH, MODERN_UI.MIN_HEIGHT, MODERN_UI.MAX_WIDTH, MODERN_UI.MAX_HEIGHT)

    -- Hide by default
    mainFrame:Hide()

    -- Set proper frame strata to ensure UI elements work correctly
    mainFrame:SetFrameStrata("DIALOG")

    -- Clean up keyboard handling when frame is hidden
    mainFrame:SetScript("OnHide", function(self)
        CleanupKeyboardHandling(self)
    end)

    -- Create UI elements
    BiSTracker.ModernUI.CreateHeader()
    BiSTracker.ModernUI.CreateTabs()
    BiSTracker.ModernUI.CreateContentArea()
    BiSTracker.ModernUI.CreateResizeGrip()

    -- Note: Content will be loaded when frame is first shown

    return mainFrame
end

-- Header with title and close button
function BiSTracker.ModernUI.CreateHeader()
    if not mainFrame then return end

    local header = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    header:SetSize(mainFrame:GetWidth(), 40)
    header:SetPoint("TOP", mainFrame, "TOP", 0, -8)
    header:SetBackdrop(CreateStandardBackdrop(false))
    header:SetBackdropColor(unpack(COLORS.HEADER))

    -- Title
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("LEFT", header, "LEFT", 15, 0)
    title:SetText("BiS Tracker")
    title:SetTextColor(unpack(COLORS.TEXT_GOLD))

    -- Class/Spec info - show loot specialization
    local playerClassName = UnitClass("player")
    local specName = BiSTracker.Utils.GetLootSpecDisplayName() or "No Spec"

    local classSpecText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classSpecText:SetPoint("LEFT", title, "RIGHT", 10, 0)
    classSpecText:SetText("(" .. (playerClassName or "Unknown") .. " - " .. specName .. ")")
    classSpecText:SetTextColor(unpack(COLORS.TEXT_GRAY))

    -- Close button
    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", header, "TOPRIGHT", -5, -8)
    closeBtn:SetScript("OnClick", function()
        if mainFrame then
            CleanupKeyboardHandling(mainFrame)
            mainFrame:Hide()
        end
    end)

    mainFrame.header = header
end

-- Tab system
function BiSTracker.ModernUI.CreateTabs()
    if not mainFrame or not mainFrame.header then return end

    local tabFrame = CreateFrame("Frame", nil, mainFrame)
    tabFrame:SetSize(mainFrame:GetWidth() - 20, MODERN_UI.TAB_HEIGHT)
    tabFrame:SetPoint("TOP", mainFrame.header, "BOTTOM", 0, -5)

    -- Tab definitions
    local tabs = {
        { key = "bisitems", text = "BiS Items", func = function() BiSTracker.ModernUI.ShowBiSItemsTab() end },
        { key = "settings", text = "Settings",  func = function() BiSTracker.ModernUI.ShowSettingsTab() end }
    }

    local tabButtons = {}
    local tabWidth = (tabFrame:GetWidth() - 10) / #tabs

    for i, tab in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, tabFrame, "BackdropTemplate")
        btn:SetSize(tabWidth, MODERN_UI.TAB_HEIGHT)
        btn:SetPoint("LEFT", tabFrame, "LEFT", (i - 1) * tabWidth + 5, 0)
        btn:SetBackdrop(CreateStandardBackdrop(true))

        -- Tab text
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText(tab.text)

        -- Ensure button can receive mouse events
        btn:EnableMouse(true)
        btn:SetFrameLevel(tabFrame:GetFrameLevel() + 1)

        -- Tab functionality
        btn:SetScript("OnClick", function()
            currentTab = tab.key
            BiSTracker.ModernUI.UpdateTabAppearance()
            tab.func()
        end)

        btn:SetScript("OnEnter", function()
            if currentTab ~= tab.key then
                btn:SetBackdropColor(unpack(COLORS.TAB_HOVER))
            end
        end)

        btn:SetScript("OnLeave", function()
            BiSTracker.ModernUI.UpdateTabAppearance()
        end)

        btn.key = tab.key
        btn.text = text
        tabButtons[tab.key] = btn
    end

    mainFrame.tabFrame = tabFrame
    mainFrame.tabButtons = tabButtons

    -- Update initial appearance
    BiSTracker.ModernUI.UpdateTabAppearance()
end

-- Update tab visual appearance
function BiSTracker.ModernUI.UpdateTabAppearance()
    if not mainFrame or not mainFrame.tabButtons then return end

    for key, btn in pairs(mainFrame.tabButtons) do
        if key == currentTab then
            btn:SetBackdropColor(unpack(COLORS.TAB_ACTIVE))
            btn.text:SetTextColor(unpack(COLORS.TEXT_LIGHT))
        else
            btn:SetBackdropColor(unpack(COLORS.TAB_INACTIVE))
            btn.text:SetTextColor(unpack(COLORS.TEXT_GRAY))
        end
        btn:SetBackdropBorderColor(unpack(COLORS.BORDER))
    end
end

-- Create content area
function BiSTracker.ModernUI.CreateContentArea()
    if not mainFrame or not mainFrame.tabFrame then return end

    local content = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    content:SetPoint("TOPLEFT", mainFrame.tabFrame, "BOTTOMLEFT", 0, -5)
    content:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -10, 10)

    content:SetBackdrop(CreateStandardBackdrop(false))
    content:SetBackdropColor(0.05, 0.05, 0.05, 0.8)

    mainFrame.content = content
end

-- Show BiS Items tab
function BiSTracker.ModernUI.ShowBiSItemsTab()
    if not mainFrame or not mainFrame.content then return end

    -- Debug output
    if BiSTracker.Utils and BiSTracker.Utils.PrintDebug then
        BiSTracker.Utils.PrintDebug("ShowBiSItemsTab called")
    end

    -- Clear content
    BiSTracker.ModernUI.ClearContent()

    -- Create subtabs
    BiSTracker.ModernUI.CreateSubTabs()

    -- Show content based on current subtab
    BiSTracker.ModernUI.ShowBiSContent()
end

-- Create subtabs for BiS Items
function BiSTracker.ModernUI.CreateSubTabs()
    if not mainFrame or not mainFrame.content then return end

    local subTabFrame = CreateFrame("Frame", nil, mainFrame.content)
    subTabFrame:SetSize(mainFrame.content:GetWidth() - 20, MODERN_UI.SUBTAB_HEIGHT)
    subTabFrame:SetPoint("TOP", mainFrame.content, "TOP", 0, -10)

    local subTabs = {
        { key = "overall",     text = "Overall" },
        { key = "raid",        text = "Raid" },
        { key = "mythic_plus", text = "Mythic+" }
    }

    local subTabButtons = {}
    local subTabWidth = (subTabFrame:GetWidth() - 15) / #subTabs

    for i, subTab in ipairs(subTabs) do
        local btn = CreateFrame("Button", nil, subTabFrame, "BackdropTemplate")
        btn:SetSize(subTabWidth, MODERN_UI.SUBTAB_HEIGHT)
        btn:SetPoint("LEFT", subTabFrame, "LEFT", (i - 1) * subTabWidth + 5, 0)
        btn:SetBackdrop(CreateStandardBackdrop(false))

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER")
        text:SetText(subTab.text)

        -- Ensure button can receive mouse events
        btn:EnableMouse(true)
        btn:SetFrameLevel(subTabFrame:GetFrameLevel() + 1)

        btn:SetScript("OnClick", function()
            currentSubTab = subTab.key
            currentDungeonFilter = "all" -- Reset filter when switching subtabs
            BiSTracker.ModernUI.UpdateSubTabAppearance()
            BiSTracker.ModernUI.ShowBiSContent()
        end)

        btn:SetScript("OnEnter", function()
            if currentSubTab ~= subTab.key then
                btn:SetBackdropColor(unpack(COLORS.TAB_HOVER))
            end
        end)

        btn:SetScript("OnLeave", function()
            BiSTracker.ModernUI.UpdateSubTabAppearance()
        end)

        btn.key = subTab.key
        btn.text = text
        subTabButtons[subTab.key] = btn
    end

    mainFrame.subTabFrame = subTabFrame
    mainFrame.subTabButtons = subTabButtons

    BiSTracker.ModernUI.UpdateSubTabAppearance()
end

-- Update subtab appearance
function BiSTracker.ModernUI.UpdateSubTabAppearance()
    if not mainFrame or not mainFrame.subTabButtons then return end

    for key, btn in pairs(mainFrame.subTabButtons) do
        if key == currentSubTab then
            btn:SetBackdropColor(unpack(COLORS.TAB_ACTIVE))
            btn.text:SetTextColor(unpack(COLORS.TEXT_LIGHT))
        else
            btn:SetBackdropColor(unpack(COLORS.TAB_INACTIVE))
            btn.text:SetTextColor(unpack(COLORS.TEXT_GRAY))
        end
    end
end

-- Create dungeon filter dropdown for Mythic+ tab
function BiSTracker.ModernUI.CreateDungeonFilter()
    if not mainFrame or not mainFrame.content or not mainFrame.subTabFrame then return end
    
    -- Remove existing filter if it exists
    if mainFrame.dungeonFilter then
        mainFrame.dungeonFilter:Hide()
        mainFrame.dungeonFilter = nil
    end
    
    -- Create filter frame
    local filterFrame = CreateFrame("Frame", nil, mainFrame.content)
    filterFrame:SetSize(mainFrame.content:GetWidth() - 40, 35)
    filterFrame:SetPoint("TOPLEFT", mainFrame.subTabFrame, "BOTTOMLEFT", 20, -10)
    
    -- Filter label
    local label = filterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", filterFrame, "LEFT", 10, 0)
    label:SetText("Dungeon: ")
    label:SetTextColor(unpack(COLORS.TEXT_GOLD))
    
    -- Create dropdown button
    local dropdown = CreateFrame("Button", nil, filterFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", label, "RIGHT", 10, 0)
    
    -- Initialize dropdown
    UIDropDownMenu_SetWidth(dropdown, 180)
    UIDropDownMenu_SetText(dropdown, currentDungeonFilter == "all" and "All Dungeons" or currentDungeonFilter)
    
    -- Dropdown menu function
    local function DropdownMenu_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        for _, dungeon in ipairs(MYTHIC_PLUS_DUNGEONS) do
            info.text = dungeon == "all" and "All Dungeons" or dungeon
            info.value = dungeon
            info.func = function()
                currentDungeonFilter = dungeon
                UIDropDownMenu_SetText(dropdown, dungeon == "all" and "All Dungeons" or dungeon)
                CloseDropDownMenus()
                BiSTracker.ModernUI.ShowBiSContent() -- Reload with new filter
            end
            info.checked = (currentDungeonFilter == dungeon)
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, DropdownMenu_Initialize)
    
    mainFrame.dungeonFilter = filterFrame
end

-- Show BiS content based on current subtab
function BiSTracker.ModernUI.ShowBiSContent()
    if not mainFrame or not mainFrame.content or not mainFrame.subTabFrame then return end

    -- Create dungeon filter for Mythic+ tab
    if currentSubTab == "mythic_plus" then
        BiSTracker.ModernUI.CreateDungeonFilter()
    elseif mainFrame.dungeonFilter then
        -- Hide filter if not on mythic+ tab
        mainFrame.dungeonFilter:Hide()
    end

    -- Clear existing scroll frame if it exists
    if mainFrame.scrollFrame then
        mainFrame.scrollFrame:Hide()
        mainFrame.scrollFrame:SetParent(nil)
        mainFrame.scrollFrame = nil
    end

    -- Show loading message temporarily
    local loadingFrame = CreateFrame("Frame", nil, mainFrame.content)
    loadingFrame:SetAllPoints(mainFrame.content)
    local loadingText = loadingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    loadingText:SetPoint("CENTER", loadingFrame, "CENTER", 0, 0)
    loadingText:SetText("Loading BiS data...")
    loadingText:SetTextColor(unpack(COLORS.TEXT_GRAY))

    -- Use a small delay to allow the loading text to show
    C_Timer.After(0.1, function()
        loadingFrame:Hide()
        loadingFrame:SetParent(nil)

        local bisData = BiSTracker.DataManager and BiSTracker.DataManager.GetCurrentPlayerBiSGear and
        BiSTracker.DataManager.GetCurrentPlayerBiSGear()
        if not bisData or #bisData == 0 then
            BiSTracker.ModernUI.ShowNoDataMessage()
            return
        end

        -- Create scroll frame for items
        local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame.content, "UIPanelScrollFrameTemplate")
        
        -- Position scroll frame based on whether dungeon filter exists
        if currentSubTab == "mythic_plus" and mainFrame.dungeonFilter then
            scrollFrame:SetPoint("TOPLEFT", mainFrame.dungeonFilter, "BOTTOMLEFT", 0, -10)
        else
            scrollFrame:SetPoint("TOPLEFT", mainFrame.subTabFrame, "BOTTOMLEFT", 0, -10)
        end
        scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame.content, "BOTTOMRIGHT", -25, 10)


        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(scrollFrame:GetWidth() - MODERN_UI.SCROLLBAR_WIDTH, 1)
        scrollFrame:SetScrollChild(scrollChild)

        -- Populate items
        local yOffset = -10
        local itemCount = 0
        for _, slotData in ipairs(bisData) do
            local itemDataList = BiSTracker.ModernUI.GetRelevantItemData(slotData, currentSubTab)
            if itemDataList then
                -- Handle both single items and arrays of items
                local itemsToProcess = itemDataList
                if not itemDataList[1] and itemDataList.itemID then
                    -- Single item, convert to array
                    itemsToProcess = {itemDataList}
                end
                
                -- Process each item
                for _, itemData in ipairs(itemsToProcess) do
                    if itemData and itemData.itemID then
                        BiSTracker.ModernUI.CreateModernItemFrame(scrollChild, slotData, itemData, yOffset)
                        yOffset = yOffset - MODERN_UI.ITEM_HEIGHT - 10
                        itemCount = itemCount + 1
                    end
                end
            end
        end

        -- If no items for this category, show message
        if itemCount == 0 then
            local noItemsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noItemsText:SetPoint("TOP", scrollChild, "TOP", 0, -50)
            
            local messageText = "No items available for " .. 
                (currentSubTab == "mythic_plus" and "Mythic+" or (currentSubTab:gsub("^%l", string.upper)))
                
            if currentSubTab == "mythic_plus" and currentDungeonFilter ~= "all" then
                messageText = messageText .. " from " .. currentDungeonFilter
            end
            
            noItemsText:SetText(messageText)
            noItemsText:SetTextColor(unpack(COLORS.TEXT_GRAY))
        end

        scrollChild:SetHeight(math.max(math.abs(yOffset) + 20, 100))
        mainFrame.scrollFrame = scrollFrame
    end)
end

-- Get relevant item data based on subtab

function BiSTracker.ModernUI.GetRelevantItemData(slotData, subTab)
    if not slotData or not slotData.BiSItems then return nil end

    local items
    if subTab == "overall" then
        items = slotData.BiSItems.overall
    elseif subTab == "raid" then
        items = slotData.BiSItems.raid
    elseif subTab == "mythic_plus" then
        items = slotData.BiSItems.mythic_plus
    end
    
    if not items then return nil end
    
    -- Apply dungeon filter for mythic_plus
    if subTab == "mythic_plus" and currentDungeonFilter ~= "all" then
        local filteredItems = {}
        -- Handle both single item and array cases
        local itemsToFilter = items
        if not items[1] and items.itemID then
            itemsToFilter = {items}
        end
        
        for _, item in ipairs(itemsToFilter) do
            if item.source and item.source:find(currentDungeonFilter, 1, true) then
                table.insert(filteredItems, item)
            end
        end
        return #filteredItems > 0 and filteredItems or nil
    end
    
    return items
end

-- Create modern item frame
function BiSTracker.ModernUI.CreateModernItemFrame(parent, slotData, itemData, yOffset)
    local itemFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    itemFrame:SetSize(parent:GetWidth() - 20, MODERN_UI.ITEM_HEIGHT)
    itemFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)

    itemFrame:SetBackdrop(CreateStandardBackdrop(true))
    itemFrame:SetBackdropColor(unpack(COLORS.ITEM_BG))
    itemFrame:SetBackdropBorderColor(unpack(COLORS.BORDER))

    -- Item icon
    local itemIcon = itemFrame:CreateTexture(nil, "ARTWORK")
    itemIcon:SetSize(32, 32)
    itemIcon:SetPoint("LEFT", itemFrame, "LEFT", 8, 0)
    
    -- Set the item icon if we have an itemID
    if itemData.itemID then
        local itemTexture = C_Item.GetItemIconByID(itemData.itemID)
        if itemTexture then
            itemIcon:SetTexture(itemTexture)
        else
            -- Fallback: use a default icon
            itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
    else
        itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- Make icon clickable and add border for better visibility
    local iconFrame = CreateFrame("Button", nil, itemFrame, "BackdropTemplate")
    iconFrame:SetPoint("LEFT", itemFrame, "LEFT", 8, 0)
    iconFrame:SetSize(32, 32)
    iconFrame:EnableMouse(true)
    iconFrame:SetFrameLevel(itemFrame:GetFrameLevel() + 1)
    
    -- Add backdrop border to icon
    iconFrame:SetBackdrop({
        bgFile = nil,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    iconFrame:SetBackdropBorderColor(0.8, 0.8, 0.8, 0.8)
    
    -- Icon click handler
    if itemData.itemID then
        iconFrame:SetScript("OnClick", function()
            HandleItemClick(itemData.itemID)
        end)
        
        iconFrame:SetScript("OnEnter", function()
            iconFrame:SetBackdropBorderColor(1, 1, 0, 1) -- Yellow border on hover
            ShowItemTooltipSafely(itemData.itemID, iconFrame)
        end)
        
        iconFrame:SetScript("OnLeave", function()
            iconFrame:SetBackdropBorderColor(0.8, 0.8, 0.8, 0.8) -- Normal border
            HideItemTooltipSafely()
        end)
    end

    -- Hover effect for main frame
    itemFrame:EnableMouse(true)
    itemFrame:SetScript("OnEnter", function()
        itemFrame:SetBackdropColor(unpack(COLORS.ITEM_BG_HOVER))
        ShowItemTooltipSafely(itemData.itemID, itemFrame)
    end)
    itemFrame:SetScript("OnLeave", function()
        itemFrame:SetBackdropColor(unpack(COLORS.ITEM_BG))
        HideItemTooltipSafely()
    end)

    -- Slot name
    local slotText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    slotText:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 48, -8) -- Moved right to make room for icon
    slotText:SetText(slotData.Slot)
    slotText:SetTextColor(unpack(COLORS.TEXT_GOLD))

    -- Item name (make it clickable)
    local itemText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemText:SetPoint("TOPLEFT", slotText, "BOTTOMLEFT", 0, -5)
    itemText:SetSize(itemFrame:GetWidth() - 120, 20)
    itemText:SetJustifyH("LEFT")
    itemText:SetText(itemData.name or "Unknown Item")

    -- Make item name clickable if we have an itemID
    if itemData.itemID then
        local itemButton = CreateFrame("Button", nil, itemFrame)
        itemButton:SetAllPoints(itemText)
        itemButton:EnableMouse(true)
        itemButton:SetFrameLevel(itemFrame:GetFrameLevel() + 2)

        itemButton:SetScript("OnClick", function()
            HandleItemClick(itemData.itemID)
        end)
        itemButton:SetScript("OnEnter", function()
            itemText:SetTextColor(1, 1, 0, 1) -- Yellow on hover
            ShowItemTooltipSafely(itemData.itemID, itemFrame)
        end)
        itemButton:SetScript("OnLeave", function()
            itemText:SetTextColor(1, 1, 1, 1) -- White normally
            HideItemTooltipSafely()
        end)
    end

    -- Status indicator
    local statusText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("TOPRIGHT", itemFrame, "TOPRIGHT", -12, -8)

    if itemData.equipped then
        if slotData.upgradeable then
            statusText:SetText("UPGRADEABLE")
            statusText:SetTextColor(unpack(COLORS.TEXT_ORANGE))
        else
            statusText:SetText("EQUIPPED")
            statusText:SetTextColor(unpack(COLORS.TEXT_GREEN))
        end
    else
        statusText:SetText("NOT EQUIPPED")
        statusText:SetTextColor(unpack(COLORS.TEXT_RED))
    end

    -- Source information
    local sourceText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceText:SetPoint("BOTTOMLEFT", itemFrame, "BOTTOMLEFT", 12, 8)
    sourceText:SetSize(itemFrame:GetWidth() - 24, 15)
    sourceText:SetJustifyH("LEFT")
    sourceText:SetText("Source: " .. (itemData.source or "Unknown"))
    sourceText:SetTextColor(unpack(COLORS.TEXT_GRAY))
end

-- Show Settings tab
function BiSTracker.ModernUI.ShowSettingsTab()
    if not mainFrame or not mainFrame.content then return end

    -- Clear content
    BiSTracker.ModernUI.ClearContent()

    -- Create settings content
    BiSTracker.ModernUI.CreateSettingsContent()
end

-- Create settings content
function BiSTracker.ModernUI.CreateSettingsContent()
    if not mainFrame or not mainFrame.content then return end

    local settingsFrame = CreateFrame("Frame", nil, mainFrame.content)
    settingsFrame:SetPoint("TOPLEFT", mainFrame.content, "TOPLEFT", MODERN_UI.CONTENT_PADDING, -MODERN_UI.CONTENT_PADDING)
    settingsFrame:SetPoint("BOTTOMRIGHT", mainFrame.content, "BOTTOMRIGHT", -MODERN_UI.CONTENT_PADDING, MODERN_UI.CONTENT_PADDING)

    -- Settings title
    local title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 0, -10)
    title:SetText("Settings")
    title:SetTextColor(unpack(COLORS.TEXT_GOLD))

    local yOffset = -50

    -- Test Alert Button
    local testButton = CreateButtonWithMouseEvents(settingsFrame, "UIPanelButtonTemplate")
    testButton:SetSize(140, 30)
    testButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, yOffset)
    testButton:SetText("Test Alert")
    testButton:SetScript("OnClick", function()
        if BiSTracker.Alerts and BiSTracker.Alerts.SendTestAlert then
            BiSTracker.Alerts.SendTestAlert()
        else
            print("BiS Tracker: Alert system not available")
        end
    end)
    yOffset = yOffset - 50

    -- Settings checkboxes
    local settings = {
        { key = "enableAlerts", text = "Enable BiS item alerts",    getter = "IsAlertsEnabled" },
        { key = "showAllItems", text = "Show all items by default", getter = "ShouldShowAllItems" },
        { key = "showMinimap",  text = "Show minimap button",       getter = "ShouldShowMinimap" },
        { key = "debugMode",    text = "Enable debug mode",         getter = "IsDebugMode" }
    }

    for _, setting in ipairs(settings) do
        local checkbox = BiSTracker.ModernUI.CreateModernCheckbox(settingsFrame, title, yOffset, setting.text,
            setting.key, setting.getter)
        yOffset = yOffset - 35
    end

    yOffset = yOffset - 20

    -- Reset button
    local resetButton = CreateButtonWithMouseEvents(settingsFrame, "UIPanelButtonTemplate")
    resetButton:SetSize(120, 30)
    resetButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, yOffset)
    resetButton:SetText("Reset All")
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("BISTRACKER_MODERN_RESET_CONFIRM")
    end)

    -- Create reset confirmation popup
    if not StaticPopupDialogs["BISTRACKER_MODERN_RESET_CONFIRM"] then
        StaticPopupDialogs["BISTRACKER_MODERN_RESET_CONFIRM"] = {
            text = "Are you sure you want to reset all BiS Tracker settings to defaults?",
            button1 = "Reset",
            button2 = "Cancel",
            OnAccept = function()
                if BiSTracker.Settings and BiSTracker.Settings.Reset then
                    BiSTracker.Settings.Reset()
                    BiSTracker.ModernUI.RefreshContent()
                else
                    print("BiS Tracker: Settings reset not available")
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
end

-- Create modern checkbox
function BiSTracker.ModernUI.CreateModernCheckbox(parent, anchor, yOffset, text, settingKey, getterFunc)
    local checkboxFrame = CreateFrame("Frame", nil, parent)
    checkboxFrame:SetSize(parent:GetWidth(), 25)
    checkboxFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset)

    local checkbox = CreateButtonWithMouseEvents(checkboxFrame, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetSize(24, 24)
    checkbox:SetPoint("LEFT", checkboxFrame, "LEFT", 0, 0)

    -- Safety check for Settings module
    local isChecked = false
    if BiSTracker.Settings and BiSTracker.Settings[getterFunc] then
        isChecked = BiSTracker.Settings[getterFunc]()
    end
    checkbox:SetChecked(isChecked)

    local label = checkboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(text)
    label:SetTextColor(unpack(COLORS.TEXT_LIGHT))

    checkbox:SetScript("OnClick", function(self)
        if BiSTracker.Settings and BiSTracker.Settings.Set then
            BiSTracker.Settings.Set(settingKey, self:GetChecked())
            -- Special handling for minimap button
            if settingKey == "showMinimap" and BiSTracker.UI and BiSTracker.UI.UpdateMinimapButtonVisibility then
                BiSTracker.UI.UpdateMinimapButtonVisibility()
            end
        end
    end)

    return checkbox
end

-- Show no data message
function BiSTracker.ModernUI.ShowNoDataMessage()
    if not mainFrame or not mainFrame.content then return end

    local noDataFrame = CreateFrame("Frame", nil, mainFrame.content)
    noDataFrame:SetAllPoints(mainFrame.content)

    local noDataText = noDataFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    noDataText:SetPoint("CENTER", noDataFrame, "CENTER", 0, 20)
    noDataText:SetText("No BiS data available")
    noDataText:SetTextColor(unpack(COLORS.TEXT_RED))

    -- Add more helpful subtitle showing loot specialization
    local playerClassName = UnitClass("player")
    local specName = BiSTracker.Utils and BiSTracker.Utils.GetLootSpecDisplayName and
    BiSTracker.Utils.GetLootSpecDisplayName() or "No Specialization"

    local subtitleText = noDataFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitleText:SetPoint("TOP", noDataText, "BOTTOM", 0, -10)
    subtitleText:SetText("For: " .. (playerClassName or "Unknown Class") .. " - " .. specName)
    subtitleText:SetTextColor(unpack(COLORS.TEXT_GRAY))

    -- Add instruction text
    local instructionText = noDataFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructionText:SetPoint("TOP", subtitleText, "BOTTOM", 0, -20)
    instructionText:SetText("Make sure your loot specialization is set correctly and the addon data is up to date.")
    instructionText:SetTextColor(unpack(COLORS.TEXT_GRAY))
end

-- Clear content
function BiSTracker.ModernUI.ClearContent()
    if not mainFrame or not mainFrame.content then return end

    -- Clear existing children
    local children = { mainFrame.content:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Clear references
    if mainFrame then
        mainFrame.subTabFrame = nil
        mainFrame.subTabButtons = nil
        mainFrame.scrollFrame = nil
    end
end

-- Resize grip
function BiSTracker.ModernUI.CreateResizeGrip()
    local resizeGrip = CreateFrame("Button", nil, mainFrame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
    resizeGrip:EnableMouse(true)
    resizeGrip:RegisterForDrag("LeftButton")
    if mainFrame then
        resizeGrip:SetFrameLevel(mainFrame:GetFrameLevel() + 10) -- Ensure it's above other elements
    end

    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeGrip:SetScript("OnDragStart", function()
        if mainFrame then
            mainFrame:StartSizing("BOTTOMRIGHT")
        end
    end)

    resizeGrip:SetScript("OnDragStop", function()
        if mainFrame then
            mainFrame:StopMovingOrSizing()
            BiSTracker.ModernUI.OnFrameResized()
        end
    end)

    if mainFrame then
        mainFrame:SetScript("OnSizeChanged", BiSTracker.ModernUI.OnFrameResized)
    end
end

-- Handle frame resizing
function BiSTracker.ModernUI.OnFrameResized()
    if not mainFrame then return end

    -- Update header width
    if mainFrame.header then
        mainFrame.header:SetWidth(mainFrame:GetWidth())
    end

    -- Update tab frame width
    if mainFrame.tabFrame then
        mainFrame.tabFrame:SetWidth(mainFrame:GetWidth() - 20)
        -- Recalculate tab widths
        if mainFrame.tabButtons then
            local tabCount = 0
            for _ in pairs(mainFrame.tabButtons) do tabCount = tabCount + 1 end
            local tabWidth = (mainFrame.tabFrame:GetWidth() - 10) / tabCount
            local i = 0
            for _, btn in pairs(mainFrame.tabButtons) do
                btn:SetSize(tabWidth, MODERN_UI.TAB_HEIGHT)
                btn:SetPoint("LEFT", mainFrame.tabFrame, "LEFT", i * tabWidth + 5, 0)
                i = i + 1
            end
        end
    end

    -- Refresh content if needed
    if mainFrame:IsShown() then
        BiSTracker.ModernUI.RefreshContent()
    end
end

-- Toggle main frame visibility
function BiSTracker.ModernUI.ToggleMainFrame()
    if not mainFrame then
        BiSTracker.ModernUI.CreateMainFrame()
    end

    if not mainFrame then return end

    if mainFrame:IsShown() then
        CleanupKeyboardHandling(mainFrame)
        mainFrame:Hide()
    else
        mainFrame:Show()

        -- Refresh content after showing the frame
        BiSTracker.ModernUI.RefreshContent()

        -- Set up escape key handling when window is shown
        mainFrame:EnableKeyboard(true)
        mainFrame:SetPropagateKeyboardInput(true)
        mainFrame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:Hide()
                return
            end
            self:SetPropagateKeyboardInput(true)
        end)
    end
end

-- Refresh current content
function BiSTracker.ModernUI.RefreshContent()
    if not mainFrame then return end

    -- Debug output
    if BiSTracker.Utils and BiSTracker.Utils.PrintDebug then
        BiSTracker.Utils.PrintDebug("RefreshContent called, currentTab: " .. currentTab)
    end

    if currentTab == "bisitems" then
        BiSTracker.ModernUI.ShowBiSItemsTab()
    elseif currentTab == "settings" then
        BiSTracker.ModernUI.ShowSettingsTab()
    end
end

-- Export
_G.BiSTracker = BiSTracker
