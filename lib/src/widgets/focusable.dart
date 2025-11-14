import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../effects/focus_effects.dart';

/// A widget that makes any child widget focusable for D-pad navigation.
///
/// This is the core widget for creating focusable components in TV apps.
class DpadFocusable extends StatefulWidget {
  /// The child widget that will be wrapped with focus capabilities.
  final Widget child;

  /// Whether this widget should automatically request focus when first built.
  final bool autofocus;

  /// Callback function triggered when the widget gains focus.
  final VoidCallback? onFocus;

  /// Callback function triggered when the widget loses focus.
  final VoidCallback? onBlur;

  /// Callback function triggered when the widget is selected.
  final VoidCallback? onSelect;

  /// Whether this widget can receive focus.
  final bool enabled;

  /// Debug label for the focus node.
  final String? debugLabel;

  /// Builder function for creating custom focus effects.
  final FocusEffectBuilder? builder;

  const DpadFocusable({
    super.key,
    required this.child,
    this.autofocus = false,
    this.onFocus,
    this.onBlur,
    this.onSelect,
    this.enabled = true,
    this.debugLabel,
    this.builder,
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
    } else {
      widget.onBlur?.call();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

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

    // Default effect: simple border
    return FocusEffects.border()(context, _focusNode.hasFocus, widget.child);
  }

  bool _isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA;
  }
}
