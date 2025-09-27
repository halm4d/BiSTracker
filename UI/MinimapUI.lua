-- Minimap UI module for BiS Tracker
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- Minimap UI Manager
BiSTracker.MinimapUI = {}

-- UI state
local minimapButton = nil
local initialized = false

-- Initialize Minimap UI components
function BiSTracker.MinimapUI.Initialize()
    if initialized then
        return
    end

    BiSTracker.MinimapUI.CreateMinimapButton()
    BiSTracker.MinimapUI.UpdateMinimapButtonVisibility()

    initialized = true
    if BiSTracker.Utils and BiSTracker.Utils.PrintDebug then
        BiSTracker.Utils.PrintDebug("Minimap UI initialized")
    end
end

-- Minimap Button Management
function BiSTracker.MinimapUI.CreateMinimapButton()
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
    BiSTracker.MinimapUI.PositionMinimapButton(position)

    -- Texture
    local texture = minimapButton:CreateTexture(nil, "BACKGROUND")
    texture:SetSize(24, 24)
    texture:SetPoint("CENTER")
    texture:SetTexture("Interface\\Icons\\INV_Jewelry_Ring_Ahnqiraj_02")

    -- Event handlers
    minimapButton:SetScript("OnClick", function()
        -- Always prefer ModernUI if available
        if BiSTracker.ModernUI and BiSTracker.ModernUI.ToggleMainFrame then
            BiSTracker.ModernUI.ToggleMainFrame()
        else
            print("BiS Tracker: UI not available")
        end
    end)
    minimapButton:SetScript("OnEnter", BiSTracker.MinimapUI.ShowMinimapTooltip)
    minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    minimapButton:SetScript("OnDragStart", function(self) self:StartMoving() end)
    minimapButton:SetScript("OnDragStop", function(self) 
        self:StopMovingOrSizing()
        BiSTracker.MinimapUI.SaveMinimapPosition()
    end)

    return minimapButton
end

function BiSTracker.MinimapUI.PositionMinimapButton(angle)
    if not minimapButton then
        return
    end

    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function BiSTracker.MinimapUI.SaveMinimapPosition()
    if not minimapButton then
        return
    end

    local centerX, centerY = Minimap:GetCenter()
    local buttonX, buttonY = minimapButton:GetCenter()
    local angle = math.atan2(buttonY - centerY, buttonX - centerX)

    BiSTracker.Settings.Set("minimapPosition", angle)
end

function BiSTracker.MinimapUI.ShowMinimapTooltip()
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

function BiSTracker.MinimapUI.UpdateMinimapButtonVisibility()
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