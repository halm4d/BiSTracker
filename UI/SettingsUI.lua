-- Settings UI for BiS Tracker
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- Settings UI Manager
BiSTracker.SettingsUI = {}

local settingsPanel = nil

function BiSTracker.SettingsUI.Initialize()
    if settingsPanel then
        return settingsPanel
    end

    settingsPanel = CreateFrame("Frame", "BiSTrackerSettingsPanel", UIParent)
    settingsPanel.name = "BiS Tracker"

    BiSTracker.SettingsUI.CreateSettingsContent()
    BiSTracker.SettingsUI.RegisterSettingsPanel()

    return settingsPanel
end

function BiSTracker.SettingsUI.CreateSettingsContent()
    if not settingsPanel then
        return
    end

    -- Title
    local title = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("BiS Tracker Settings")

    -- Description
    local description = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    description:SetText("Configure your BiS Tracker addon settings.")

    local yOffset = -60

    -- Test Alert Button
    local testButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    testButton:SetSize(120, 25)
    testButton:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, yOffset)
    testButton:SetText("Test Alert")
    testButton:SetScript("OnClick", function()
        BiSTracker.Alerts.SendTestAlert()
    end)
    yOffset = yOffset - 40

    -- Enable Alerts checkbox
    local enableAlertsCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "InterfaceOptionsCheckButtonTemplate")
    enableAlertsCheckbox:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, yOffset)
    enableAlertsCheckbox.Text:SetText("Enable BiS item alerts")
    enableAlertsCheckbox:SetChecked(BiSTracker.Settings.IsAlertsEnabled())
    enableAlertsCheckbox:SetScript("OnClick", function(self)
        BiSTracker.Settings.Set("enableAlerts", self:GetChecked())
    end)
    yOffset = yOffset - 30

    -- Show All Items checkbox
    local showAllCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "InterfaceOptionsCheckButtonTemplate")
    showAllCheckbox:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, yOffset)
    showAllCheckbox.Text:SetText("Show all items by default in UI")
    showAllCheckbox:SetChecked(BiSTracker.Settings.ShouldShowAllItems())
    showAllCheckbox:SetScript("OnClick", function(self)
        BiSTracker.Settings.Set("showAllItems", self:GetChecked())
    end)
    yOffset = yOffset - 30

    -- Show Minimap Button checkbox
    local minimapCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "InterfaceOptionsCheckButtonTemplate")
    minimapCheckbox:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, yOffset)
    minimapCheckbox.Text:SetText("Show minimap button")
    minimapCheckbox:SetChecked(BiSTracker.Settings.ShouldShowMinimap())
    minimapCheckbox:SetScript("OnClick", function(self)
        BiSTracker.Settings.Set("showMinimap", self:GetChecked())
    end)
    yOffset = yOffset - 30

    -- Debug Mode checkbox
    local debugCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "InterfaceOptionsCheckButtonTemplate")
    debugCheckbox:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, yOffset)
    debugCheckbox.Text:SetText("Enable debug mode")
    debugCheckbox:SetChecked(BiSTracker.Settings.IsDebugMode())
    debugCheckbox:SetScript("OnClick", function(self)
        BiSTracker.Settings.Set("debugMode", self:GetChecked())
    end)
    yOffset = yOffset - 50

    -- Reset Button
    local resetButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    resetButton:SetSize(100, 25)
    resetButton:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, yOffset)
    resetButton:SetText("Reset All")
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("BISTRACKER_RESET_CONFIRM")
    end)

    -- Store references for updates
    settingsPanel.enableAlertsCheckbox = enableAlertsCheckbox
    settingsPanel.showAllCheckbox = showAllCheckbox
    settingsPanel.minimapCheckbox = minimapCheckbox
    settingsPanel.debugCheckbox = debugCheckbox
end

function BiSTracker.SettingsUI.RegisterSettingsPanel()
    if not settingsPanel then
        return
    end

    -- For retail (Dragonflight/TWW)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(settingsPanel, settingsPanel.name)
        Settings.RegisterAddOnCategory(category)
    end

    -- Create reset confirmation popup
    StaticPopupDialogs["BISTRACKER_RESET_CONFIRM"] = {
        text = "Are you sure you want to reset all BiS Tracker settings to defaults?",
        button1 = "Reset",
        button2 = "Cancel",
        OnAccept = function()
            BiSTracker.Settings.Reset()
            BiSTracker.SettingsUI.RefreshSettingsUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function BiSTracker.SettingsUI.RefreshSettingsUI()
    if not settingsPanel then
        return
    end

    if settingsPanel.enableAlertsCheckbox then
        settingsPanel.enableAlertsCheckbox:SetChecked(BiSTracker.Settings.IsAlertsEnabled())
    end

    if settingsPanel.showAllCheckbox then
        settingsPanel.showAllCheckbox:SetChecked(BiSTracker.Settings.ShouldShowAllItems())
    end

    if settingsPanel.minimapCheckbox then
        settingsPanel.minimapCheckbox:SetChecked(BiSTracker.Settings.ShouldShowMinimap())
    end

    if settingsPanel.debugCheckbox then
        settingsPanel.debugCheckbox:SetChecked(BiSTracker.Settings.IsDebugMode())
    end
end

function BiSTracker.SettingsUI.OpenSettings()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory("BiS Tracker")
    else
        if BiSTracker.Utils and BiSTracker.Utils.PrintError then
            BiSTracker.Utils.PrintError("Settings UI not available")
        end
    end
end

-- Export
_G.BiSTracker = BiSTracker