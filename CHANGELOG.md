# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.2] - 2025-11-26

### Fixed
- **Region Navigation Policy Detection**: Fixed issue where `RegionAwareFocusTraversalPolicy` was not being detected properly
  - Now directly checks for and uses the policy via `FocusTraversalGroup.maybeOf()`
  - Ensures region navigation rules are applied correctly when navigating between regions

### Improved
- **Navigation Logic**: Streamlined the navigation flow in `_navigate()` method

## [2.0.1] - 2025-11-25

### Added
- **Window Focus Restoration**: Automatically restores focus when app/window regains focus
  - Implements `WidgetsBindingObserver` to detect `AppLifecycleState.resumed`
  - Restores last focused widget from history or finds first focusable widget
  - Handles navigation attempts when no widget is focused

### Improved
- **Smart Region Navigation**: Prioritizes within-region navigation before cross-region jumps
  - Navigates through all items in current region (including hidden/scrolled items) first
  - Only crosses to other regions when current region boundary is reached
  - Better geometric calculation for directional navigation
- **Focus History Safety**: Improved `requestFocusSafely()` to handle async focus changes correctly
  - Removed premature focus verification that could fail due to async timing
  - Added context validity check before requesting focus

### Fixed
- Fixed issue where navigation stopped working after window lost and regained focus
- Fixed issue where pressing left/right would jump to sidebar before navigating through all list items
- Fixed focus memory restoration returning `false` due to async focus request timing

## [2.0.0] - 2025-11-25

### Added
- **Region-based Navigation System**: A completely new navigation paradigm for TV apps
  - `RegionNavigationOptions` for configuring cross-region navigation behavior
  - `RegionNavigationRule` for defining navigation rules between regions
  - `RegionNavigationStrategy` enum with 4 strategies:
    - `geometric`: Flutter's default distance-based navigation
    - `fixedEntry`: Always focus the entry point widget
    - `memory`: Restore last focused widget in target region
    - `custom`: User-defined navigation logic
  - `RegionNavigationManager` for managing region registrations
  - `isEntryPoint` and `entryPriority` properties in `DpadFocusable`
  - Bidirectional rules support with `bidirectional` and `reverseStrategy`

- **Flutter System API Integration**:
  - `RegionAwareFocusTraversalPolicy` extending `ReadingOrderTraversalPolicy`
  - `RegionTraversalGroup` widget for wrapping with custom policy
  - `RegionTraversalGroupScope` InheritedWidget for passing manager
  - Uses `FocusScope.focusInDirection()` for native navigation

### Improved
- Better integration with Flutter's native focus traversal system
- Enhanced `DpadNavigator.regionManagerOf()` for accessing region manager
- Automatic region manager updates when options change

### Breaking Changes
- This is a major version update with new APIs
- Existing code using v1.x should continue to work without changes

## [1.2.2] - 2025-11-25

### Added
- Auto-scroll feature for `DpadFocusable` to ensure focused widgets are fully visible
- `autoScroll` parameter to enable/disable auto-scroll (default: `true`)
- `scrollPadding` parameter to control extra padding around focused widgets (default: `24.0`)
- Smart scrolling algorithm that handles both horizontal and vertical scroll containers
- `scrollToFocus()` method in `Dpad` utility class for programmatic scroll control

### Improved
- Focus effects like glow, shadows, and borders are now fully visible at viewport edges
- Enhanced InheritedWidget pattern with `_DpadNavigatorScope` for O(1) ancestor lookup
- Instance-based `FocusHistoryManager` per `DpadNavigator` for proper scope isolation
- Better duplicate recording prevention with `lastPoppedEntry` tracking

### Fixed
- Focus glow being clipped when items are at the edge of scrollable containers

## [1.2.1] - 2025-11-25

### Fixed
- Improved focus memory safety by removing excessive FocusNode validation checks
- Fixed context-based focus history retrieval in Dpad utility methods
- Simplified FocusNode.isValid check for better performance and reliability
- Updated DpadCore methods to require context parameter for navigator-scoped history
- Fixed DpadNavigator scope isolation for independent focus history per navigator

### Improved
- Enhanced error handling for disposed FocusNode detection
- Optimized focus restoration logic to avoid redundant validation
- Streamlined example code by removing debug shortcuts for focus history
- Updated documentation to reflect context-based API changes

## [1.2.0] - 2025-11-23

### Added
- Focus memory system for intelligent focus restoration
- `FocusMemoryOptions` configuration for focus memory settings
- `region` property in `DpadFocusable` for area identification
- `onNavigateBack` callback in `DpadNavigator` for custom back navigation logic
- Stack-based focus history management with configurable size limits
- Route and region aware focus restoration

### Features
- Automatic focus position restoration when returning to previous areas
- Tab switching memory - returns to previously selected tab
- Filter navigation memory - returns to previously selected filter option
- Cross-route focus history tracking
- Configurable focus memory size and regions
- Complete backward compatibility with existing APIs

## [1.1.0] - 2025-11-14

### Added
- Sequential navigation support with `navigateNext()` and `navigatePrevious()` methods
- Default keyboard shortcuts for sequential navigation:
  - Tab/Shift+Tab for next/previous navigation
  - Media Track Next/Previous for media control
  - Channel Up/Down for TV remote sequential navigation
- Enhanced documentation for sequential navigation use cases

### Features
- Logical focus traversal order navigation (independent of spatial positioning)
- Media player control support
- Form field sequential navigation
- List and grid item navigation
- TV remote channel button support

## [1.0.0] - 2025-11-14

### Added
- Initial release of Dpad - Flutter TV Navigation System
- `DpadNavigator` widget for global D-pad event handling
- `DpadFocusable` widget for making any widget focusable
- `FocusEffects` class with 8+ built-in focus effects:
  - Border highlight
  - Glow/shadow effect
  - Scale animation
  - Gradient background
  - Elevation effect
  - Combined scale and border
  - Opacity transition
  - Color tint effect
- `Dpad` utility class for programmatic navigation
- Support for custom keyboard shortcuts
- Platform-specific key handling (menu, back, select)
- Full compatibility with Flutter's native focus system
- Support for Android TV, Fire TV, Apple TV, and game controllers
- Complete documentation and examples
- TypeScript-like strong typing throughout
- Performance optimizations for smooth navigation

### Features
- Simple 3-step setup process
- Custom focus effect builders
- Programmatic focus control
- Custom keyboard shortcuts support
- Multi-platform TV support
- Built-in accessibility features
- Seamless Flutter integration

### Documentation
- Comprehensive README with examples
- API documentation in source code
- Example app demonstrating all features
- Migration guide from other solutions
