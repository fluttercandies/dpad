import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/dpad_core.dart';
import '../core/focus_history.dart';
import '../core/focus_memory_options.dart';
import '../core/region_navigation.dart';

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

  /// The region navigation manager instance for this navigator scope.
  final RegionNavigationManager? regionManager;

  const _DpadNavigatorScope({
    required super.child,
    required this.focusMemory,
    required this.historyManager,
    required this.regionManager,
  });

  @override
  bool updateShouldNotify(_DpadNavigatorScope oldWidget) {
    return focusMemory != oldWidget.focusMemory ||
        historyManager != oldWidget.historyManager ||
        regionManager != oldWidget.regionManager;
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

  /// Region navigation configuration options.
  ///
  /// Used to configure cross-region navigation behavior for TV apps.
  /// When enabled, navigation between regions can use custom strategies
  /// like fixed entry points or memory-based restoration.
  ///
  /// Example:
  /// ```dart
  /// DpadNavigator(
  ///   regionNavigation: RegionNavigationOptions(
  ///     enabled: true,
  ///     rules: [
  ///       RegionNavigationRule(
  ///         fromRegion: 'tabs',
  ///         toRegion: 'content',
  ///         direction: TraversalDirection.down,
  ///         strategy: RegionNavigationStrategy.fixedEntry,
  ///         bidirectional: true,
  ///         reverseStrategy: RegionNavigationStrategy.memory,
  ///       ),
  ///     ],
  ///   ),
  ///   child: MyApp(),
  /// )
  /// ```
  final RegionNavigationOptions? regionNavigation;

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
    this.regionNavigation,
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

  /// Gets the region navigation manager from the nearest [DpadNavigator].
  ///
  /// Returns null if no [DpadNavigator] is found or region navigation is not enabled.
  /// Each [DpadNavigator] has its own isolated region manager instance.
  ///
  /// **Example:**
  /// ```dart
  /// final regionManager = DpadNavigator.regionManagerOf(context);
  /// if (regionManager != null) {
  ///   final nodes = regionManager.getNodesInRegion('tabs');
  ///   final entryPoint = regionManager.getEntryPointForRegion('content');
  /// }
  /// ```
  static RegionNavigationManager? regionManagerOf(BuildContext context) {
    return _DpadNavigatorScope.maybeOf(context)?.regionManager;
  }

  @override
  State<DpadNavigator> createState() => _DpadNavigatorState();
}

