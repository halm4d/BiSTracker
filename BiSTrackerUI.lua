local BiSTracker = BiSTracker or {}

-- Main frame
local frame = CreateFrame("Frame", "BiSTrackerFrame", UIParent, "InsetFrameTemplate3")
frame:SetSize(450, 725)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetResizable(true)
frame:SetResizeBounds(300, 400, 800, 1000)

-- Resize grip
local resizeGrip = CreateFrame("Button", nil, frame)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
resizeGrip:EnableMouse(true)
resizeGrip:RegisterForDrag("LeftButton")

-- Set resize grip texture
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

-- Resize functionality
resizeGrip:SetScript("OnDragStart", function()
    frame:StartSizing("BOTTOMRIGHT")
end)

-- Scroll frame for BIS items
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -30)
scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 12)

local content = CreateFrame("Frame")
content:SetSize(380, 1)
scrollFrame:SetScrollChild(content)

resizeGrip:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    -- Update scroll frame size when resizing stops
    local width, height = frame:GetSize()
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 12)
    content:SetSize(width - 50, content:GetHeight())
end)

-- Create title bar for InsetFrameTemplate3
local titleFrame = CreateFrame("Frame", nil, frame)
titleFrame:SetSize(450, 25)
titleFrame:SetPoint("TOP", frame, "TOP", 0, 0)

-- Set title
frame.title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
frame.title:SetPoint("CENTER", titleFrame, "CENTER", 0, 0)
frame.title:SetText("BiS Tracker")
frame.title:SetTextColor(1, 0.8, 0, 1) -- Golden color

-- Create close button
local closeButton = CreateFrame("Button", nil, titleFrame, "UIPanelCloseButton")
closeButton:SetSize(24, 24)
closeButton:SetPoint("TOPRIGHT", titleFrame, "TOPRIGHT", -3, -1)
closeButton:SetScript("OnClick", function()
    frame:Hide()
end)

-- Toggle state for showing all items or only non-equipped
local showAllItems = true

-- Hide frame by default
-- frame:Show()
frame:Hide()

-- Function to update content width when frame is resized
local function UpdateContentSize()
    local frameWidth = frame:GetWidth()
    content:SetSize(frameWidth - 50, content:GetHeight())
end

-- Add resize handler to frame
frame:SetScript("OnSizeChanged", function(self, width, height)
    -- Update title frame width
    titleFrame:SetWidth(width)

    -- Update content size
    UpdateContentSize()

    -- Refresh the display to adjust item frames
    PopulateBISItems()
end)

-- Function to check if item is equipped
local function IsItemEquipped(itemData)
    return itemData.equipped or 
           itemData.BiSItems.overall.equipped or 
           itemData.BiSItems.raid.equipped or 
           itemData.BiSItems.mythic_plus.equipped
end

