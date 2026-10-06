import 'package:flutter/material.dart';

/// The interaction state of a [DpadFocusable], passed to focus effects and
/// custom builders.
///
/// TV interfaces communicate two distinct states:
///
/// * [focused] — the item is the current d-pad cursor position.
/// * [pressed] — the select key (or a tap) is currently held down on the
///   item. Use it for "press down" feedback, mirroring native TV platforms.
@immutable
class DpadFocusState {
  /// Creates an interaction state snapshot.
  const DpadFocusState({required this.focused, required this.pressed});

  /// A state that is neither focused nor pressed.
  static const DpadFocusState idle =
      DpadFocusState(focused: false, pressed: false);

  /// Whether the item currently has d-pad focus.
  final bool focused;

  /// Whether the select key or a pointer is currently held down on the item.
  final bool pressed;

  @override
  bool operator ==(Object other) {
    return other is DpadFocusState &&
        other.focused == focused &&
        other.pressed == pressed;
  }

  @override
  int get hashCode => Object.hash(focused, pressed);

  @override
  String toString() => 'DpadFocusState(focused: $focused, pressed: $pressed)';
}

/// Signature for building a custom focus presentation.
///
/// [child] is the wrapped content; return it decorated according to [state].
typedef DpadEffectBuilder = Widget Function(
  BuildContext context,
  DpadFocusState state,
  Widget child,
);

/// A composable, immutable visual effect applied to a [DpadFocusable] based
/// on its [DpadFocusState].
///
/// Effects are plain const-able objects, so they can be shared through
/// [DpadThemeData.effects] or passed inline:
///
/// ```dart
/// DpadFocusable(
///   effects: const [
///     DpadScaleEffect(scale: 1.1),
///     DpadGlowEffect(),
///   ],
///   child: PosterCard(...),
/// )
/// ```
///
/// When multiple effects are combined, the **first** effect in the list is
/// the outermost wrapper. Put transform-style effects (like [DpadScaleEffect])
/// first so they scale the entire decorated result.
abstract class DpadEffect {
  /// Const constructor for subclasses.
  const DpadEffect();

  /// Wraps [child] with this effect for the given interaction [state].
  Widget build(BuildContext context, DpadFocusState state, Widget child);

  /// Applies [effects] to [child], first effect outermost.
  static Widget wrap(
    BuildContext context,
    List<DpadEffect> effects,
    DpadFocusState state,
    Widget child,
  ) {
    Widget result = child;
    for (int i = effects.length - 1; i >= 0; i--) {
      result = effects[i].build(context, state, result);
    }
    return result;
  }
}

/// The Material primary when a [Theme] surrounds the item, white otherwise,
/// so default-colored effects work (and stay neutral) in Material-less apps.
Color _primaryColor(BuildContext context) {
  if (context.findAncestorWidgetOfExactType<Theme>() == null) {
    return const Color(0xFFFFFFFF);
  }
  return Theme.of(context).colorScheme.primary;
}

/// Scales the item up while focused and slightly back down while pressed —
/// the classic TV "lift and press" feedback.
class DpadScaleEffect extends DpadEffect {
  /// Creates a scale effect.
  const DpadScaleEffect({
    this.scale = 1.08,
    this.pressedScale,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeOutCubic,
  });

  /// Scale factor while focused.
  final double scale;

  /// Scale factor while pressed.
  ///
  /// Defaults to a value halfway between `1.0` and [scale], producing a
  /// subtle "push down" while the select key is held.
  final double? pressedScale;

  /// Animation duration.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    final double target = state.pressed
        ? (pressedScale ?? (1.0 + (scale - 1.0) * 0.5))
        : state.focused
            ? scale
            : 1.0;
    return AnimatedScale(
      scale: target,
      duration: duration,
      curve: curve,
      child: child,
    );
  }
}

/// Paints an animated border on top of the item while focused.
///
/// The border is drawn as a foreground decoration, so enabling it never
/// shifts the item's layout.
class DpadBorderEffect extends DpadEffect {
  /// Creates a border effect.
  const DpadBorderEffect({
    this.color,
    this.width = 2.5,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.duration = const Duration(milliseconds: 150),
  });

  /// Border color. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Border stroke width while focused.
  final double width;

  /// Corner radius of the border.
  final BorderRadius borderRadius;

