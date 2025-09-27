-- Main UI module for BiS Tracker
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- UI Manager
BiSTracker.UI = {}

-- UI state
local mainFrame = nil
local minimapButton = nil
local initialized = false

-- Initialize UI components
function BiSTracker.UI.Initialize()
    if initialized then
        return
    end

    BiSTracker.UI.CreateMainFrame()
    BiSTracker.UI.CreateMinimapButton()
    BiSTracker.UI.UpdateMinimapButtonVisibility()

    initialized = true
    BiSTracker.Utils.PrintDebug("UI initialized")
end

-- Main Frame Management

function BiSTracker.UI.CreateMainFrame()
    if mainFrame then
        return mainFrame
    end

    mainFrame = CreateFrame("Frame", "BiSTrackerMainFrame", UIParent, "InsetFrameTemplate3")
    mainFrame:SetSize(BiSTracker.Constants.UI.MAIN_FRAME_WIDTH, BiSTracker.Constants.UI.MAIN_FRAME_HEIGHT)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetResizable(true)
    mainFrame:SetResizeBounds(
        BiSTracker.Constants.UI.MIN_FRAME_WIDTH,
        BiSTracker.Constants.UI.MIN_FRAME_HEIGHT,
        BiSTracker.Constants.UI.MAX_FRAME_WIDTH,
        BiSTracker.Constants.UI.MAX_FRAME_HEIGHT
    )
    mainFrame:Hide() -- Hidden by default

    BiSTracker.UI.SetupMainFrameElements()

    return mainFrame
end

function BiSTracker.UI.SetupMainFrameElements()
    -- Title
    local titleFrame = CreateFrame("Frame", nil, mainFrame)
    if mainFrame then
        titleFrame:SetSize(mainFrame:GetWidth(), 25)
    end
    titleFrame:SetPoint("TOP", mainFrame, "TOP", 0, 0)

    local title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("CENTER", titleFrame, "CENTER", 0, 0)
    title:SetText("BiS Tracker")
    title:SetTextColor(1, 0.8, 0, 1) -- Gold

    -- Close button
    local closeButton = CreateFrame("Button", nil, titleFrame, "UIPanelCloseButton")
    closeButton:SetSize(24, 24)
    closeButton:SetPoint("TOPRIGHT", titleFrame, "TOPRIGHT", -3, -1)
    closeButton:SetScript("OnClick", function()
        if not mainFrame then return end
        mainFrame:Hide()
    end)

    -- Scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -32, 12)

    local content = CreateFrame("Frame")
    if mainFrame then
        content:SetSize(mainFrame:GetWidth() - 50, 1)
    end
    scrollFrame:SetScrollChild(content)

    -- Store references
    if mainFrame then
        mainFrame.titleFrame = titleFrame
        mainFrame.title = title
        mainFrame.scrollFrame = scrollFrame
        mainFrame.content = content
    end

    -- Resize handling
    BiSTracker.UI.SetupFrameResizing()
end

