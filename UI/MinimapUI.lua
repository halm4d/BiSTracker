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
    minimapButton:SetSize(31, 31)  -- Match standard minimap button size
	minimapButton:SetFrameStrata("MEDIUM")
	minimapButton:SetFixedFrameStrata(true)
	minimapButton:SetFrameLevel(8)
	minimapButton:SetFixedFrameLevel(true)
	minimapButton:SetSize(31, 31)
	minimapButton:RegisterForClicks("AnyUp")
	minimapButton:RegisterForDrag("LeftButton")
	minimapButton:SetHighlightTexture(136477) --"Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"

    -- Position on minimap
    local position = BiSTracker.Settings.Get("minimapPosition") or 45
    BiSTracker.MinimapUI.PositionMinimapButton(position)

    
    -- Border (overlay on top)
    local border = minimapButton:CreateTexture(nil, "OVERLAY")
    border:SetSize(50, 50)  -- Same size as button
    border:SetPoint("TOPLEFT", minimapButton, "TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    -- Texture (icon)
    local texture = minimapButton:CreateTexture(nil, "BACKGROUND")
    texture:SetSize(24, 24)  -- Smaller than button to leave room for border
    texture:SetPoint("CENTER", minimapButton, "CENTER")
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