class _DpadNavigatorState extends State<DpadNavigator>
    with WidgetsBindingObserver {
  /// The focus history manager for this navigator instance.
  FocusHistoryManager? _historyManager;

  /// The region navigation manager for this navigator instance.
  RegionNavigationManager? _regionManager;

  @override
  void initState() {
    super.initState();
    // Register as observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Initialize focus history manager only when focus memory is enabled
    if (widget.focusMemory?.enabled == true) {
      _historyManager = FocusHistoryManager(
        maxSize: widget.focusMemory!.maxHistory,
      );
    }
    // Initialize region navigation manager
    if (widget.regionNavigation?.enabled == true) {
      _regionManager = RegionNavigationManager(
        options: widget.regionNavigation!,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes (window regains focus), restore focus if lost
    if (state == AppLifecycleState.resumed) {
      _restoreFocusIfNeeded();
    }
  }

  /// Restores focus when it's been lost (e.g., after window regains focus).
  void _restoreFocusIfNeeded() {
    // Use post-frame callback to ensure the widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final primaryFocus = FocusManager.instance.primaryFocus;

      // If there's already a focused widget, no need to restore
      if (primaryFocus != null && primaryFocus.context != null) {
        return;
      }

      // Try to restore from focus history
      if (_historyManager != null) {
        _historyManager!.cleanup();
        final current = _historyManager!.getCurrent();
        if (current != null && current.isValid) {
          current.focusNode.requestFocus();
          return;
        }
      }

      // If no history, try to find any focusable widget and focus it
      _focusFirstAvailable();
    });
  }

  /// Finds and focuses the first available focusable widget.
  void _focusFirstAvailable() {
    // This will trigger focus on the first focusable widget in the tree
    // by using the focus traversal system
    final scope = FocusManager.instance.rootScope;
    scope.focusInDirection(TraversalDirection.down);
  }

  @override
  void didUpdateWidget(DpadNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle focus memory changes
    final wasMemoryEnabled = oldWidget.focusMemory?.enabled == true;
    final isMemoryEnabled = widget.focusMemory?.enabled == true;

    if (!wasMemoryEnabled && isMemoryEnabled) {
      _historyManager = FocusHistoryManager(
        maxSize: widget.focusMemory!.maxHistory,
      );
    } else if (wasMemoryEnabled && !isMemoryEnabled) {
      _historyManager?.clear();
      _historyManager = null;
    } else if (isMemoryEnabled &&
        widget.focusMemory?.maxHistory != oldWidget.focusMemory?.maxHistory) {
      _historyManager?.setMaxSize(widget.focusMemory!.maxHistory);
    }

    // Handle region navigation changes
    final wasRegionEnabled = oldWidget.regionNavigation?.enabled == true;
    final isRegionEnabled = widget.regionNavigation?.enabled == true;

    if (!wasRegionEnabled && isRegionEnabled) {
      _regionManager = RegionNavigationManager(
        options: widget.regionNavigation!,
      );
    } else if (wasRegionEnabled && !isRegionEnabled) {
      _regionManager?.clear();
      _regionManager = null;
    } else if (isRegionEnabled &&
        widget.regionNavigation != oldWidget.regionNavigation) {
      // Update manager when options change
      _regionManager = RegionNavigationManager(
        options: widget.regionNavigation!,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _historyManager?.clear();
    _historyManager = null;
    _regionManager?.clear();
    _regionManager = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If navigation is disabled, just return the child as-is
    if (!widget.enabled) {
      return widget.child;
    }

    // Build the child widget tree
    Widget child = CallbackShortcuts(
      bindings: _buildBindings(),
      child: widget.child,
    );

    // Wrap with region traversal scope and FocusTraversalGroup if region navigation is enabled
    if (_regionManager != null && widget.regionNavigation?.enabled == true) {
      child = RegionTraversalGroupScope(
        regionManager: _regionManager,
        getLastFocusInRegion: _getLastFocusInRegion,
        child: FocusTraversalGroup(
          policy: RegionAwareFocusTraversalPolicy(
            regionManager: _regionManager,
            getLastFocusInRegion: _getLastFocusInRegion,
          ),
          child: child,
        ),
      );
    }

    // Wrap with Focus widget to handle key events
    // Note: We don't request focus here to let child widgets manage focus
    return _DpadNavigatorScope(
      focusMemory: widget.focusMemory,
      historyManager: _historyManager,
      regionManager: _regionManager,
      child: Focus(
        // Skip traversal to prevent this Focus from stealing focus
        skipTraversal: true,
        // Disable focus on this node - it should only handle key events
        canRequestFocus: false,
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
  /// This method uses Flutter's native focus traversal system with our
  /// custom [RegionAwareFocusTraversalPolicy] for region-based navigation.
  ///
  /// **Parameters:**
  /// - [direction]: The direction to navigate (up, down, left, right)
  void _navigate(TraversalDirection direction) {
    final currentFocus = FocusManager.instance.primaryFocus;

    // If no focus exists (e.g., after window regains focus), restore it first
    if (currentFocus == null || currentFocus.context == null) {
      _restoreFocusIfNeeded();
      return;
    }

    // Use Flutter's native focus navigation which will use our
    // RegionAwareFocusTraversalPolicy if a FocusTraversalGroup is set up
    final currentContext = currentFocus.context;
    if (currentContext != null) {
      // This will call FocusTraversalPolicy.inDirection which we override
      // in RegionAwareFocusTraversalPolicy to handle region-based navigation
      FocusScope.of(currentContext).focusInDirection(direction);
    }
  }

  /// Gets the last focused node in a specific region from history.
  FocusNode? _getLastFocusInRegion(String region) {
    if (_historyManager == null) return null;

    final entry = _historyManager!.getLastFocusInRegion(region);
    if (entry != null && entry.isValid) {
      return entry.focusNode;
    }
    return null;
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

    // If no focus exists, restore it first
    if (currentFocus == null || currentFocus.context == null) {
      _restoreFocusIfNeeded();
      return;
    }

    // Consume the keyboard token to trigger the selection action
    currentFocus.consumeKeyboardToken();
  }

  /// Navigates to the next widget in the focus traversal order.
  ///
  /// This method follows the logical focus order rather than spatial positioning,
  /// making it ideal for sequential navigation like media controls, lists,
  /// or form fields. Uses Flutter's native nextFocus() method.
  void _navigateNext() {
    final currentFocus = FocusManager.instance.primaryFocus;

    // If no focus exists, restore it first
    if (currentFocus == null || currentFocus.context == null) {
      _restoreFocusIfNeeded();
      return;
    }

    currentFocus.nextFocus();
  }

  /// Navigates to the previous widget in the focus traversal order.
  ///
  /// This method follows the logical focus order in reverse, making it ideal
  /// for sequential navigation like media controls, lists, or form fields.
  /// Uses Flutter's native previousFocus() method.
  void _navigatePrevious() {
    final currentFocus = FocusManager.instance.primaryFocus;

    // If no focus exists, restore it first
    if (currentFocus == null || currentFocus.context == null) {
      _restoreFocusIfNeeded();
      return;
    }

    currentFocus.previousFocus();
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
