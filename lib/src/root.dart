import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'key_set.dart';
import 'marks.dart';
import 'region.dart';
import 'scroll.dart';
import 'theme.dart';
import 'traversal.dart';

/// The root of the d-pad system.
///
/// Place one [Dpad] above your pages — the recommended spot is
/// [WidgetsApp.builder] / `MaterialApp.builder`, so every route, dialog and
/// overlay is covered:
///
/// ```dart
/// MaterialApp(
///   builder: Dpad.wrap(),
///   home: const HomePage(),
/// )
/// ```
///
/// [Dpad] provides:
///
/// * **TV-correct directional navigation** for the whole subtree, via
///   [DpadTraversalPolicy]. Works with arrow keys, remote d-pads and game
///   controllers on every platform (including web, where Flutter does not
///   map arrows to focus by default).
/// * **Remote key semantics** — back and menu callbacks, plus app-level
///   [shortcuts]. All of them automatically stand down while a text field
///   is being edited, so typing is never hijacked.
/// * **Focus resilience** — when the focused widget disappears (a list
///   refreshes, a dialog closes) or the app resumes from background, focus
///   is restored to the nearest sensible item instead of being lost, which
///   would otherwise leave the remote dead.
/// * **Programmatic control** through [Dpad.of]: `Dpad.of(context).moveDown()`,
///   `.select()`, `.requestFocus(...)` and friends.
///
/// Styling defaults for all [DpadFocusable]s live in [theme].
class Dpad extends StatefulWidget {
  /// Creates the d-pad root around [child].
  const Dpad({
    super.key,
    required this.child,
    this.enabled = true,
    this.keySet = const DpadKeySet(),
    this.theme,
    this.onBack,
    this.onMenu,
    this.onFocusChange,
    this.shortcuts = const <LogicalKeyboardKey, VoidCallback>{},
    this.restoreFocus = true,
    this.debugOverlay = false,
  });

  /// The subtree to control. Usually the app's `Navigator` (via
  /// `MaterialApp.builder`) or the whole `MaterialApp`.
  final Widget child;

  /// Freezes remote navigation — the playback-overlay pattern: while
  /// `false`, arrow keys are consumed without moving focus (so nothing
  /// behind [Dpad] can steal them either), back/menu keys and [shortcuts]
  /// stand down, and [DpadController.move] calls do nothing. While a text
  /// field holds focus the arrows fall through to normal caret editing —
  /// which consumes them too, so focus still never moves. Select keys
  /// keep working on the focused [DpadFocusable], which is what lets a
  /// frozen UI (an on-screen toggle, a "press OK to resume" hint) turn
  /// navigation back on.
  final bool enabled;

  /// The remote-key mapping. See [DpadKeySet].
  final DpadKeySet keySet;

  /// Default styling and timing for descendant [DpadFocusable]s.
  final DpadThemeData? theme;

  /// Called when a back key ([DpadKeySet.back]) is pressed.
  ///
  /// Suspended automatically while a text field is focused (the IME owns
  /// the keys) and while [enabled] is `false`.
  ///
  /// Return `true` to consume the press. Return `false` to let the
  /// framework continue (dismissing dialogs, popping routes on platforms
  /// that deliver back as a key event). When null, back keys are not
  /// intercepted at all.
  final bool Function()? onBack;

  /// Called when a menu key ([DpadKeySet.menu]) is pressed.
  ///
  /// Suspended automatically while a text field is focused (the IME owns
  /// the keys) and while [enabled] is `false`.
  final VoidCallback? onMenu;

  /// Called on every focus change with the newly focused node (or `null`
  /// when nothing real is focused).
  ///
  /// The natural place for the app-wide focus "tick" sound, haptics or
  /// analytics:
  ///
  /// ```dart
  /// Dpad.wrap(
  ///   onFocusChange: (node) {
  ///     if (node != null) audio.playTick();
  ///   },
  /// )
  /// ```
  final ValueChanged<FocusNode?>? onFocusChange;

