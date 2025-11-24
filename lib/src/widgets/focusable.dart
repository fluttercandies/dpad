import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dpad.dart';

/// A widget that makes any child widget focusable for D-pad navigation.
///
/// This is the core widget for creating focusable components in TV apps.
/// It wraps any widget with focus management capabilities, allowing it to respond
/// to D-pad navigation, selection events, and focus state changes.
///
/// **Example Usage:**
/// ```dart
/// DpadFocusable(
///   autofocus: true,
///   onFocus: () => print('Got focus'),
///   onBlur: () => print('Lost focus'),
///   onSelect: () => print('Selected'),
///   builder: (context, isFocused, child) {
///     return AnimatedContainer(
///       duration: Duration(milliseconds: 200),
///       decoration: BoxDecoration(
///         border: Border.all(
///           color: isFocused ? Colors.blue : Colors.transparent,
///           width: 3,
///         ),
///         borderRadius: BorderRadius.circular(8),
///       ),
///       child: child,
///     );
///   },
///   child: ElevatedButton(
///     onPressed: () => print('Button pressed'),
///     child: Text('Focusable Button'),
///   ),
/// )
/// ```
///
/// **Key Features:**
/// - Seamless integration with Flutter's focus system
/// - Custom focus effects through builder pattern
/// - Automatic focus management
/// - Support for multiple selection keys
/// - Debug capabilities with labels
/// - Enable/disable focus capabilities
class DpadFocusable extends StatefulWidget {
  /// The child widget that will be wrapped with focus capabilities.
  ///
  /// This can be any Flutter widget that you want to make focusable,
  /// such as buttons, containers, cards, list items, etc.
  final Widget? child;

  /// Whether this widget should automatically request focus when first built.
  ///
  /// Set to `true` to give this widget initial focus when it appears.
  /// This is useful for ensuring there's always a focused widget on each screen.
  /// Only one widget per screen should have `autofocus: true`.
  ///
  /// Defaults to `false`.
  final bool autofocus;

  /// Callback function triggered when the widget gains focus.
  ///
  /// This is called when the widget becomes the currently focused element
  /// through D-pad navigation or programmatic focus changes.
  /// Use this to update UI, show focus indicators, or trigger animations.
  final VoidCallback? onFocus;

  /// Callback function triggered when the widget loses focus.
  ///
  /// This is called when focus moves away from this widget to another element.
  /// Use this to hide focus indicators, stop animations, or reset UI state.
  final VoidCallback? onBlur;

  /// Callback function triggered when the widget is selected.
  ///
  /// This is called when the user presses a selection key (Enter, Space, Select, A)
  /// while this widget has focus. This is different from the widget's own
  /// `onPressed` or `onTap` callbacks - it's specifically for D-pad selection.
  final VoidCallback? onSelect;

  /// Whether this widget can receive focus.
  ///
  /// When set to `false`, the widget will not be focusable and will be
  /// ignored by D-pad navigation. This can be used to temporarily disable
  /// focus capabilities without removing the widget from the widget tree.
  ///
  /// Defaults to `true`.
  final bool enabled;

  /// Debug label for the focus node.
  ///
  /// This label appears in Flutter's focus debugging tools and can help
  /// identify specific focusable widgets during development and debugging.
  ///
  /// **Example:** `debugLabel: 'LoginButton'`
  final String? debugLabel;

  /// Builder function for creating custom focus effects.
  ///
  /// Use this to create completely custom focus appearances and animations.
  /// The builder provides the current focus state and allows you to wrap
  /// the child widget with any focus effect you can imagine.
  ///
  /// **Signature:** `Widget Function(BuildContext context, bool isFocused, Widget? child)`
  ///
  /// **Example:**
  /// ```dart
  /// builder: (context, isFocused, child) {
  ///   return Transform.scale(
  ///     scale: isFocused ? 1.1 : 1.0,
  ///     child: child ?? AnimatedContainer(
  ///       duration: Duration(milliseconds: 200),
  ///       decoration: BoxDecoration(
  ///         boxShadow: isFocused ? [
  ///           BoxShadow(color: Colors.blue, blurRadius: 10)
  ///         ] : null,
  ///       ),
  ///       child: child,
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// If not provided, a simple border effect will be used.
  final FocusEffectBuilder? builder;

  /// Region identifier.
  ///
  /// Used to identify different functional areas, e.g., 'tabs', 'filters', 'cards'
  /// Used for region identification and restoration in focus memory.
  final String? region;

  /// Creates a [DpadFocusable] widget.
  ///
  /// Either [child] or [builder] must be provided.
  /// When neither is provided, an assertion error will be thrown at build time.
  const DpadFocusable({
    super.key,
    this.child,
    this.autofocus = false,
    this.onFocus,
    this.onBlur,
    this.onSelect,
    this.enabled = true,
    this.debugLabel,
    this.builder,
    this.region,
  });

  @override
  State<DpadFocusable> createState() => _DpadFocusableState();
}

class _DpadFocusableState extends State<DpadFocusable> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      canRequestFocus: widget.enabled,
      skipTraversal: false,
      debugLabel: widget.debugLabel,
    );

    _focusNode.addListener(_onFocusChange);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          // Record initial focus to history
          _recordFocusToHistory();
        }
      });
    }
  }

  @override
  void didUpdateWidget(DpadFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled != widget.enabled) {
      _focusNode.canRequestFocus = widget.enabled;
    }

    if (oldWidget.debugLabel != widget.debugLabel) {
      _focusNode.debugLabel = widget.debugLabel;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);

    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }

    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;

    if (_focusNode.hasFocus) {
      widget.onFocus?.call();

      // Record focus to history stack (if enabled)
      _recordFocusToHistory();
    } else {
      widget.onBlur?.call();
    }
    setState(() {});
  }

  /// Records focus to history stack.
  void _recordFocusToHistory() {
    final navigator = _findNavigator(context);
    if (navigator == null) return;
    final memory = navigator.focusMemory;
    if (memory == null || !memory.enabled) {
      return;
    }

    // Check if this region should be tracked
    if (memory.shouldTrackRegion(widget.region)) {
      final routeName = ModalRoute.of(context)?.settings.name ?? 
                      memory.defaultRoute ?? 
                      'default_route';

      FocusHistory.push(FocusHistoryEntry(
        focusNode: _focusNode,
        region: widget.region,
        routeName: routeName,
        debugLabel: widget.debugLabel,
      ));
    }
  }

  /// Finds the nearest DpadNavigator widget.
  DpadNavigator? _findNavigator(BuildContext context) {
    try {
      DpadNavigator? navigator;
      context.visitAncestorElements((ancestor) {
        if (ancestor.widget is DpadNavigator) {
          navigator = ancestor.widget as DpadNavigator;
          return false; // Stop traversing
        }
        return true; // Continue traversing
      });
      return navigator;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && _isSelectKey(event.logicalKey)) {
          widget.onSelect?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: _buildWithFocus(context),
    );
  }

  Widget _buildWithFocus(BuildContext context) {
    // Use custom builder if provided
    if (widget.builder != null) {
      return widget.builder!(context, _focusNode.hasFocus, widget.child);
    }

    // 无builder时，child必须存在
    assert(widget.child != null, 'DpadFocusable: child must be provided when builder is null.');
    return FocusEffects.border()(context, _focusNode.hasFocus, widget.child!);
  }

  bool _isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA;
  }
}
