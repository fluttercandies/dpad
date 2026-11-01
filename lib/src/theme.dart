import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'effects.dart';
import 'scroll.dart';

/// Shared defaults for every [DpadFocusable] below a [DpadTheme] (or the
/// [Dpad] root, which installs one).
///
/// Individual [DpadFocusable]s override these values with their own
/// parameters; anything left `null` falls back to the theme.
/// [longSelectDuration] is the exception — it has no per-item parameter, so
/// the theme (or nearest [DpadThemeData] scope) always decides it.
@immutable
class DpadThemeData {
  /// Creates d-pad defaults.
  const DpadThemeData({
    this.effects = defaultEffects,
    this.scrollPadding = DpadScroll.defaultPadding,
    this.scrollDuration = DpadScroll.defaultDuration,
    this.scrollCurve = DpadScroll.defaultCurve,
    this.scrollAlignment = DpadRevealAlignment.nearest,
    this.longSelectDuration = const Duration(milliseconds: 500),
  });

  /// The default focus presentation: a gentle scale plus a border.
  static const List<DpadEffect> defaultEffects = <DpadEffect>[
    DpadScaleEffect(),
    DpadBorderEffect(),
  ];

  /// Effects applied to focusables that do not declare their own
  /// [DpadFocusable.effects] or [DpadFocusable.builder].
  ///
  /// The list is stored as given — treat it as immutable; mutating it after
  /// construction changes behavior in place and breaks `==`.
  final List<DpadEffect> effects;

  /// Extra space kept between a focused item and the viewport edge when
  /// auto-scrolling, so glows and scaled borders stay fully visible.
  final double scrollPadding;

  /// Duration of the auto-scroll animation.
  final Duration scrollDuration;

  /// Curve of the auto-scroll animation.
  final Curve scrollCurve;

  /// How the auto-scroll places a newly focused item along each scrollable's
  /// axis — just enough to reveal it ([DpadRevealAlignment.nearest], the
  /// default), or centered theater-style ([DpadRevealAlignment.center],
  /// which centers every scrollable and ignores [scrollPadding]). See
  /// [DpadRevealAlignment].
  final DpadRevealAlignment scrollAlignment;

  /// How long the select key must be held before
  /// [DpadFocusable.onLongSelect] fires.
  final Duration longSelectDuration;

  /// Creates a copy of this theme with the given fields replaced.
  DpadThemeData copyWith({
    List<DpadEffect>? effects,
    double? scrollPadding,
    Duration? scrollDuration,
    Curve? scrollCurve,
    DpadRevealAlignment? scrollAlignment,
    Duration? longSelectDuration,
  }) {
    return DpadThemeData(
      effects: effects ?? this.effects,
      scrollPadding: scrollPadding ?? this.scrollPadding,
      scrollDuration: scrollDuration ?? this.scrollDuration,
      scrollCurve: scrollCurve ?? this.scrollCurve,
      scrollAlignment: scrollAlignment ?? this.scrollAlignment,
      longSelectDuration: longSelectDuration ?? this.longSelectDuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DpadThemeData &&
        listEquals(other.effects, effects) &&
        other.scrollPadding == scrollPadding &&
        other.scrollDuration == scrollDuration &&
        other.scrollCurve == scrollCurve &&
        other.scrollAlignment == scrollAlignment &&
        other.longSelectDuration == longSelectDuration;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(effects),
        scrollPadding,
        scrollDuration,
        scrollCurve,
        scrollAlignment,
        longSelectDuration,
      );
}

/// Provides a [DpadThemeData] to descendant [DpadFocusable]s.
///
/// Nest one anywhere to restyle a subtree:
///
/// ```dart
/// DpadTheme(
///   data: const DpadThemeData(
///     effects: [DpadGlowEffect(color: Colors.amber)],
///   ),
///   child: SettingsColumn(...),
/// )
/// ```
class DpadTheme extends InheritedWidget {
  /// Provides [data] to descendants.
  const DpadTheme({super.key, required this.data, required super.child});

  /// The defaults for this subtree.
  final DpadThemeData data;

  /// The [DpadThemeData] of the closest enclosing [DpadTheme], or a default
  /// [DpadThemeData] when there is none.
  static DpadThemeData of(BuildContext context) {
    return maybeOf(context) ?? const DpadThemeData();
  }

  /// The [DpadThemeData] of the closest enclosing [DpadTheme], if any.
  static DpadThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DpadTheme>()?.data;
  }

  @override
  bool updateShouldNotify(DpadTheme oldWidget) => data != oldWidget.data;
}
