-- Constants for BiS Tracker
local addonName = "BiSTracker"

---@class BiSTracker
local BiSTracker = _G.BiSTracker or {}

-- Constants
BiSTracker.Constants = {
    -- Addon Info
    ADDON_NAME = addonName,
    VERSION = "1.0.0",
    
    -- UI Constants
    UI = {
        MAIN_FRAME_WIDTH = 450,
        MAIN_FRAME_HEIGHT = 725,
        ITEM_FRAME_HEIGHT = 70,
        MIN_FRAME_WIDTH = 300,
        MIN_FRAME_HEIGHT = 400,
        MAX_FRAME_WIDTH = 800,
        MAX_FRAME_HEIGHT = 1000,
        MINIMAP_BUTTON_SIZE = 32,
        ALERT_DURATION = 3,
    },
    
    -- Colors (hex without FF prefix)
    COLORS = {
        GOLD = "FFD700",
        GREEN = "00FF00",
        RED = "FF0000",
        ORANGE = "FF8C00",
        LIGHT_BLUE = "00BFFF",
        WHITE = "FFFFFF",
        GRAY = "808080",
    },
    
    -- Sound effects
    SOUNDS = {
        ALERT = SOUNDKIT.RAID_WARNING,
    },
    
    -- Inventory slots
    INVENTORY_SLOTS = {
        HEAD = 1,
        NECK = 2,
        SHOULDER = 3,
        BODY = 4,
        CHEST = 5,
        WAIST = 6,
        LEGS = 7,
        FEET = 8,
        WRIST = 9,
        HANDS = 10,
        FINGER1 = 11,
        FINGER2 = 12,
        TRINKET1 = 13,
        TRINKET2 = 14,
        BACK = 15,
        MAINHAND = 16,
        OFFHAND = 17,
        RANGED = 18,
    },
    
    -- Slash commands
    SLASH_COMMANDS = {
        MAIN = "/bistracker",
        SETTINGS = "/bissettings",
        ALERTS = "/bis-alerts",
        BIS_LIST = "/bis",
    },
    
    -- Default settings
    DEFAULT_SETTINGS = {
        enableAlerts = true,
        showAllItems = true,
        showMinimap = true,
        minimapPosition = 45,
    },
}

-- Export
_G.BiSTracker = BiSTracker