  /// App-level key shortcuts, e.g. a search key or color buttons.
  ///
  /// Suspended automatically while a text field is focused.
  final Map<LogicalKeyboardKey, VoidCallback> shortcuts;

  /// Whether the d-pad system keeps focus alive on its own. Defaults to
  /// `true`, which guarantees:
  ///
  /// * the app starts with something focused (an `autofocus` item wins);
  /// * a route pushed without `autofocus` still receives an initial focus;
  /// * disposing the focused widget moves focus to its nearest surviving
  ///   neighbor;
  /// * resuming from background restores the previous focus.
  final bool restoreFocus;

  /// Paints a developer overlay outlining the focused node with its label
  /// and geometry — focus bugs on TV are invisible without it.
  ///
  /// Enable it for debug builds only:
  ///
  /// ```dart
  /// Dpad.wrap(debugOverlay: kDebugMode)
  /// ```
  final bool debugOverlay;

  /// The [DpadController] of the closest [Dpad] ancestor.
  static DpadController of(BuildContext context) {
    final DpadController? controller = maybeOf(context);
    assert(
      controller != null,
      'Dpad.of() called with a context that has no Dpad ancestor.\n'
      'Install one with MaterialApp(builder: Dpad.wrap()) or by wrapping '
      'your page tree in a Dpad widget.',
    );
    return controller!;
  }

  /// The [DpadController] of the closest [Dpad] ancestor, if any.
  static DpadController? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_DpadScope>()?.controller;
  }

  /// The active [DpadKeySet] for [context], falling back to the defaults
  /// when no [Dpad] ancestor exists.
  static DpadKeySet keySetOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_DpadScope>()?.keySet ??
        const DpadKeySet();
  }

  /// Convenience for installing [Dpad] through `MaterialApp.builder`:
  ///
  /// ```dart
  /// MaterialApp(
  ///   builder: Dpad.wrap(theme: const DpadThemeData(...)),
  ///   home: const HomePage(),
  /// )
  /// ```
  static TransitionBuilder wrap({
    bool enabled = true,
    DpadKeySet keySet = const DpadKeySet(),
    DpadThemeData? theme,
    bool Function()? onBack,
    VoidCallback? onMenu,
    ValueChanged<FocusNode?>? onFocusChange,
    Map<LogicalKeyboardKey, VoidCallback> shortcuts =
        const <LogicalKeyboardKey, VoidCallback>{},
    bool restoreFocus = true,
    bool debugOverlay = false,
  }) {
    return (BuildContext context, Widget? child) {
      return Dpad(
        enabled: enabled,
        keySet: keySet,
        theme: theme,
        onBack: onBack,
        onMenu: onMenu,
        onFocusChange: onFocusChange,
        shortcuts: shortcuts,
        restoreFocus: restoreFocus,
        debugOverlay: debugOverlay,
        child: child ?? const SizedBox.shrink(),
      );
    };
  }

  @override
  State<Dpad> createState() => _DpadState();
}

class _DpadState extends State<Dpad> with WidgetsBindingObserver {
  late final DpadController _controller = DpadController._(this);
  final DpadTraversalPolicy _policy = DpadTraversalPolicy();