-- Function to create BIS item display
local function CreateBISItemFrame(parent, itemData, yOffset)
    local parentWidth = parent:GetWidth()
    local itemFrame = CreateFrame("Frame", nil, parent)
    itemFrame:SetSize(parentWidth - 10, 70) -- Dynamic width based on parent
    itemFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, yOffset)

    local bg = itemFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(itemFrame)
    bg:SetColorTexture(0, 0, 0, 0.1)

    -- Slot name
    local slotText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    slotText:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 5, -10)
    slotText:SetText(itemData.Slot .. ":")
    slotText:SetWidth(120)
    slotText:SetJustifyH("LEFT")

    -- Item name (clickable)
    local itemText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemText:SetPoint("LEFT", slotText, "RIGHT", 5, 0)
    itemText:SetText(itemData.BiSItems.overall.name)
    itemText:SetWidth(parentWidth - 150)
    itemText:SetJustifyH("LEFT")

    if itemData.equipped then
        itemText:SetTextColor(0, 1, 0) -- Green if equipped
    elseif itemData.upgradeable then
        itemText:SetTextColor(1, 0.5, 0) -- Orange if upgradeable
    else
        itemText:SetTextColor(1, 1, 1) -- White if not equipped
    end

    -- Source overall - dynamic width
    local overallSourceText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    overallSourceText:SetPoint("TOPLEFT", itemText, "BOTTOMLEFT", 15, -3)
    overallSourceText:SetText("Overall: " .. itemData.BiSItems.overall.source)
    overallSourceText:SetWidth(parentWidth - 20)
    overallSourceText:SetJustifyH("LEFT")
    if itemData.BiSItems.overall.equipped then
        overallSourceText:SetTextColor(0, 1, 0) -- Green if equipped
    else
        overallSourceText:SetTextColor(0.7, 0.7, 0.7) -- Gray if not equipped
    end

    -- Source raid - dynamic width
    local raidSourceText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    raidSourceText:SetPoint("TOPLEFT", overallSourceText, "BOTTOMLEFT", 0, -2)
    raidSourceText:SetText("Raid: " .. itemData.BiSItems.raid.source)
    raidSourceText:SetWidth(parentWidth - 20)
    raidSourceText:SetJustifyH("LEFT")
    if itemData.BiSItems.raid.equipped then
        raidSourceText:SetTextColor(0, 1, 0) -- Green if equipped
    else
        raidSourceText:SetTextColor(0.7, 0.7, 0.7) -- Gray if not equipped
    end

    -- Source mythic_plus - dynamic width
    local mythicPlusSourceText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mythicPlusSourceText:SetPoint("TOPLEFT", raidSourceText, "BOTTOMLEFT", 0, -2)
    mythicPlusSourceText:SetText("M+: " .. itemData.BiSItems.mythic_plus.source)
    mythicPlusSourceText:SetWidth(parentWidth - 20)
    mythicPlusSourceText:SetJustifyH("LEFT")
    if itemData.BiSItems.mythic_plus.equipped then
        mythicPlusSourceText:SetTextColor(0, 1, 0) -- Green if equipped
    else
        mythicPlusSourceText:SetTextColor(0.7, 0.7, 0.7) -- Gray if not equipped
    end

    -- Item frame clickable
    -- itemFrame:EnableMouse(true)
    -- itemFrame:SetScript("OnMouseUp", function()
    --     print("Clicked on: " .. itemData.BiSItems.overall.name)
    -- end)

    -- Hover effect
    itemFrame:SetScript("OnEnter", function()
        bg:SetColorTexture(1, 1, 1, 0.1)
    end)

    itemFrame:SetScript("OnLeave", function()
        bg:SetColorTexture(0, 0, 0, 0.1)
    end)

    return itemFrame
end

