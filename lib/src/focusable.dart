import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'effects.dart';
import 'key_set.dart';
import 'marks.dart';
import 'region.dart';
import 'root.dart';
import 'scroll.dart';
import 'theme.dart';

/// Signature for building a fully custom focus presentation for a
/// [DpadFocusable].
typedef DpadFocusableBuilder = Widget Function(
  BuildContext context,
  DpadFocusState state,
  Widget child,
);

/// Signature for intercepting directional key presses on a focused item.
///
/// Return `true` to consume the key press (focus will not move); return
/// `false` to let normal d-pad navigation happen.
typedef DpadDirectionCallback = bool Function(TraversalDirection direction);

/// Makes [child] a TV focus target: navigable with the d-pad, selectable
/// with the remote's center button, and decorated with focus effects.
///
/// The minimal form is all most items need:
///
/// ```dart
/// DpadFocusable(
///   onSelect: () => playMovie(movie),
///   child: PosterCard(movie),
/// )
/// ```
///
/// ### Visuals
///
/// By default the item uses the effects from the nearest [DpadTheme]
/// (a scale + border by default). Override per item with [effects], or take
/// full control with [builder], which receives the live [DpadFocusState]
/// including the pressed state of the select key.
///
/// ### Interaction
///
/// * [onSelect] — center button pressed (or tapped on touch devices).
/// * [onLongSelect] — center button held; great for context menus.
/// * [onDirection] — intercept arrows while focused, e.g. to implement a
///   value slider that consumes left/right.
///
/// ### Inside a [DpadRegion]
///
/// Items report themselves to their region's focus memory automatically.
/// Mark one item per region with [entry] to make it the landing target for
/// [DpadEnterBehavior.entry] (and the fallback for
/// [DpadEnterBehavior.restore]).
///
/// ### One widget, one focus target
///
/// Descendant focus is excluded by default ([excludeChildFocus]), so
/// wrapping a `Card`, `Image` or even a Material button never produces two
/// stops on the d-pad path. Wire behavior through [onSelect] instead of the
/// child's `onPressed`. Set [excludeChildFocus] to `false` when the child
/// must manage its own focus (e.g. a `TextField`).
class DpadFocusable extends StatefulWidget {
  /// Creates a TV focus target around [child].
  const DpadFocusable({
    super.key,
    required this.child,
    this.effects,
    this.builder,
    this.onSelect,
    this.onLongSelect,
    this.onFocusChange,
    this.onDirection,
    this.autofocus = false,
    this.enabled = true,
    this.entry = false,
    this.focusNode,
    this.debugLabel,
    this.autoScroll = true,
    this.scrollPadding,
    this.scrollDuration,
    this.scrollCurve,
    this.excludeChildFocus = true,
    this.tapToSelect = true,
  }) : assert(
          effects == null || builder == null,
          'Provide either effects or builder, not both.',
        );

  /// The content to make focusable.
  final Widget child;

  /// Focus effects for this item, first effect outermost.
  ///
  /// When null (and [builder] is null) the [DpadThemeData.effects] apply.
  final List<DpadEffect>? effects;

  /// Builds a fully custom presentation from the live [DpadFocusState].
  /// Mutually exclusive with [effects].
  final DpadFocusableBuilder? builder;

  /// Called when the user presses the select key (or taps the item).
  final VoidCallback? onSelect;

  /// Called when the user holds the select key for
  /// [DpadThemeData.longSelectDuration] (or long-presses the item).
  ///
  /// When provided, [onSelect] fires on key release instead of key press so
  /// the two gestures never overlap.
  final VoidCallback? onLongSelect;

  /// Called with `true` when the item gains focus and `false` when it
  /// loses focus.
  final ValueChanged<bool>? onFocusChange;

  /// Intercepts directional keys while this item is focused. Return `true`
  /// to consume the press. Repeats (held keys) are delivered too.
  final DpadDirectionCallback? onDirection;

  /// Whether this item grabs focus when it first appears.
  ///
  /// Give exactly one item per screen `autofocus: true` so a remote-only
  /// user always has a visible starting point.
  final bool autofocus;

  /// Whether the item can be focused. Disabled items are skipped by
  /// navigation entirely.
  final bool enabled;

  /// Marks this item as its region's entry target. See
  /// [DpadEnterBehavior.entry]. One per region.
  final bool entry;

  /// An external focus node to use instead of the internal one.
  final FocusNode? focusNode;

  /// A label shown in focus debug output.
  final String? debugLabel;

  /// Whether gaining focus auto-scrolls the item into view with padding for
  /// its focus effects. Defaults to `true`.
  final bool autoScroll;

  /// Viewport padding for auto-scroll. Defaults to
  /// [DpadThemeData.scrollPadding].
  final double? scrollPadding;

  /// Auto-scroll animation duration. Defaults to
  /// [DpadThemeData.scrollDuration].
  final Duration? scrollDuration;

  /// Auto-scroll animation curve. Defaults to [DpadThemeData.scrollCurve].
  final Curve? scrollCurve;

  /// Whether descendants are removed from the focus tree so this widget is
  /// a single d-pad stop. Defaults to `true`.
  final bool excludeChildFocus;

  /// Whether taps focus the item and trigger [onSelect], for hybrid
  /// touch/pointer devices and desktop debugging. Defaults to `true`.
  final bool tapToSelect;

  @override
  State<DpadFocusable> createState() => _DpadFocusableState();
}

class _DpadFocusableState extends State<DpadFocusable> {
  FocusNode? _internalNode;
  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  DpadRegionState? _region;
  bool _focused = false;
  bool _pressed = false;
  bool _selectKeyDown = false;
  bool _longSelectFired = false;
  Timer? _longSelectTimer;