  /// Animation duration.
  final Duration duration;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    final Color resolved = color ?? _primaryColor(context);
    return AnimatedContainer(
      duration: duration,
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: state.focused ? resolved : resolved.withAlpha(0),
          width: width,
        ),
      ),
      child: child,
    );
  }
}

/// Surrounds the item with a soft glow while focused.
class DpadGlowEffect extends DpadEffect {
  /// Creates a glow effect.
  const DpadGlowEffect({
    this.color,
    this.blurRadius = 18.0,
    this.spreadRadius = 2.0,
    this.opacity = 0.55,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.duration = const Duration(milliseconds: 150),
  });

  /// Glow color. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Blur radius of the glow.
  final double blurRadius;

  /// Spread radius of the glow.
  final double spreadRadius;

  /// Peak opacity of the glow while focused, `0.0` – `1.0`.
  final double opacity;

  /// Corner radius used by the shadow shape.
  final BorderRadius borderRadius;

  /// Animation duration.
  final Duration duration;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    final Color resolved = color ?? _primaryColor(context);
    return AnimatedContainer(
      duration: duration,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        // No shadow at all while idle (BoxShadow.lerpList interpolates
        // between lists of different lengths, so the fade stays smooth).
        boxShadow: state.focused
            ? <BoxShadow>[
                BoxShadow(
                  color: resolved.withAlpha(
                    (opacity.clamp(0.0, 1.0) * 255).round(),
                  ),
                  blurRadius: blurRadius,
                  spreadRadius: spreadRadius,
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: child,
    );
  }
}

/// Raises the item with a Material elevation shadow while focused.
class DpadElevationEffect extends DpadEffect {
  /// Creates an elevation effect.
  const DpadElevationEffect({
    this.elevation = 12.0,
    this.idleElevation = 0.0,
    this.shadowColor = const Color(0xFF000000),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.duration = const Duration(milliseconds: 150),
  });

  /// Elevation while focused.
  final double elevation;

  /// Elevation while not focused.
  final double idleElevation;

  /// Shadow color.
  final Color shadowColor;

  /// Corner radius of the shadow shape.
  final BorderRadius borderRadius;

  /// Animation duration.
  final Duration duration;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    return AnimatedPhysicalModel(
      duration: duration,
      curve: Curves.easeOutCubic,
      shape: BoxShape.rectangle,
      elevation: state.focused ? elevation : idleElevation,
      color: const Color(0x00000000),
      shadowColor: shadowColor,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

/// Dims the item while it is *not* focused, letting the focused item stand
/// out against its neighbors.
class DpadOpacityEffect extends DpadEffect {
  /// Creates an opacity effect.
  const DpadOpacityEffect({
    this.idleOpacity = 0.6,
    this.focusedOpacity = 1.0,
    this.duration = const Duration(milliseconds: 150),
  });

  /// Opacity while not focused.
  final double idleOpacity;

  /// Opacity while focused.
  final double focusedOpacity;

  /// Animation duration.
  final Duration duration;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    return AnimatedOpacity(
      duration: duration,
      opacity: state.focused ? focusedOpacity : idleOpacity,
      child: child,
    );
  }
}

/// Lays a translucent color over the item while focused.
class DpadTintEffect extends DpadEffect {
  /// Creates a tint effect.
  const DpadTintEffect({
    this.color,
    this.opacity = 0.25,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.duration = const Duration(milliseconds: 150),
  });

  /// Tint color. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Peak opacity of the tint while focused, `0.0` – `1.0`.
  final double opacity;

  /// Corner radius of the tint overlay.
  final BorderRadius borderRadius;

  /// Animation duration.
  final Duration duration;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    final Color resolved = color ?? _primaryColor(context);
    return AnimatedContainer(
      duration: duration,
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius,
        color: resolved.withAlpha(
          state.focused ? (opacity.clamp(0.0, 1.0) * 255).round() : 0,
        ),
      ),
      child: child,
    );
  }
}

/// Adapts an arbitrary [DpadEffectBuilder] into a [DpadEffect], for one-off
/// effects that do not deserve their own class.
class DpadCustomEffect extends DpadEffect {
  /// Creates an effect backed by [builder].
  const DpadCustomEffect(this.builder);

  /// The function that decorates the child.
  final DpadEffectBuilder builder;

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    return builder(context, state, child);
  }
}
