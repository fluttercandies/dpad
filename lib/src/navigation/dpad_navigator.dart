import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/dpad_core.dart';
import '../core/focus_history.dart';
import '../core/focus_memory_options.dart';

/// Callback type for focus navigation back functionality.
///
/// [context] The current build context
/// [previousEntry] The previous focus entry
/// [history] Complete focus history stack
/// Returns KeyEventResult.handled if processed, ignored for system default behavior
typedef FocusNavigateBackCallback = KeyEventResult Function(
    BuildContext context,
    FocusHistoryEntry? previousEntry,
    List<FocusHistoryEntry> history);

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
///         LogicalKeyboardKey.keyG: () {}, // Grid view
///         LogicalKeyboardKey.keyL: () {}, // List view
///       },
///       onMenuPressed: () {}, // Menu pressed
///       onBackPressed: () {}, // Back pressed
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
/// InheritedWidget that provides access to DpadNavigator configuration.
///
/// This allows descendant widgets to efficiently access the navigator's
/// configuration without traversing the widget tree manually.
class _DpadNavigatorScope extends InheritedWidget {
  /// The focus memory configuration.
  final FocusMemoryOptions? focusMemory;

  /// The focus history manager instance for this navigator scope.
  final FocusHistoryManager? historyManager;

  const _DpadNavigatorScope({
    required super.child,
    required this.focusMemory,
    required this.historyManager,
  });

  @override
  bool updateShouldNotify(_DpadNavigatorScope oldWidget) {
    return focusMemory != oldWidget.focusMemory ||
        historyManager != oldWidget.historyManager;
  }

  /// Gets the nearest [_DpadNavigatorScope] from the widget tree.
  ///
  /// Returns null if no [DpadNavigator] is found in the ancestor tree.
  static _DpadNavigatorScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_DpadNavigatorScope>();
  }
}

class DpadNavigator extends StatefulWidget {
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

  /// Focus memory configuration options.
  ///
  /// Used to configure the enabled state and behavior of focus memory features.
  final FocusMemoryOptions? focusMemory;

  /// Focus navigation back callback.
  ///
  /// Used to handle the back key with focus memory restoration logic.
  /// Provides context information for user customization.
  final FocusNavigateBackCallback? onNavigateBack;

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
    this.focusMemory,
    this.onNavigateBack,
  });

  /// Gets the focus memory options from the nearest [DpadNavigator].
  ///
  /// Returns null if no [DpadNavigator] is found or focus memory is not configured.
  ///
  /// **Example:**
  /// ```dart
  /// final focusMemory = DpadNavigator.focusMemoryOf(context);
  /// if (focusMemory?.enabled == true) {
  ///   // Focus memory is enabled
  /// }
  /// ```
  static FocusMemoryOptions? focusMemoryOf(BuildContext context) {
    return _DpadNavigatorScope.maybeOf(context)?.focusMemory;
  }

  /// Gets the focus history manager from the nearest [DpadNavigator].
  ///
  /// Returns null if no [DpadNavigator] is found or focus memory is not enabled.
  /// Each [DpadNavigator] has its own isolated history manager instance.
  ///
  /// **Example:**
  /// ```dart
  /// final history = DpadNavigator.historyOf(context);
  /// if (history != null) {
  ///   final current = history.getCurrent();
  ///   final previous = history.getPrevious();
  /// }
  /// ```
  static FocusHistoryManager? historyOf(BuildContext context) {
    return _DpadNavigatorScope.maybeOf(context)?.historyManager;
  }

  @override
  State<DpadNavigator> createState() => _DpadNavigatorState();
}

class _DpadNavigatorState extends State<DpadNavigator> {
  /// The focus history manager for this navigator instance.
  FocusHistoryManager? _historyManager;

  @override
  void initState() {
    super.initState();
    // Initialize focus history manager only when focus memory is enabled
    if (widget.focusMemory?.enabled == true) {
      _historyManager = FocusHistoryManager(
        maxSize: widget.focusMemory!.maxHistory,
      );
    }
  }

  @override
  void didUpdateWidget(DpadNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasEnabled = oldWidget.focusMemory?.enabled == true;
    final isEnabled = widget.focusMemory?.enabled == true;

    if (!wasEnabled && isEnabled) {
      // Focus memory was just enabled, create manager
      _historyManager = FocusHistoryManager(
        maxSize: widget.focusMemory!.maxHistory,
      );
    } else if (wasEnabled && !isEnabled) {
      // Focus memory was just disabled, dispose manager
      _historyManager?.clear();
      _historyManager = null;
    } else if (isEnabled &&
        widget.focusMemory?.maxHistory != oldWidget.focusMemory?.maxHistory) {
      // Only update max size if it changed
      _historyManager?.setMaxSize(widget.focusMemory!.maxHistory);
    }
  }