-- Function to populate BIS items for current class
function PopulateBISItems()
    -- Clear existing items
    for i, child in ipairs({content:GetChildren()}) do
        child:Hide()
    end

    local playerClass = GetCurrentPlayerClassAndSpec()
    local classData = GetCurrentPlayerBiSGear()

    if not classData then
        -- Create "No data" message
        -- local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        -- noDataText:SetPoint("TOP", content, "TOP", 0, -10)
        -- noDataText:SetText("No BIS data available for " .. (playerClass or "Unknown"))
        -- noDataText:SetTextColor(1, 0, 0) -- Red text
        return
    end

    -- Update content size
    UpdateContentSize()

    -- Class header
    local playerClassName = UnitClass("player")
    local _, name = GetSpecializationInfo(GetSpecialization())
    local classHeader = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    classHeader:SetPoint("TOP", content, "TOP", 0, -10)
    classHeader:SetText("Best-in-slot for " .. playerClassName .. " - " .. (name or "No Spec"))
    classHeader:SetTextColor(1, 1, 0) -- Yellow text

    local checkboxFrame = CreateFrame("Frame", nil, content)
    checkboxFrame:SetSize(content:GetWidth() - 10, 25)
    checkboxFrame:SetPoint("TOP", classHeader, "BOTTOM", 0, -5)

    local checkbox = CreateFrame("CheckButton", nil, checkboxFrame, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetSize(24, 24)
    checkbox:SetPoint("LEFT", checkboxFrame, "LEFT", 10, 0)
    checkbox:SetChecked(showAllItems)

    local checkboxLabel = checkboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkboxLabel:SetText("Show All Items")
    checkboxLabel:SetTextColor(1, 1, 1) -- White text

    checkboxFrame:EnableMouse(true)
    checkboxFrame:SetScript("OnMouseUp", function()
        checkbox:Click()
    end)

    checkbox:SetScript("OnClick", function(self)
        showAllItems = self:GetChecked()
        PopulateBISItems() -- Refresh the display
    end)

    -- Test alert button under the checkbox
    local testButtonFrame = CreateFrame("Frame", nil, content)
    testButtonFrame:SetSize(content:GetWidth() - 10, 30)
    testButtonFrame:SetPoint("TOP", checkboxFrame, "BOTTOM", 0, -5)

    local testButton = CreateFrame("Button", nil, testButtonFrame, "UIPanelButtonTemplate")
    testButton:SetSize(120, 25)
    testButton:SetPoint("CENTER", testButtonFrame, "CENTER", 0, 0)
    testButton:SetText("Test Alert")

    testButton:SetScript("OnClick", function()
        SendAlert(Colorize("BiS item dropped!", "00FF00"))
    end)

    -- Filtered items based on checkbox state
    local filteredData = {}
    for i, itemData in ipairs(classData) do
        if showAllItems or not IsItemEquipped(itemData) then
            table.insert(filteredData, itemData)
        end
    end

    local yOffset = -100
    for i, itemData in ipairs(filteredData) do
        CreateBISItemFrame(content, itemData, yOffset)
        yOffset = yOffset - 75
    end

    -- Set content height based on number of items
    content:SetHeight(math.abs(yOffset) + 20)
end

-- Function to toggle frame visibility
function BiSTracker:ToggleFrame()
    if frame:IsShown() then
        frame:Hide()
    else
        PopulateBISItems()
        frame:Show()
    end
end

-- Create slash command
SLASH_BISTRACKER1 = "/bistracker"
SlashCmdList["BISTRACKER"] = function(msg)
    BiSTracker:ToggleFrame()
end

-- Minimap button (optional)
MinimapButton = CreateFrame("Button", "BiSTrackerMinimapButton", Minimap)
MinimapButton:SetSize(32, 32)
MinimapButton:SetFrameStrata("MEDIUM")
MinimapButton:SetFrameLevel(8)
MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -15, 15)
MinimapButton:SetMovable(true)
MinimapButton:EnableMouse(true)
MinimapButton:RegisterForDrag("LeftButton")

-- Minimap button texture
local texture = MinimapButton:CreateTexture(nil, "BACKGROUND")
texture:SetSize(24, 24)
texture:SetPoint("CENTER")
texture:SetTexture("Interface\\Icons\\INV_Jewelry_Ring_Ahnqiraj_02") -- Epic ring icon

-- Add a border/highlight effect
-- local border = MinimapButton:CreateTexture(nil, "BORDER")
-- border:SetSize(48, 48)
-- border:SetPoint("CENTER", texture, "CENTER", 0, 0)
-- border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- Minimap button functionality
MinimapButton:SetScript("OnClick", function()
    BiSTracker:ToggleFrame()
end)

MinimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(MinimapButton, "ANCHOR_LEFT")
    GameTooltip:SetText("|cFFFFD700BiS Tracker|r") -- Gold colored title
    GameTooltip:AddLine("Click to open BiS items window", 1, 1, 1) -- White text
    GameTooltip:AddLine(" ", 1, 1, 1) -- Empty line
    GameTooltip:AddLine("|cFF00FF00Left-click:|r Toggle window", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cFF00FF00Drag:|r Move button", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)

MinimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Drag functionality for the minimap button
MinimapButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

MinimapButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- Initialize
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "BiSTracker" then
        print("BiS Tracker loaded! Use /bistracker to open the window.")
    elseif event == "PLAYER_LOGIN" then
        PopulateBISItems()
    end
end)

-- Export for global access
_G.BiSTracker = BiSTracker