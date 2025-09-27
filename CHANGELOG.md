# Changelog

All notable changes to BiS Tracker will be documented in this file.

## [1.0.0] - 2025-09-27

### Added
- Initial release of BiS Tracker addon
- Core tracking functionality for Best-in-Slot items
- Support for all classes and specializations
- Modular architecture with separated concerns
- Main UI window for viewing BiS items and current gear
- Settings panel for customization
- Alert system for BiS item notifications
- Slash commands for easy access:
  - `/bis` - Toggle main window
  - `/bis help` - Show help information
  - `/bis stats` - Show completion statistics
  - `/bissettings` - Open settings panel
- Event-driven architecture for efficient performance
- Data management system for BiS item lookups
- Utility functions for common operations
- Error handling and debug mode support
- Backward compatibility layer for future updates

### Core Features
- **Comprehensive Class Support**: All WoW classes and specializations
- **Real-time Tracking**: Automatically detects equipped gear changes
- **Smart Notifications**: Configurable alerts for BiS item availability
- **Professional UI**: Clean, resizable interface with modern design
- **Performance Optimized**: Efficient event handling and data caching
- **User-friendly Commands**: Intuitive slash command system
- **Flexible Settings**: Customizable alerts, UI preferences, and more

### Technical Implementation
- **Modular Design**: Separated into logical modules (Core, UI, Data)
- **Event System**: Centralized event management for better performance
- **Data Layer**: Efficient BiS data storage and retrieval
- **Error Handling**: Comprehensive error catching with debug support
- **Documentation**: Full inline documentation for maintainability

### Files Structure
```
BiSTracker/
├── Core/
│   ├── Constants.lua      # Configuration constants
│   ├── Utils.lua         # Utility functions
│   ├── Settings.lua      # Settings management
│   ├── DataManager.lua   # BiS data handling
│   ├── Events.lua        # Event system
│   ├── Alerts.lua        # Alert system
│   └── Commands.lua      # Slash commands
├── UI/
│   ├── MainUI.lua        # Main interface
│   └── SettingsUI.lua    # Settings panel
├── BiSTrackerData.lua    # BiS item database
├── BiSTracker.lua        # Main entry point
└── BiSTracker.toc        # Addon manifest
```

### Known Issues
- None at release

### Notes
- Compatible with World of Warcraft 11.0.1+
- Requires no additional dependencies
- Saved variables: BiSTrackerDB

---

## Version History Format

### [Version] - YYYY-MM-DD

#### Added
- New features

#### Changed
- Changes in existing functionality

#### Deprecated
- Soon-to-be removed features

#### Removed
- Now removed features

#### Fixed
- Any bug fixes

#### Security
- In case of vulnerabilities