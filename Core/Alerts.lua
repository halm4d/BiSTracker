-- Alert system for BiS Tracker
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- Alert Manager
BiSTracker.Alerts = {}

---@param message string Alert message to display
---@param duration number|nil Alert duration in seconds (default: 3)
---@param playSound boolean|nil Whether to play sound (default: true)
function BiSTracker.Alerts.SendAlert(message, duration, playSound)
    if not message then
        return
    end

    duration = duration or BiSTracker.Settings.Get("alertDuration") or BiSTracker.Constants.UI.ALERT_DURATION
    playSound = playSound ~= false and BiSTracker.Settings.Get("alertSound") ~= false

    -- Create alert frame
    local alert = CreateFrame("Frame", nil, UIParent)
    alert:SetSize(800, 200)
    alert:SetPoint("CENTER", UIParent, "CENTER")
    alert:SetFrameStrata("DIALOG")
    alert:SetFrameLevel(100)

    -- Text
    local text = alert:CreateFontString(nil, "OVERLAY", "Game72Font_Shadow")
    text:SetPoint("CENTER")
    text:SetText(message)
    text:SetWidth(750)
    text:SetJustifyH("CENTER")

    -- Play sound if enabled
    if playSound then
        PlaySound(BiSTracker.Constants.SOUNDS.ALERT, "Master")
    end

    -- Animation
    local fadeIn = alert:CreateAnimationGroup()
    local alpha = fadeIn:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
    alpha:SetDuration(0.3)

    local fadeOut = alert:CreateAnimationGroup()
    local alphaOut = fadeOut:CreateAnimation("Alpha")
    alphaOut:SetFromAlpha(1)
    alphaOut:SetToAlpha(0)
    alphaOut:SetDuration(0.5)
    alphaOut:SetStartDelay(duration - 0.5)

    fadeOut:SetScript("OnFinished", function()
        alert:Hide()
        alert:SetParent(nil)
    end)

    alert:Show()
    fadeIn:Play()
    fadeOut:Play()

    BiSTracker.Utils.PrintDebug("Alert sent: " .. message)

    return alert
end

---@param message string|nil Test alert message
function BiSTracker.Alerts.SendTestAlert(message)
    message = message or BiSTracker.Utils.Colorize("This is a test BiS alert!", BiSTracker.Constants.COLORS.GREEN)
    BiSTracker.Alerts.SendAlert(message)
    BiSTracker.Utils.Print("Test alert sent!")
end

-- Export
_G.BiSTracker = BiSTracker