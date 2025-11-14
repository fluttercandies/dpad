import 'package:flutter/material.dart';

/// Signature for focus effect builders.
typedef FocusEffectBuilder = Widget Function(
  BuildContext context,
  bool isFocused,
  Widget child,
);

/// Pre-built focus effects for common use cases.
class FocusEffects {
  /// Simple border highlight effect.
  ///
  /// Shows a colored border when focused.
  static FocusEffectBuilder border({
    Color? focusColor,
    Color unfocusedColor = Colors.transparent,
    double width = 2.0,
    BorderRadius? borderRadius,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return (context, isFocused, child) {
      final color = focusColor ?? Theme.of(context).colorScheme.primary;
      return AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused ? color : unfocusedColor,
            width: width,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: child,
      );
    };
  }

  /// Glow/shadow effect when focused.
  static FocusEffectBuilder glow({
    Color? glowColor,
    double blurRadius = 20.0,
    double spreadRadius = 2.0,
    BorderRadius? borderRadius,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return (context, isFocused, child) {
      final color = glowColor ?? Theme.of(context).colorScheme.primary;
      return AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: blurRadius,
                    spreadRadius: spreadRadius,
                  ),
                ]
              : null,
        ),
        child: child,
      );
    };
  }

  /// Scale effect when focused.
  static FocusEffectBuilder scale({
    double scale = 1.1,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeInOut,
  }) {
    return (context, isFocused, child) {
      return TweenAnimationBuilder<double>(
        duration: duration,
        curve: curve,
        tween: Tween(begin: 1.0, end: isFocused ? scale : 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: child,
      );
    };
  }

  /// Gradient background effect.
  static FocusEffectBuilder gradient({
    required List<Color> focusedColors,
    List<Color>? unfocusedColors,
    BorderRadius? borderRadius,
    Duration duration = const Duration(milliseconds: 250),
  }) {
    return (context, isFocused, child) {
      return AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          gradient: isFocused
              ? LinearGradient(colors: focusedColors)
              : (unfocusedColors != null
                  ? LinearGradient(colors: unfocusedColors)
                  : null),
          color: !isFocused && unfocusedColors == null
              ? Colors.grey.shade800
              : null,
        ),
        child: child,
      );
    };
  }

  /// Elevation effect (material design).
  static FocusEffectBuilder elevation({
    double focusedElevation = 8.0,
    double unfocusedElevation = 0.0,
    Color? shadowColor,
    BorderRadius? borderRadius,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return (context, isFocused, child) {
      return AnimatedPhysicalModel(
        duration: duration,
        elevation: isFocused ? focusedElevation : unfocusedElevation,
        color: Colors.transparent,
        shadowColor: shadowColor ?? Colors.black,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: child,
      );
    };
  }

  /// Combined scale and border effect.
  static FocusEffectBuilder scaleWithBorder({
    double scale = 1.05,
    Color? borderColor,
    double borderWidth = 3.0,
    BorderRadius? borderRadius,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return (context, isFocused, child) {
      final color = borderColor ?? Theme.of(context).colorScheme.primary;
      return TweenAnimationBuilder<double>(
        duration: duration,
        tween: Tween(begin: 1.0, end: isFocused ? scale : 1.0),
        builder: (context, value, animChild) {
          return Transform.scale(
            scale: value,
            child: AnimatedContainer(
              duration: duration,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isFocused ? color : Colors.transparent,
                  width: borderWidth,
                ),
                borderRadius: borderRadius ?? BorderRadius.circular(8),
              ),
              child: animChild,
            ),
          );
        },
        child: child,
      );
    };
  }

  /// Opacity effect.
  static FocusEffectBuilder opacity({
    double focusedOpacity = 1.0,
    double unfocusedOpacity = 0.6,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return (context, isFocused, child) {
      return AnimatedOpacity(
        duration: duration,
        opacity: isFocused ? focusedOpacity : unfocusedOpacity,
        child: child,
      );
    };
  }

  /// Color tint effect.
  static FocusEffectBuilder colorTint({
    Color? focusedTint,
    Color? unfocusedTint,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return (context, isFocused, child) {
      final tint = isFocused
          ? (focusedTint ??
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))
          : unfocusedTint;

      return AnimatedContainer(
        duration: duration,
        color: tint,
        child: child,
      );
    };
  }

  /// Combine multiple effects.
  static FocusEffectBuilder combine(List<FocusEffectBuilder> effects) {
    return (context, isFocused, child) {
      Widget result = child;
      for (final effect in effects.reversed) {
        result = effect(context, isFocused, result);
      }
      return result;
    };
  }
}
