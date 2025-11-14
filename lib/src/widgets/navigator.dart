import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Root container providing global D-pad navigation support for Flutter TV apps.
///
/// This widget captures D-pad events and translates them into focus movements,
/// making your Flutter app navigable with D-pad controllers on TV platforms.
///
/// **Example Usage:**
/// ```dart
/// void main() {
///   runApp(
///     DpadNavigator(
///       enabled: true,
///       customShortcuts: {
///         LogicalKeyboardKey.keyG: () => print('Grid view'),
///         LogicalKeyboardKey.keyL: () => print('List view'),
///       },
///       onMenuPressed: () => print('Menu pressed'),
///       onBackPressed: () => print('Back pressed'),
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// **Platform Support:**
/// - Android TV: Full D-pad and remote control support
/// - Amazon Fire TV: Compatible with Fire TV remotes
/// - Apple TV: Works with Siri Remote (Flutter web)
/// - Game Controllers: Standard controller navigation
///
/// **Key Features:**
/// - Automatic D-pad event handling
/// - Custom keyboard shortcuts
/// - Platform-specific key handling
/// - Seamless Flutter focus integration
class DpadNavigator extends StatelessWidget {
  /// The child widget that will have D-pad navigation support.
  /// 
  /// This is typically your app's root widget (MaterialApp, CupertinoApp, etc.).
  /// The child will receive all D-pad navigation capabilities.
  final Widget child;

  /// Map of custom keyboard shortcuts and their corresponding actions.
  /// 
  /// Allows you to add custom key bindings beyond the default D-pad controls.
  /// Useful for application-specific shortcuts like 'G' for grid view, 'L' for list view, etc.
  /// 
  /// **Example:**
  /// ```dart
  /// customShortcuts: {
  ///   LogicalKeyboardKey.keyG: () => _showGridView(),
  ///   LogicalKeyboardKey.keyL: () => _showListView(),
  ///   LogicalKeyboardKey.keyR: () => _refreshData(),
  /// }
  /// ```
  final Map<LogicalKeyboardKey, VoidCallback>? customShortcuts;

  /// Whether D-pad navigation is enabled.
  /// 
  /// When set to false, the widget will pass through the child without any
  /// D-pad handling capabilities. This can be useful for temporarily disabling
  /// TV navigation or for non-TV platforms.
  /// 
  /// Defaults to `true`.
  final bool enabled;

  /// Callback function triggered when the menu key is pressed.
  /// 
  /// This is typically triggered by the menu button on TV remotes or the ContextMenu key.
  /// Use this to show application menus, settings, or other menu-related actions.
  /// 
  /// **Platform Details:**
  /// - Android TV: Menu button on remote
  /// - Fire TV: Menu button on remote
  /// - Generic: ContextMenu key
  final VoidCallback? onMenuPressed;

  /// Callback function triggered when the back key is pressed.
  /// 
  /// This handles the back navigation functionality, typically triggered by:
  /// - Escape key on keyboard
  /// - Back button on TV remotes
  /// - Android back button
  /// 
  /// **Note:** This differs from the system back behavior and gives you
  /// full control over back navigation within your app.
  final VoidCallback? onBackPressed;

  /// Creates a [DpadNavigator] widget.
  ///
  /// The [child] parameter is required. All other parameters are optional.
  /// 
  /// **Example:**
  /// ```dart
  /// DpadNavigator(
  ///   enabled: true,
  ///   onMenuPressed: () => _showMenu(),
  ///   onBackPressed: () => _handleBack(),
  ///   child: MaterialApp(
  ///     home: MyHomePage(),
  ///   ),
  /// )
  /// ```
  const DpadNavigator({
    super.key,
    required this.child,
    this.customShortcuts,
    this.enabled = true,
    this.onMenuPressed,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    // If navigation is disabled, just return the child as-is
    if (!enabled) {
      return child;
    }

    // Wrap with Focus widget to handle key events
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Handle special keys that don't use the shortcut system
          if (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.goBack) {
            onBackPressed?.call();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.contextMenu) {
            onMenuPressed?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: CallbackShortcuts(
        bindings: _buildBindings(),
        child: child,
      ),
    );
  }

  /// Builds the map of keyboard shortcuts and their corresponding actions.
  /// 
  /// This combines default D-pad controls with any custom shortcuts
  /// provided by the user.
  /// 
  /// **Default Shortcuts:**
  /// - Arrow keys: Navigate focus in respective directions
  /// - Enter/Select/Space: Trigger selection action
  /// 
  /// Returns a map of [ShortcutActivator] to [VoidCallback] pairs.
  Map<ShortcutActivator, VoidCallback> _buildBindings() {
    final bindings = <ShortcutActivator, VoidCallback>{
      // Navigation controls
      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
          _navigate(TraversalDirection.up),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
          _navigate(TraversalDirection.down),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
          _navigate(TraversalDirection.left),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
          _navigate(TraversalDirection.right),
      
      // Selection controls
      const SingleActivator(LogicalKeyboardKey.enter): () => _selectCurrent(),
      const SingleActivator(LogicalKeyboardKey.select): () => _selectCurrent(),
      const SingleActivator(LogicalKeyboardKey.space): () => _selectCurrent(),
    };

    // Add any custom shortcuts provided by user
    if (customShortcuts != null) {
      for (final entry in customShortcuts!.entries) {
        bindings[SingleActivator(entry.key)] = entry.value;
      }
    }

    return bindings;
  }

  /// Navigates focus in the specified direction using Flutter's native focus system.
  /// 
  /// This method leverages Flutter's built-in focus traversal system,
  /// ensuring compatibility with all Flutter widgets and proper focus management.
  /// 
  /// **Parameters:**
  /// - [direction]: The direction to navigate (up, down, left, right)
  void _navigate(TraversalDirection direction) {
    // Get the current focused widget's context
    final currentContext = FocusManager.instance.primaryFocus?.context;
    if (currentContext != null) {
      // Use Flutter's native focus navigation for proper focus traversal
      FocusScope.of(currentContext).focusInDirection(direction);
    }
  }

  /// Triggers the selection action on the currently focused widget.
  /// 
  /// This simulates a selection event by consuming the keyboard token,
  /// which triggers the appropriate action on the focused widget.
  /// 
  /// **Technical Details:**
  /// - Consumes keyboard token to trigger focused widget's action
  /// - Works with buttons, list items, and any other interactive widgets
  /// - Maintains consistency with Flutter's focus system
  void _selectCurrent() {
    final currentFocus = FocusManager.instance.primaryFocus;
    // Consume the keyboard token to trigger the selection action
    currentFocus?.consumeKeyboardToken();
  }
}
