import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The set of remote-control keys recognized by the d-pad system.
///
/// TV remotes, game controllers and keyboards report semantically equivalent
/// buttons under different [LogicalKeyboardKey]s. A [DpadKeySet] groups them
/// by *meaning* so the rest of the library — and your app — can reason about
/// "select" or "back" instead of individual key codes.
///
/// The default constructor covers Android TV, Fire TV, Apple TV (via web),
/// standard game controllers and desktop keyboards. Customize it when your
/// target device reports unusual key codes:
///
/// ```dart
/// Dpad(
///   keySet: const DpadKeySet().copyWith(
///     select: [LogicalKeyboardKey.f1, ...DpadKeySet.defaultSelect],
///   ),
///   child: ...,
/// )
/// ```
@immutable
class DpadKeySet {
  /// Creates a key set. Every parameter falls back to the platform defaults.
  const DpadKeySet({
    this.up = defaultUp,
    this.down = defaultDown,
    this.left = defaultLeft,
    this.right = defaultRight,
    this.select = defaultSelect,
    this.back = defaultBack,
    this.menu = defaultMenu,
  });

  /// Default keys that move focus up.
  static const List<LogicalKeyboardKey> defaultUp = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowUp,
  ];

  /// Default keys that move focus down.
  static const List<LogicalKeyboardKey> defaultDown = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowDown,
  ];

  /// Default keys that move focus left.
  static const List<LogicalKeyboardKey> defaultLeft = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowLeft,
  ];

  /// Default keys that move focus right.
  static const List<LogicalKeyboardKey> defaultRight = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowRight,
  ];

  /// Default keys that confirm / press the focused item.
  ///
  /// Covers the remote center button ([LogicalKeyboardKey.select]), keyboard
  /// confirm keys and the game controller `A` button.
  static const List<LogicalKeyboardKey> defaultSelect = <LogicalKeyboardKey>[
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.gameButtonA,
  ];

  /// Default keys that request back navigation.
  static const List<LogicalKeyboardKey> defaultBack = <LogicalKeyboardKey>[
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.goBack,
    LogicalKeyboardKey.gameButtonB,
  ];

  /// Default keys that open a contextual menu.
  static const List<LogicalKeyboardKey> defaultMenu = <LogicalKeyboardKey>[
    LogicalKeyboardKey.contextMenu,
  ];

  /// Keys that move focus up.
  final List<LogicalKeyboardKey> up;

  /// Keys that move focus down.
  final List<LogicalKeyboardKey> down;

  /// Keys that move focus left.
  final List<LogicalKeyboardKey> left;

  /// Keys that move focus right.
  final List<LogicalKeyboardKey> right;

  /// Keys that confirm / press the focused item.
  ///
  /// Note that mapping is additive for selection: keyboard-standard
  /// activation keys (`enter`, `space`) reach [DpadFocusable] through the
  /// framework's own [ActivateIntent] shortcuts no matter what this set
  /// contains, just like they activate any Flutter button — remapping
  /// `select` adds keys (e.g. `F1`), it cannot disarm the keyboard ones.
  final List<LogicalKeyboardKey> select;

  /// Keys that request back navigation.
  final List<LogicalKeyboardKey> back;

  /// Keys that open a contextual menu.
  final List<LogicalKeyboardKey> menu;

  /// Returns the [TraversalDirection] mapped to [key], or `null` if [key] is
  /// not a directional key in this set.
  TraversalDirection? directionOf(LogicalKeyboardKey key) {
    if (up.contains(key)) {
      return TraversalDirection.up;
    }
    if (down.contains(key)) {
      return TraversalDirection.down;
    }
    if (left.contains(key)) {
      return TraversalDirection.left;
    }
    if (right.contains(key)) {
      return TraversalDirection.right;
    }
    return null;
  }

  /// Whether [key] is a select key in this set.
  bool isSelect(LogicalKeyboardKey key) => select.contains(key);

  /// Whether [key] is a back key in this set.
  bool isBack(LogicalKeyboardKey key) => back.contains(key);

  /// Whether [key] is a menu key in this set.
  bool isMenu(LogicalKeyboardKey key) => menu.contains(key);

  /// Creates a copy of this key set with the given fields replaced.
  DpadKeySet copyWith({
    List<LogicalKeyboardKey>? up,
    List<LogicalKeyboardKey>? down,
    List<LogicalKeyboardKey>? left,
    List<LogicalKeyboardKey>? right,
    List<LogicalKeyboardKey>? select,
    List<LogicalKeyboardKey>? back,
    List<LogicalKeyboardKey>? menu,
  }) {
    return DpadKeySet(
      up: up ?? this.up,
      down: down ?? this.down,
      left: left ?? this.left,
      right: right ?? this.right,
      select: select ?? this.select,
      back: back ?? this.back,
      menu: menu ?? this.menu,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DpadKeySet &&
        listEquals(other.up, up) &&
        listEquals(other.down, down) &&
        listEquals(other.left, left) &&
        listEquals(other.right, right) &&
        listEquals(other.select, select) &&
        listEquals(other.back, back) &&
        listEquals(other.menu, menu);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(up),
        Object.hashAll(down),
        Object.hashAll(left),
        Object.hashAll(right),
        Object.hashAll(select),
        Object.hashAll(back),
        Object.hashAll(menu),
      );
}