  FocusNode? _lastFocus;
  Rect? _lastRect;
  bool _restoreScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_handleGlobalFocusChange);
    // A TV app must always have a visible focus, even before the first key
    // press; otherwise remote events have no anchor to dispatch through.
    _scheduleRestore(resumed: true);
  }

  @override
  void didUpdateWidget(Dpad oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A freeze must stop any wrap rewind still in flight — its per-hop
    // focus grabs would keep moving focus while frozen; re-enabling must
    // not resurrect an old chain either. A fresh press starts a new one.
    if (oldWidget.enabled != widget.enabled) {
      DpadTraversalPolicy.invalidateRewinds();
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleGlobalFocusChange);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Focus resilience
  // -----------------------------------------------------------------------

  void _handleGlobalFocusChange() {
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary is! FocusScopeNode) {
      _lastFocus = primary;
      _lastRect = DpadMarks.rectOf(primary) ?? _lastRect;
      widget.onFocusChange?.call(primary);
      return;
    }
    widget.onFocusChange?.call(null);
    if (widget.restoreFocus && widget.enabled) {
      _scheduleRestore();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed &&
        widget.restoreFocus &&
        widget.enabled) {
      _scheduleRestore(resumed: true);
    }
  }

  void _scheduleRestore({bool resumed = false}) {
    if (_restoreScheduled) {
      return;
    }
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The microtask hop lets pending `autofocus` and explicit focus
      // requests settle first, so they always win over the fallback.
      scheduleMicrotask(() {
        _restoreScheduled = false;
        if (mounted && widget.enabled && widget.restoreFocus) {
          _restoreFocus(resumed: resumed);
        }
      });
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _restoreFocus({required bool resumed}) {
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary is! FocusScopeNode) {
      return; // Something real took focus in the meantime.
    }
    final FocusScopeNode scope =
        primary is FocusScopeNode ? primary : FocusManager.instance.rootScope;

    final FocusNode? last = _lastFocus;
    final bool lastUsable = DpadMarks.isUsable(last);
    if (lastUsable) {
      if (resumed) {
        // Coming back from background: return to where the user was.
        DpadTraversalPolicy.invalidateRewinds();
        last!.requestFocus();
        return;
      }
      if (identical(last!.nearestScope, scope)) {
        // The unfocus was deliberate (e.g. dismissing a text field) —
        // leave it alone.
        return;
      }
      // A different scope holds focus with no focused child: a route was
      // pushed without an autofocus. Give it an initial focus below.
    }

    final List<FocusNode> candidates = scope.traversalDescendants.toList();
    if (candidates.isEmpty) {
      return;
    }

    FocusNode? target;
    // Only bias towards the old position when the focused widget actually
    // died in place (list refresh); for fresh scopes use the entry /
    // top-left item.
    final bool lastDetached = last != null && !lastUsable;
    final Rect? memory = _lastRect;
    if (lastDetached && memory != null) {
      double best = double.infinity;
      for (final FocusNode node in candidates) {
        final Rect? rect = DpadMarks.rectOf(node);
        if (rect == null) {
          continue;
        }
        final double distance = (rect.center - memory.center).distanceSquared;
        if (distance < best) {
          best = distance;
          target = node;
        }
      }
    }
    target ??= DpadMarks.initialCandidate(candidates) ?? candidates.first;
    // Recovery (list refresh, route pop) outranks in-flight rewind chains.
    DpadTraversalPolicy.invalidateRewinds();
    DpadRegion.ofNode(target)?.noteFocus(target);
    target.requestFocus();
  }

  // -----------------------------------------------------------------------
  // Key handling
  // -----------------------------------------------------------------------

  EditableTextState? get _focusedEditable {
    final BuildContext? focusContext =
        FocusManager.instance.primaryFocus?.context;
    if (focusContext == null || !focusContext.mounted) {
      return null;
    }
    return focusContext.findAncestorStateOfType<EditableTextState>();
  }

  bool get _keysActive => widget.enabled && _focusedEditable == null;

  static final Set<LogicalKeyboardKey> _physicalArrowKeys =
      <LogicalKeyboardKey>{
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
  };

  /// TV-correct arrow handling inside text fields: arrows edit the caret
  /// in the middle of text, but *leave* the field when there is nowhere
  /// left to go — otherwise a remote-only user is trapped in the field.
  ///
  /// Remapped movement keys (WASD) never claim this contract: they fall
  /// through while an editable is focused so the user can still type
  /// them.
  bool _directionAllowed(
    TraversalDirection direction, {
    required bool isArrowKey,
  }) {
    // While frozen the map stays installed and the action stays enabled —
    // the key is then consumed by [_move] without moving — because the
    // framework's own arrow shortcuts sit above and would otherwise keep
    // navigating with this same policy. One exception: while an editable
    // holds focus the action must stand down so the keys fall through to
    // caret editing — which also consumes them, so focus still never
    // moves.
    if (!widget.enabled) {
      return _focusedEditable == null;
    }
    final EditableTextState? editable = _focusedEditable;
    if (editable == null) {
      return true;
    }
    if (!isArrowKey) {
      return false;
    }
    final TextEditingValue value = editable.textEditingValue;
    if (value.composing.isValid) {
      return false; // The IME owns every key while composing.
    }
    final TextSelection selection = value.selection;
    switch (direction) {
      case TraversalDirection.up:
      case TraversalDirection.down:
        // Single-line fields have no vertical caret movement: navigate.
        if (editable.widget.maxLines == 1) {
          return true;
        }
        // Multiline fields keep vertical caret movement between lines;
        // escape only from the text's very start/end — the outer edge of
        // the first/last line — so a remote-only user is never trapped,
        // while inner-line arrows keep editing the caret.
        return selection.isValid &&
            selection.isCollapsed &&
            (direction == TraversalDirection.up
                ? selection.baseOffset <= 0
                : selection.baseOffset >= value.text.length);
      case TraversalDirection.left:
        return selection.isValid &&
            selection.isCollapsed &&
            selection.baseOffset <= 0;
      case TraversalDirection.right:
        return selection.isValid &&
            selection.isCollapsed &&
            selection.baseOffset >= value.text.length;
    }
  }

  bool _move(TraversalDirection direction) {
    // Frozen: the action stays enabled so the key press is still consumed
    // (the framework's default arrow shortcuts must not move focus), but a
    // programmatic caller learns the truth — nothing moved.
    if (!widget.enabled) {
      return false;
    }
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    if (primary == null || primary.context == null) {
      _restoreFocus(resumed: true);
      return true;
    }
    return primary.focusInDirection(direction);
  }

  Map<ShortcutActivator, Intent> _buildShortcuts() {
    final Map<ShortcutActivator, Intent> map = <ShortcutActivator, Intent>{};
    void mapDirection(List<LogicalKeyboardKey> keys, TraversalDirection d) {
      for (final LogicalKeyboardKey key in keys) {
        map[SingleActivator(key)] = _DpadDirectionalIntent(
          d,
          isArrowKey: _physicalArrowKeys.contains(key),
        );
      }
    }

    mapDirection(widget.keySet.up, TraversalDirection.up);
    mapDirection(widget.keySet.down, TraversalDirection.down);
    mapDirection(widget.keySet.left, TraversalDirection.left);
    mapDirection(widget.keySet.right, TraversalDirection.right);

    for (final LogicalKeyboardKey key in widget.keySet.back) {
      map[SingleActivator(key, includeRepeats: false)] =
          const _DpadBackIntent();
    }
    for (final LogicalKeyboardKey key in widget.keySet.menu) {
      map[SingleActivator(key, includeRepeats: false)] =
          const _DpadMenuIntent();
    }
    for (final MapEntry<LogicalKeyboardKey, VoidCallback> entry
        in widget.shortcuts.entries) {
      map[SingleActivator(entry.key, includeRepeats: false)] =
          _DpadCallbackIntent(entry.value);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    // The tree below is structurally identical for every configuration, so
    // flipping `enabled` or `debugOverlay` at runtime never reparents (and
    // thereby resets) the application subtree. Disabled branches are inert
    // instead of absent.
    return _DpadScope(
      controller: _controller,
      keySet: widget.keySet,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          DpadTheme(
            data: widget.theme ?? const DpadThemeData(),
            child: Actions(
              actions: <Type, Action<Intent>>{
                _DpadDirectionalIntent: _DpadDirectionalAction(this),
                _DpadBackIntent: _DpadBackAction(this),
                _DpadMenuIntent: _DpadMenuAction(this),
                _DpadCallbackIntent: _DpadCallbackAction(this),
              },
              child: Shortcuts(
                debugLabel: 'Dpad',
                // Always installed. While frozen, the directional actions
                // stay enabled and swallow the arrows (see [_move]) —
                // clearing the map would hand the keys to the framework's
                // own arrow shortcuts, which navigate with this very
                // policy; back/menu/shortcut intents simply stand down via
                // their enabled checks instead.
                shortcuts: _buildShortcuts(),
                child: FocusTraversalGroup(
                  policy: _policy,
                  child: widget.child,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: widget.debugOverlay
                ? const _DpadDebugOverlay()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DpadDebugOverlay extends StatefulWidget {
  const _DpadDebugOverlay();

  @override
  State<_DpadDebugOverlay> createState() => _DpadDebugOverlayState();
}

class _DpadDebugOverlayState extends State<_DpadDebugOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    // Repaint every frame: the focused rect moves during scrolling and
    // animations, not just on focus changes. Debug-tool overhead only.
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FocusNode? node = FocusManager.instance.primaryFocus;
    final Rect? rect = (node == null || node is FocusScopeNode)
        ? null
        : DpadMarks.rectOf(node);
    if (node == null || rect == null) {
      return const SizedBox.shrink();
    }
    final DpadRegionState? region = DpadRegion.ofNode(node);
    final String label = <String?>[
      node.debugLabel,
      if (region != null)
        'region: ${region.widget.debugLabel ?? region.hashCode}',
      '${rect.width.round()}×${rect.height.round()}',
    ].whereType<String>().join('  ·  ');

    return IgnorePointer(
      child: Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Positioned.fromRect(
            rect: rect.inflate(2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                border: Border.all(color: const Color(0xFFFF1744), width: 2),
              ),
            ),
          ),
          Positioned(
            left: rect.left,
            top: rect.bottom + 6,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xDD000000),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  label,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: Color(0xFFFF8A80),
                    fontSize: 11,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DpadScope extends InheritedWidget {
  const _DpadScope({
    required this.controller,
    required this.keySet,
    required super.child,
  });

  final DpadController controller;
  final DpadKeySet keySet;

  @override
  bool updateShouldNotify(_DpadScope oldWidget) =>
      keySet != oldWidget.keySet || controller != oldWidget.controller;
}

// ---------------------------------------------------------------------------
// Intents & actions
// ---------------------------------------------------------------------------

class _DpadDirectionalIntent extends Intent {
  const _DpadDirectionalIntent(this.direction, {required this.isArrowKey});

  final TraversalDirection direction;

  /// Whether the pressed key is one of the four physical arrow keys, as
  /// opposed to a remapped movement key (WASD and friends). Only physical
  /// arrows keep the caret-edge escape contract inside text fields — a
  /// remapped key must fall through so it can be typed.
  final bool isArrowKey;
}

class _DpadBackIntent extends Intent {
  const _DpadBackIntent();
}

class _DpadMenuIntent extends Intent {
  const _DpadMenuIntent();
}

class _DpadCallbackIntent extends Intent {
  const _DpadCallbackIntent(this.callback);

  final VoidCallback callback;
}

class _DpadDirectionalAction extends Action<_DpadDirectionalIntent> {
  _DpadDirectionalAction(this.state);

  final _DpadState state;

  @override
  bool isEnabled(_DpadDirectionalIntent intent) => state._directionAllowed(
        intent.direction,
        isArrowKey: intent.isArrowKey,
      );

  @override
  Object? invoke(_DpadDirectionalIntent intent) {
    state._move(intent.direction);
    return null;
  }
}

class _DpadBackAction extends Action<_DpadBackIntent> {
  _DpadBackAction(this.state);

  final _DpadState state;

  @override
  bool isEnabled(_DpadBackIntent intent) =>
      state._keysActive && state.widget.onBack != null;

  @override
  Object? invoke(_DpadBackIntent intent) => state.widget.onBack!();

  @override
  KeyEventResult toKeyEventResult(
    _DpadBackIntent intent,
    covariant Object? invokeResult,
  ) {
    return invokeResult == true
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }
}

class _DpadMenuAction extends Action<_DpadMenuIntent> {
  _DpadMenuAction(this.state);

  final _DpadState state;

  @override
  bool isEnabled(_DpadMenuIntent intent) =>
      state._keysActive && state.widget.onMenu != null;

  @override
  Object? invoke(_DpadMenuIntent intent) {
    state.widget.onMenu!();
    return null;
  }
}

class _DpadCallbackAction extends Action<_DpadCallbackIntent> {
  _DpadCallbackAction(this.state);

  final _DpadState state;

  @override
  bool isEnabled(_DpadCallbackIntent intent) => state._keysActive;

  @override
  Object? invoke(_DpadCallbackIntent intent) {
    intent.callback();
    return null;
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

/// Programmatic d-pad control, obtained with [Dpad.of].
///
/// ```dart
/// final dpad = Dpad.of(context);
/// dpad.moveDown();
/// dpad.select();
/// dpad.requestFocus(searchFieldNode);
/// ```
class DpadController {
  DpadController._(this._state);

  final _DpadState _state;

  /// The node that currently holds focus, or `null` when nothing real is
  /// focused.
  FocusNode? get focused {
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    return primary is FocusScopeNode ? null : primary;
  }

  /// Moves focus one step in [direction], exactly like a remote key press.
  /// Returns whether focus moved (or the press was meaningfully consumed);
  /// `false` while [Dpad.enabled] is `false`.
  bool move(TraversalDirection direction) => _state._move(direction);

  /// Moves focus up. Equivalent to `move(TraversalDirection.up)`.
  bool moveUp() => move(TraversalDirection.up);

  /// Moves focus down. Equivalent to `move(TraversalDirection.down)`.
  bool moveDown() => move(TraversalDirection.down);

  /// Moves focus left. Equivalent to `move(TraversalDirection.left)`.
  bool moveLeft() => move(TraversalDirection.left);

  /// Moves focus right. Equivalent to `move(TraversalDirection.right)`.
  bool moveRight() => move(TraversalDirection.right);

  /// Moves focus to the next item in reading order (like Tab).
  bool next() => focused?.nextFocus() ?? false;

  /// Moves focus to the previous item in reading order (like Shift+Tab).
  bool previous() => focused?.previousFocus() ?? false;

  /// Activates the focused item — the programmatic equivalent of pressing
  /// the remote's center button. Returns whether something handled it.
  bool select() {
    final BuildContext? context = focused?.context;
    if (context == null || !context.mounted) {
      return false;
    }
    if (Actions.maybeFind<ActivateIntent>(context) == null) {
      return false;
    }
    Actions.maybeInvoke(context, const ActivateIntent());
    return true;
  }

  /// Runs the [Dpad.onBack] handler. Returns whether it consumed the event.
  bool back() => _state.widget.onBack?.call() ?? false;

  /// Focuses [node] if it can currently receive focus.
  bool requestFocus(FocusNode node) {
    if (!DpadMarks.isUsable(node)) {
      return false;
    }
    // A programmatic focus decision outranks any wrap rewind still in
    // flight — the chain must not drag focus back afterwards.
    DpadTraversalPolicy.invalidateRewinds();
    DpadRegion.ofNode(node)?.noteFocus(node);
    node.requestFocus();
    return true;
  }

  /// Removes focus from the currently focused item.
  void clearFocus() {
    // Deliberate unfocus: an in-flight rewind chain must not "helpfully"
    // grab focus back.
    DpadTraversalPolicy.invalidateRewinds();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Scrolls [node] (or the currently focused node) fully into view,
  /// keeping room for focus effects.
  void ensureVisible({
    FocusNode? node,
    double padding = 48.0,
    Duration duration = const Duration(milliseconds: 220),
    Curve curve = Curves.easeOutCubic,
  }) {
    final FocusNode? target = node ?? focused;
    if (target != null) {
      DpadScroll.ensureVisible(
        target,
        padding: padding,
        duration: duration,
        curve: curve,
      );
    }
  }
}