function BiSTracker.UI.SetupFrameResizing()
    -- Resize grip
    local resizeGrip = CreateFrame("Button", nil, mainFrame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
    resizeGrip:EnableMouse(true)
    resizeGrip:RegisterForDrag("LeftButton")

    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeGrip:SetScript("OnDragStart", function()
        if not mainFrame then return end
        mainFrame:StartSizing("BOTTOMRIGHT")
    end)

    resizeGrip:SetScript("OnDragStop", function()
        if not mainFrame then return end
        mainFrame:StopMovingOrSizing()
        BiSTracker.UI.OnFrameResized()
    end)

    if mainFrame then
        mainFrame:SetScript("OnSizeChanged", BiSTracker.UI.OnFrameResized)
    end
end

function BiSTracker.UI.OnFrameResized()
    if not mainFrame or not mainFrame.content then
        return
    end

    local width = mainFrame:GetWidth()
    mainFrame.titleFrame:SetWidth(width)
    mainFrame.content:SetSize(width - 50, mainFrame.content:GetHeight())

    -- Refresh display if showing
    if mainFrame:IsShown() then
        BiSTracker.UI.PopulateBiSItems()
    end
end

function BiSTracker.UI.ToggleMainFrame()
    if not mainFrame then
        BiSTracker.UI.CreateMainFrame()
    end

    if not mainFrame then return end
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        BiSTracker.UI.PopulateBiSItems()
        mainFrame:Show()
    end
end

function BiSTracker.UI.PopulateBiSItems()
    if not mainFrame or not mainFrame.content then
        return
    end

    -- Clear existing content
    for i, child in ipairs({mainFrame.content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local classSpec = BiSTracker.Utils.GetCurrentPlayerClassAndSpec()
    local bisData = BiSTracker.DataManager.GetCurrentPlayerBiSGear()

    if not bisData then
        BiSTracker.UI.ShowNoDataMessage(classSpec or "Unknown")
        return
    end

    BiSTracker.UI.CreateContentHeader(classSpec)
    BiSTracker.UI.CreateFilterControls()
    BiSTracker.UI.CreateItemList(bisData)
end

function BiSTracker.UI.ShowNoDataMessage(classSpec)
    if not mainFrame or not mainFrame.content then
        return
    end
    local noDataText = mainFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    noDataText:SetPoint("TOP", mainFrame.content, "TOP", 0, -50)
    noDataText:SetText("No BiS data available for " .. classSpec)
    noDataText:SetTextColor(1, 0, 0) -- Red
end

function BiSTracker.UI.CreateContentHeader(classSpec)
    local playerClassName = UnitClass("player")
    local _, specName = GetSpecializationInfo(GetSpecialization())

    if not mainFrame or not mainFrame.content then
        return
    end
    local header = mainFrame.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    header:SetPoint("TOP", mainFrame.content, "TOP", 0, -10)
    header:SetText("Best-in-slot for " .. (playerClassName or "Unknown") .. " - " .. (specName or "No Spec"))
    header:SetTextColor(1, 1, 0) -- Yellow
end

function BiSTracker.UI.CreateFilterControls()
    if not mainFrame or not mainFrame.content then
        return
    end
    local controlFrame = CreateFrame("Frame", nil, mainFrame.content)
    controlFrame:SetSize(mainFrame.content:GetWidth() - 10, 60)
    controlFrame:SetPoint("TOP", mainFrame.content, "TOP", 0, -40)

    -- Show all items checkbox
    local checkbox = CreateFrame("CheckButton", nil, controlFrame, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetSize(24, 24)
    checkbox:SetPoint("TOPLEFT", controlFrame, "TOPLEFT", 10, -10)
    checkbox:SetChecked(BiSTracker.Settings.ShouldShowAllItems())

    local checkboxLabel = controlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkboxLabel:SetText("Show All Items")

    controlFrame:EnableMouse(true)
    controlFrame:SetScript("OnMouseUp", function()
        checkbox:Click()
    end)

    checkbox:SetScript("OnClick", function(self)
        BiSTracker.Settings.Set("showAllItems", self:GetChecked())
        BiSTracker.UI.PopulateBiSItems()
    end)

    -- Test alert button
    local testButton = CreateFrame("Button", nil, controlFrame, "UIPanelButtonTemplate")
    testButton:SetSize(120, 25)
    testButton:SetPoint("TOP", checkbox, "BOTTOM", 60, -10)
    testButton:SetText("Test Alert")
    testButton:SetScript("OnClick", function()
        BiSTracker.Alerts.SendTestAlert()
    end)
end

function BiSTracker.UI.CreateItemList(bisData)
    local showAll = BiSTracker.Settings.ShouldShowAllItems()
    local filteredData = BiSTracker.DataManager.GetFilteredBiSData(showAll)

    local yOffset = -110
    for _, slotData in ipairs(filteredData) do
        BiSTracker.UI.CreateItemFrame(slotData, yOffset)
        yOffset = yOffset - BiSTracker.Constants.UI.ITEM_FRAME_HEIGHT - 5
    end

    if not mainFrame or not mainFrame.content then
        return
    end
    mainFrame.content:SetHeight(math.abs(yOffset) + 20)
end

function BiSTracker.UI.CreateItemFrame(slotData, yOffset)
    if not mainFrame or not mainFrame.content then
        return
    end
    local parentWidth = mainFrame.content:GetWidth()
    local itemFrame = CreateFrame("Frame", nil, mainFrame.content)
    itemFrame:SetSize(parentWidth - 10, BiSTracker.Constants.UI.ITEM_FRAME_HEIGHT)
    itemFrame:SetPoint("TOPLEFT", mainFrame.content, "TOPLEFT", 5, yOffset)

    local bg = itemFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(itemFrame)
    bg:SetColorTexture(0, 0, 0, 0.1)

    BiSTracker.UI.PopulateItemFrame(itemFrame, slotData, parentWidth)

    -- Hover effects
    itemFrame:SetScript("OnEnter", function()
        bg:SetColorTexture(1, 1, 1, 0.1)
    end)

    itemFrame:SetScript("OnLeave", function()
        bg:SetColorTexture(0, 0, 0, 0.1)
    end)
end

function BiSTracker.UI.PopulateItemFrame(frame, slotData, width)
    -- Slot name
    local slotText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    slotText:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -10)
    slotText:SetText(slotData.Slot .. ":")
    slotText:SetWidth(120)
    slotText:SetJustifyH("LEFT")

    -- Main item name
    local itemText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemText:SetPoint("LEFT", slotText, "RIGHT", 5, 0)
    itemText:SetText(slotData.BiSItems.overall.name)
    itemText:SetWidth(width - 150)
    itemText:SetJustifyH("LEFT")

    -- Color based on status
    if slotData.equipped then
        if slotData.upgradeable then
            itemText:SetTextColor(1, 0.5, 0) -- Orange (upgradeable)
        else
            itemText:SetTextColor(0, 1, 0) -- Green (BiS equipped)
        end
    else
        itemText:SetTextColor(1, 1, 1) -- White (not equipped)
    end

    -- Source information
    local yPos = -25
    BiSTracker.UI.CreateSourceText(frame, "Overall", slotData.BiSItems.overall, width, yPos)
    BiSTracker.UI.CreateSourceText(frame, "Raid", slotData.BiSItems.raid, width, yPos - 12)
    BiSTracker.UI.CreateSourceText(frame, "M+", slotData.BiSItems.mythic_plus, width, yPos - 24)
end

function BiSTracker.UI.CreateSourceText(parent, label, itemData, width, yPos)
    local sourceText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceText:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yPos)
    sourceText:SetText(label .. ": " .. (itemData.source or "Unknown"))
    sourceText:SetWidth(width - 25)
    sourceText:SetJustifyH("LEFT")

    if itemData.equipped then
        sourceText:SetTextColor(0, 1, 0) -- Green
    else
        sourceText:SetTextColor(0.7, 0.7, 0.7) -- Gray
    end
end

-- Minimap Button Management

function BiSTracker.UI.CreateMinimapButton()
    if minimapButton then
        return minimapButton
    end

    minimapButton = CreateFrame("Button", "BiSTrackerMinimapButton", Minimap)
    minimapButton:SetSize(BiSTracker.Constants.UI.MINIMAP_BUTTON_SIZE, BiSTracker.Constants.UI.MINIMAP_BUTTON_SIZE)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:SetMovable(true)
    minimapButton:EnableMouse(true)
    minimapButton:RegisterForDrag("LeftButton")

    -- Position on minimap
    local position = BiSTracker.Settings.Get("minimapPosition") or 45
    BiSTracker.UI.PositionMinimapButton(position)

    -- Texture
    local texture = minimapButton:CreateTexture(nil, "BACKGROUND")
    texture:SetSize(24, 24)
    texture:SetPoint("CENTER")
    texture:SetTexture("Interface\\Icons\\INV_Jewelry_Ring_Ahnqiraj_02")

    -- Event handlers
    minimapButton:SetScript("OnClick", function()
        if BiSTracker.ModernUI and BiSTracker.ModernUI.ToggleMainFrame then
            BiSTracker.ModernUI.ToggleMainFrame()
        else
            BiSTracker.UI.ToggleMainFrame()
        end
    end)
    minimapButton:SetScript("OnEnter", BiSTracker.UI.ShowMinimapTooltip)
    minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    minimapButton:SetScript("OnDragStart", function(self) self:StartMoving() end)
    minimapButton:SetScript("OnDragStop", function(self) 
        self:StopMovingOrSizing()
        BiSTracker.UI.SaveMinimapPosition()
    end)

    return minimapButton
end

function BiSTracker.UI.PositionMinimapButton(angle)
    if not minimapButton then
        return
    end

    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function BiSTracker.UI.SaveMinimapPosition()
    if not minimapButton then
        return
    end

    local centerX, centerY = Minimap:GetCenter()
    local buttonX, buttonY = minimapButton:GetCenter()
    local angle = math.atan2(buttonY - centerY, buttonX - centerX)

    BiSTracker.Settings.Set("minimapPosition", angle)
end

function BiSTracker.UI.ShowMinimapTooltip()
    if not minimapButton then
        return
    end
    GameTooltip:SetOwner(minimapButton, "ANCHOR_LEFT")
    GameTooltip:SetText(BiSTracker.Utils.Colorize("BiS Tracker", BiSTracker.Constants.COLORS.GOLD))
    GameTooltip:AddLine("Click to toggle BiS window", 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: Toggle window", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Drag: Move button", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function BiSTracker.UI.UpdateMinimapButtonVisibility()
    if not minimapButton then
        return
    end

    if BiSTracker.Settings.ShouldShowMinimap() then
        minimapButton:Show()
    else
        minimapButton:Hide()
    end
end

-- Export
_G.BiSTracker = BiSTracker