  @override
  void dispose() {
    _historyManager?.clear();
    _historyManager = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If navigation is disabled, just return the child as-is
    if (!widget.enabled) {
      return widget.child;
    }

    // Wrap with Focus widget to handle key events
    // Note: We don't request focus here to let child widgets manage focus
    return _DpadNavigatorScope(
      focusMemory: widget.focusMemory,
      historyManager: _historyManager,
      child: Focus(
        // Don't autofocus to prevent stealing focus from child widgets
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // Handle special keys that don't use the shortcut system
            if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.goBack) {
              return _handleNavigateBack(context);
            }
            if (event.logicalKey == LogicalKeyboardKey.contextMenu) {
              widget.onMenuPressed?.call();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: CallbackShortcuts(
          bindings: _buildBindings(),
          child: widget.child,
        ),
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
  /// - Tab/Shift+Tab: Navigate to next/previous in focus order
  /// - Media Track Next/Previous: Sequential navigation
  /// - Channel Up/Down: TV remote sequential navigation
  /// - Enter/Select/Space: Trigger selection action
  ///
  /// Returns a map of [ShortcutActivator] to [VoidCallback] pairs.
  Map<ShortcutActivator, VoidCallback> _buildBindings() {
    final bindings = <ShortcutActivator, VoidCallback>{
      // Directional navigation controls
      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
          _navigate(TraversalDirection.up),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
          _navigate(TraversalDirection.down),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
          _navigate(TraversalDirection.left),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
          _navigate(TraversalDirection.right),

      // Sequential navigation controls
      const SingleActivator(LogicalKeyboardKey.tab): () => _navigateNext(),
      const SingleActivator(LogicalKeyboardKey.tab, shift: true): () =>
          _navigatePrevious(),
      const SingleActivator(LogicalKeyboardKey.mediaTrackNext): () =>
          _navigateNext(),
      const SingleActivator(LogicalKeyboardKey.mediaTrackPrevious): () =>
          _navigatePrevious(),
      const SingleActivator(LogicalKeyboardKey.channelUp): () =>
          _navigateNext(),
      const SingleActivator(LogicalKeyboardKey.channelDown): () =>
          _navigatePrevious(),

      // Selection controls
      const SingleActivator(LogicalKeyboardKey.enter): () => _selectCurrent(),
      const SingleActivator(LogicalKeyboardKey.select): () => _selectCurrent(),
      const SingleActivator(LogicalKeyboardKey.space): () => _selectCurrent(),
    };

    // Add any custom shortcuts provided by user
    if (widget.customShortcuts != null) {
      for (final entry in widget.customShortcuts!.entries) {
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

  /// Navigates to the next widget in the focus traversal order.
  ///
  /// This method follows the logical focus order rather than spatial positioning,
  /// making it ideal for sequential navigation like media controls, lists,
  /// or form fields. Uses Flutter's native nextFocus() method.
  void _navigateNext() {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus != null) {
      currentFocus.nextFocus();
    }
  }

  /// Navigates to the previous widget in the focus traversal order.
  ///
  /// This method follows the logical focus order in reverse, making it ideal
  /// for sequential navigation like media controls, lists, or form fields.
  /// Uses Flutter's native previousFocus() method.
  void _navigatePrevious() {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus != null) {
      currentFocus.previousFocus();
    }
  }

  /// Handles focus memory logic for back key navigation.
  ///
  /// [context] The current build context
  /// Returns KeyEventResult.handled if processed, ignored for system default behavior
  KeyEventResult _handleNavigateBack(BuildContext context) {
    // If focus memory is disabled or no history manager, use original logic
    if (widget.focusMemory?.enabled != true || _historyManager == null) {
      widget.onBackPressed?.call();
      return KeyEventResult.handled;
    }

    final historyManager = _historyManager!;

    // Get previous focus and complete history
    historyManager.cleanup();

    FocusHistoryEntry? previousEntry = historyManager.pop();
    final history = historyManager.getHistory();

    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && previousEntry?.focusNode == primaryFocus) {
      // Avoid returning the same entry
      previousEntry = historyManager.pop();
    }

    final onNavigateBack = widget.onNavigateBack;
    if (onNavigateBack != null) {
      final result = widget.onNavigateBack!(context, previousEntry, history);
      if (result == KeyEventResult.ignored) {
        widget.onBackPressed?.call();
        return KeyEventResult.handled;
      }
      return result;
    }

    // If user handled the back key, restore previous focus safely
    if (previousEntry != null) {
      // Use the new safe focus request method
      final focusSuccess = previousEntry.requestFocusSafely();

      if (focusSuccess) {
        // Scroll to ensure the focused widget is visible
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Double-check validity before scrolling
          if (previousEntry!.isValid) {
            Dpad.scrollToFocus(previousEntry.focusNode);
          }
        });
      } else {
        // Focus restoration failed, fall back to system back behavior
        widget.onBackPressed?.call();
      }
    } else {
      // User chose system default behavior
      widget.onBackPressed?.call();
    }

    return KeyEventResult.handled;
  }
}
