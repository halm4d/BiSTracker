# UI Architecture Refactoring Plan

## ✅ COMPLETED - Current Issues RESOLVED
- ~~**MainUI.lua** and **ModernUI.lua** have overlapping responsibilities~~ ✅
- ~~Minimap button management is scattered~~ ✅
- ~~Two separate main frame implementations~~ ✅
- ~~Settings UI is duplicated across files~~ ✅

## ✅ COMPLETED - Recommended Structure IMPLEMENTED

### 1. ✅ **MainUI.lua** → **MinimapUI.lua**
- ✅ Focus solely on minimap button functionality
- ✅ Remove the old main frame code
- ✅ Keep: `CreateMinimapButton`, `UpdateMinimapButtonVisibility`, etc.

### 2. ✅ **ModernUI.lua** (Kept as primary UI)
- ✅ Remove dependency on `BiSTracker.UI.UpdateMinimapButtonVisibility`
- ✅ Handle its own settings management via UIManager
- ✅ Be the single source of truth for the main UI

### 3. ✅ **Create UIManager.lua** (New)
- ✅ Coordinate between different UI components
- ✅ Handle UI initialization and selection
- ✅ Manage cross-component communication

### 4. ✅ **SettingsUI.lua** (Already exists)
- ✅ Handle the game's settings panel integration
- ✅ Remove settings UI from ModernUI.lua (delegated via UIManager)

## ✅ COMPLETED - Migration Steps

1. ✅ Extract minimap functionality from MainUI.lua into MinimapUI.lua
2. ✅ Remove old main frame code from MainUI.lua  
3. ✅ Create UIManager.lua to coordinate components
4. ✅ Update ModernUI.lua to be self-contained
5. ✅ Update all references throughout the codebase

## ✅ ACHIEVED - Benefits
- ✅ Clear separation of concerns
- ✅ No code duplication
- ✅ Easier maintenance
- ✅ Better testing capability
- ✅ More modular architecture

## IMPLEMENTATION SUMMARY

### Files Created:
- `UI/MinimapUI.lua` - Dedicated minimap button management
- `UI/UIManager.lua` - Central coordinator for all UI components

### Files Modified:
- `UI/ModernUI.lua` - Now uses UIManager for cross-component communication
- `Core/Settings.lua` - Routes setting changes through UIManager
- `Core/Commands.lua` - Uses UIManager for consistent UI access
- `Core/Events.lua` - Updated to use UIManager for initialization
- `BiSTracker.lua` - Uses UIManager for coordinated initialization
- `BiSTracker.toc` - Updated to reflect new file structure

### Files Removed:
- `UI/MainUI.lua` - Replaced by MinimapUI.lua and UIManager.lua

### Architecture Benefits Achieved:
1. **Modular Design**: Each component has a single, clear responsibility
2. **No Circular Dependencies**: Clean dependency graph
3. **Centralized Communication**: UIManager handles all inter-component communication
4. **Easy Maintenance**: Changes to one component don't require changes to others
5. **Better Testing**: Each component can be tested in isolation
6. **Consistent Interfaces**: All UI interactions go through UIManager