  @override
  void initState() {
    super.initState();
    _mark(_node);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _region = DpadRegion.maybeOf(context);
  }

  @override
  void didUpdateWidget(DpadFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _unmark(oldWidget.focusNode ?? _internalNode);
      _mark(_node);
    } else {
      if (oldWidget.entry != widget.entry) {
        DpadMarks.entry[_node] = widget.entry ? true : null;
      }
      if (oldWidget.debugLabel != widget.debugLabel) {
        _node.debugLabel = widget.debugLabel;
      }
    }
  }

  void _mark(FocusNode node) {
    DpadMarks.managed[node] = true;
    DpadMarks.entry[node] = widget.entry ? true : null;
    if (widget.debugLabel != null) {
      node.debugLabel = widget.debugLabel;
    }
  }

  void _unmark(FocusNode? node) {
    if (node == null) {
      return;
    }
    DpadMarks.managed[node] = null;
    DpadMarks.entry[node] = null;
  }

  @override
  void dispose() {
    _longSelectTimer?.cancel();
    final FocusNode? internal = _internalNode;
    final FocusNode? node = widget.focusNode ?? internal;
    if (node != null) {
      _region?.forget(node);
    }
    _unmark(widget.focusNode);
    if (internal != null) {
      _unmark(internal);
      internal.dispose();
    }
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Selection
  // -----------------------------------------------------------------------

  void _handleSelect() {
    if (!widget.enabled) {
      return;
    }
    widget.onSelect?.call();
  }

  void _handleLongSelect() {
    _longSelectFired = true;
    widget.onLongSelect?.call();
  }

  void _startPress() {
    _longSelectFired = false;
    _setPressed(true);
    if (widget.onLongSelect != null) {
      _longSelectTimer?.cancel();
      _longSelectTimer = Timer(
        DpadTheme.of(context).longSelectDuration,
        _handleLongSelect,
      );
    }
  }

  void _endPress({required bool canceled}) {
    _longSelectTimer?.cancel();
    _longSelectTimer = null;
    _setPressed(false);
    if (canceled || _longSelectFired) {
      return;
    }
    // With a long-select handler, select fires on release; without one it
    // already fired on press.
    if (widget.onLongSelect != null) {
      _handleSelect();
    }
  }

  void _setPressed(bool value) {
    if (_pressed != value && mounted) {
      setState(() => _pressed = value);
    } else {
      _pressed = value;
    }
  }

  // -----------------------------------------------------------------------
  // Keys
  // -----------------------------------------------------------------------

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final DpadKeySet keys = Dpad.keySetOf(context);
    final LogicalKeyboardKey key = event.logicalKey;

    if (keys.isSelect(key)) {
      return _handleSelectKey(event);
    }

    final TraversalDirection? direction = keys.directionOf(key);
    if (direction != null &&
        widget.onDirection != null &&
        event is! KeyUpEvent) {
      if (widget.onDirection!(direction)) {
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleSelectKey(KeyEvent event) {
    if (!widget.enabled) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      _selectKeyDown = true;
      _startPress();
      if (widget.onLongSelect == null) {
        _handleSelect();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) {
      // Swallow repeats so a held select key never machine-guns onSelect.
      return _selectKeyDown ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    if (event is KeyUpEvent) {
      if (!_selectKeyDown) {
        // The matching key-down happened on another widget.
        return KeyEventResult.ignored;
      }
      _selectKeyDown = false;
      _endPress(canceled: false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // -----------------------------------------------------------------------
  // Focus
  // -----------------------------------------------------------------------

  void _handleFocusChange(bool focused) {
    if (!mounted) {
      return;
    }
    setState(() => _focused = focused);
    if (focused) {
      _region?.noteFocus(_node);
      if (widget.autoScroll) {
        final DpadThemeData theme = DpadTheme.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _node.hasFocus) {
            DpadScroll.ensureVisible(
              _node,
              padding: widget.scrollPadding ?? theme.scrollPadding,
              duration: widget.scrollDuration ?? theme.scrollDuration,
              curve: widget.scrollCurve ?? theme.scrollCurve,
            );
          }
        });
      }
    } else {
      _selectKeyDown = false;
      _longSelectTimer?.cancel();
      _setPressed(false);
    }
    widget.onFocusChange?.call(focused);
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final DpadFocusState state =
        DpadFocusState(focused: _focused, pressed: _pressed);

    Widget content = widget.child;
    if (widget.excludeChildFocus) {
      content = ExcludeFocus(child: content);
    }

    if (widget.builder != null) {
      content = widget.builder!(context, state, content);
    } else {
      content = DpadEffect.wrap(
        context,
        widget.effects ?? DpadTheme.of(context).effects,
        state,
        content,
      );
    }

    if (widget.tapToSelect) {
      content = MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled
              ? (TapDownDetails details) {
                  _node.requestFocus();
                  _startPress();
                }
              : null,
          onTapUp: widget.enabled
              ? (TapUpDetails details) => _endPress(canceled: false)
              : null,
          onTapCancel: widget.enabled ? () => _endPress(canceled: true) : null,
          onTap: widget.enabled && widget.onLongSelect == null
              ? _handleSelect
              : null,
          child: content,
        ),
      );
    }

    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            _handleSelect();
            return null;
          },
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (ButtonActivateIntent intent) {
            _handleSelect();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: _node,
        autofocus: widget.autofocus,
        canRequestFocus: widget.enabled,
        onKeyEvent: _handleKeyEvent,
        onFocusChange: _handleFocusChange,
        child: content,
      ),
    );
  }
}
