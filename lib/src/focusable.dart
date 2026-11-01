import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'effects.dart';
import 'highlight.dart';
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
/// ### Accessibility
///
/// Every self-contained focusable (the default, [excludeChildFocus])
/// announces as a [Semantics] button, and assistive activation works
/// everywhere the remote does — as long as the child does not expose its
/// own button/tap semantics: a screen reader's tap (TalkBack double-tap,
/// VoiceOver default action) fires [onSelect] and focuses the item, a
/// long-press fires [onLongSelect]. An interactive child (a Material
/// button, a wrapped text field) keeps its own semantics node, label and
/// activation, so the reader reaches the child's callback first — wire
/// that callback to the same behavior, or wrap the child in
/// `ExcludeSemantics` and give the item a [semanticLabel] so the wrapper
/// is the single node. With `excludeChildFocus: false` the child's role
/// stays authoritative and the wrapper still contributes its
/// `onSelect`/`onLongSelect` activation when provided. Give image-only
/// items a spoken name with [semanticLabel].
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
    this.highlight,
    this.focusNode,
    this.debugLabel,
    this.semanticLabel,
    this.autoScroll = true,
    this.scrollPadding,
    this.scrollDuration,
    this.scrollCurve,
    this.scrollAlignment,
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

  /// The flying-highlight configuration for this item.
  ///
  /// Overrides the nearest [DpadHighlightTheme] and the [Dpad] root's
  /// [Dpad.highlight] — pass [DpadHighlight.none] to keep the flying
  /// highlight off this item entirely (for items that draw their own focus
  /// presentation). `null` (the default) inherits.
  ///
  /// Like a [DpadHighlightTheme], the override re-resolves when focus
  /// moves — changing it while its own item stays focused applies on the
  /// next focus change.
  final DpadHighlight? highlight;

  /// An external focus node to use instead of the internal one.
  ///
  /// The node stays owned by the caller: the widget attaches and detaches
  /// but never disposes it. When null, an internal node is created and
  /// disposed with the widget's state.
  final FocusNode? focusNode;

  /// A label shown in focus debug output.
  final String? debugLabel;

  /// The accessibility label screen readers announce for this item.
  ///
  /// When null (the default), the semantics tree falls through to the
  /// child's own — usually its text. Set it when the visuals alone carry
  /// the meaning (a poster image, an icon tile):
  ///
  /// ```dart
  /// DpadFocusable(
  ///   semanticLabel: movie.title,
  ///   onSelect: () => play(movie),
  ///   child: PosterImage(movie),
  /// )
  /// ```
  ///
  /// The label composes with, not replaces, the child's own text — an
  /// explicit label is announced ahead of it. Skip it when the child
  /// already says the same thing.
  final String? semanticLabel;

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

  /// How the auto-scroll places this item along each scrollable's axis.
  /// Defaults to [DpadThemeData.scrollAlignment]. See
  /// [DpadRevealAlignment] for the two placements.
  final DpadRevealAlignment? scrollAlignment;

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
  Timer? _pressPulseTimer;

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
      final FocusNode? old = oldWidget.focusNode ?? _internalNode;
      if (old != null) {
        // The region's memory must not restore focus to a node this
        // widget no longer owns.
        _region?.forget(old);
      }
      _unmark(old);
      _mark(_node);
    } else {
      if (oldWidget.entry != widget.entry) {
        DpadMarks.entry[_node] = widget.entry ? true : null;
      }
      if (oldWidget.highlight != widget.highlight) {
        DpadMarks.highlightStyle[_node] = widget.highlight;
      }
      if (oldWidget.debugLabel != widget.debugLabel) {
        // Assign through — clearing back to null must not leave the old
        // label behind.
        _node.debugLabel = widget.debugLabel;
      }
    }
  }

  void _mark(FocusNode node) {
    DpadMarks.managed[node] = true;
    DpadMarks.entry[node] = widget.entry ? true : null;
    DpadMarks.highlightStyle[node] = widget.highlight;
    DpadMarks.pressPulse[node] = _pulsePress;
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
    DpadMarks.highlightStyle[node] = null;
    DpadMarks.pressPulse[node] = null;
    DpadMarks.visualScale[node] = null;
    DpadMarks.pressed[node] = null;
  }

  @override
  void dispose() {
    _longSelectTimer?.cancel();
    _pressPulseTimer?.cancel();
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
    // A real press takes the visuals over from a pulse still in flight.
    _pressPulseTimer?.cancel();
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
    _pressPulseTimer?.cancel();
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
    // Mirror the press onto the node so the flying highlight (and anything
    // else tracking it) sees it, and wake the highlight so effects reading
    // DpadHighlightState.pressed repaint.
    DpadMarks.pressed[_node] = value;
    highlightHostOf(context)?.wake();
    if (_pressed != value && mounted) {
      setState(() => _pressed = value);
    } else {
      _pressed = value;
    }
  }

  // -----------------------------------------------------------------------
  // Keys
  // -----------------------------------------------------------------------

  /// The programmatic press pulse: pressed visuals on, then off after a
  /// beat. Fired by [DpadController.select] so a voice-remote or scripted
  /// activation looks like a real key press — without arming the
  /// long-select timer (the activation already dispatched).
  void _pulsePress() {
    // A held select key owns the visuals until its key-up.
    if (!mounted || !widget.enabled || _selectKeyDown) {
      return;
    }
    _setPressed(true);
    _pressPulseTimer?.cancel();
    _pressPulseTimer = Timer(DpadController.selectPulseDuration, () {
      if (mounted) {
        _setPressed(false);
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // A descendant holds primary focus (`excludeChildFocus: false`
    // wrapping a text field): the keys belong to it. Claiming select here
    // would eat spaces and enters mid-sentence; claiming directions would
    // trap the caret. The keys bubble on — the root's text-field contract
    // is what eventually lets arrows leave the field.
    if (!identical(FocusManager.instance.primaryFocus, node)) {
      return KeyEventResult.ignored;
    }
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
      // A select fires once per press, so repeats are always swallowed —
      // including repeats landing on an item that never saw the key-down,
      // because whatever did moved focus away (a pushed route, a dialog, a
      // plain button's onPressed requesting focus).
      return KeyEventResult.handled;
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
            // Reduced motion (the platform's accessibility setting): jump
            // instead of animating the reveal.
            final bool reduceMotion =
                MediaQuery.maybeOf(context)?.disableAnimations ?? false;
            DpadScroll.ensureVisible(
              _node,
              padding: widget.scrollPadding ?? theme.scrollPadding,
              duration: reduceMotion
                  ? Duration.zero
                  : widget.scrollDuration ?? theme.scrollDuration,
              curve: widget.scrollCurve ?? theme.scrollCurve,
              alignment: widget.scrollAlignment ?? theme.scrollAlignment,
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

    final List<DpadEffect>? effects = widget.builder == null
        ? (widget.effects ?? DpadTheme.of(context).effects)
        : null;
    if (widget.builder != null) {
      content = widget.builder!(context, state, content);
    } else {
      content = DpadEffect.wrap(context, effects!, state, content);
    }
    // Record the steady-state focused scale so the flying highlight frames
    // the scaled visual instead of the un-scaled layout rect (custom
    // builders draw their own presentation; theirs stays 1.0).
    double visualScale = 1.0;
    for (final DpadEffect effect in effects ?? const <DpadEffect>[]) {
      if (effect is DpadScaleEffect) {
        visualScale *= effect.scale;
      }
    }
    DpadMarks.visualScale[_node] = visualScale == 1.0 ? null : visualScale;

    // Assistive activation. The semantics wrapper below owns ALL of it —
    // the gesture detector above stands down from semantics entirely
    // (`excludeFromSemantics`), so there is exactly one activate path
    // regardless of how the tap/long-select/keyboard pipelines overlap.
    // Activation also focuses the item, like the touch path's tap-down.
    content = Semantics(
      // Only a self-contained stop reads as a button; with a wrapped inner
      // focus target (excludeChildFocus: false, e.g. a text field) the
      // child's own role must stay authoritative.
      button: widget.excludeChildFocus,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      onTap: widget.enabled && widget.onSelect != null
          ? () {
              _node.requestFocus();
              // The same visible beat a real key press or tap produces.
              _pulsePress();
              _handleSelect();
            }
          : null,
      onLongPress: widget.enabled && widget.onLongSelect != null
          ? () {
              _node.requestFocus();
              _pulsePress();
              _handleLongSelect();
            }
          : null,
      child: content,
    );

    if (widget.tapToSelect) {
      content = MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          // Assistive activation goes through the Semantics wrapper above,
          // never this detector's own synthesized tap.
          excludeFromSemantics: true,
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
