local BiSTracker = BiSTracker or {}

-- Settings panel
local settingsPanel = CreateFrame("Frame", "BiSTrackerSettingsPanel", UIParent)
settingsPanel.name = "BiS Tracker"

-- Title
local title = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("BiS Tracker Settings")

-- Description
local description = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
description:SetText("Configure your BiS Tracker addon settings.")

-- Test Alert Button
local testButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
testButton:SetSize(120, 25)
testButton:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -20)
testButton:SetText("Test Alert")

testButton:SetScript("OnClick", function()
    if SendAlert and Colorize then
        SendAlert(Colorize("BiS item dropped!", "00FF00"))
        print("BiS Tracker: Test alert sent!")
    else
        print("BiS Tracker: SendAlert or Colorize function not available")
    end
end)

-- Show All Items by Default checkbox
local showAllCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "InterfaceOptionsCheckButtonTemplate")
showAllCheckbox:SetPoint("TOPLEFT", testButton, "BOTTOMLEFT", 0, -20)
showAllCheckbox.Text:SetText("Show all items by default")

-- Minimap Button checkbox
local minimapCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "InterfaceOptionsCheckButtonTemplate")
minimapCheckbox:SetPoint("TOPLEFT", showAllCheckbox, "BOTTOMLEFT", 0, -10)
minimapCheckbox.Text:SetText("Show minimap button")

-- Alert Settings Section
local alertTitle = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
alertTitle:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 0, -30)
alertTitle:SetText("Alert Settings")

-- Enable Alerts checkbox
local enableAlertsCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "InterfaceOptionsCheckButtonTemplate")
enableAlertsCheckbox:SetPoint("TOPLEFT", alertTitle, "BOTTOMLEFT", 0, -10)
enableAlertsCheckbox.Text:SetText("Enable BiS item alerts")

-- Reset Button
local resetButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
resetButton:SetSize(100, 25)
resetButton:SetPoint("BOTTOMLEFT", settingsPanel, "BOTTOMLEFT", 16, 16)
resetButton:SetText("Reset")

resetButton:SetScript("OnClick", function()
    -- Reset all settings to defaults
    showAllCheckbox:SetChecked(true)
    minimapCheckbox:SetChecked(true)
    enableAlertsCheckbox:SetChecked(true)
    print("BiS Tracker: Settings reset to defaults")
end)

-- Initialize default values
local function InitializeSettings()
    -- Load saved variables or set defaults
    BiSTrackerDB = BiSTrackerDB or {}
    BiSTrackerDB.showAllItems = BiSTrackerDB.showAllItems ~= false -- default true
    BiSTrackerDB.showMinimap = BiSTrackerDB.showMinimap ~= false -- default true
    BiSTrackerDB.enableAlerts = BiSTrackerDB.enableAlerts ~= false -- default true

    -- Set checkbox states
    showAllCheckbox:SetChecked(BiSTrackerDB.showAllItems)
    minimapCheckbox:SetChecked(BiSTrackerDB.showMinimap)
    enableAlertsCheckbox:SetChecked(BiSTrackerDB.enableAlerts)
end

-- Save settings when changed
local function SaveSettings()
    BiSTrackerDB.showAllItems = showAllCheckbox:GetChecked()
    BiSTrackerDB.showMinimap = minimapCheckbox:GetChecked()
    BiSTrackerDB.enableAlerts = enableAlertsCheckbox:GetChecked()
end

-- Set up checkbox callbacks
showAllCheckbox:SetScript("OnClick", function ()
    SaveSettings()
end)
minimapCheckbox:SetScript("OnClick", function()
    SaveSettings()
    -- Toggle minimap button visibility
    if MinimapButton then
        if minimapCheckbox:GetChecked() then
            MinimapButton:Show()
        else
            MinimapButton:Hide()
        end
    end
end)
enableAlertsCheckbox:SetScript("OnClick", function ()
    SaveSettings()
    -- Update loot event registration
    if UpdateLootEventRegistration then
        UpdateLootEventRegistration()
    end

end)

-- Panel event handling
settingsPanel:RegisterEvent("ADDON_LOADED")
settingsPanel:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "BiSTracker" then
        InitializeSettings()
    end
end)

-- For retail (Dragonflight/TWW)
if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(settingsPanel, settingsPanel.name)
    Settings.RegisterAddOnCategory(category)
end

-- Slash command to open settings
SLASH_BISTRACKERSETTINGS1 = "/bissettings"
SLASH_BISTRACKERSETTINGS2 = "/bistrackersettings"
SlashCmdList["BISTRACKERSETTINGS"] = function()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(settingsPanel.name)
    end
end

-- Export settings access
BiSTracker.Settings = {
    GetShowAllItems = function() return BiSTrackerDB and BiSTrackerDB.showAllItems end,
    GetShowMinimap = function() return BiSTrackerDB and BiSTrackerDB.showMinimap end,
    GetEnableAlerts = function() return BiSTrackerDB and BiSTrackerDB.enableAlerts end,
}

-- Global export
_G.BiSTracker = BiSTracker