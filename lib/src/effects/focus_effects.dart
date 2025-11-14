import 'package:flutter/material.dart';

/// Signature for focus effect builders.
///
/// This function type defines the signature for custom focus effect builders.
/// It provides the current focus state and allows you to wrap
/// the child widget with custom focus indicators.
///
/// **Parameters:**
/// - [context]: The BuildContext for theme access
/// - [isFocused]: Whether the widget currently has focus
/// - [child]: The child widget to wrap with focus effects
///
/// **Returns:** A widget that implements the focus effect
///
/// **Example:**
/// ```dart
/// FocusEffectBuilder myEffect = (context, isFocused, child) {
///   return AnimatedContainer(
///     duration: Duration(milliseconds: 200),
///     decoration: BoxDecoration(
///       border: Border.all(
///         color: isFocused ? Colors.blue : Colors.transparent,
///         width: 2,
///       ),
///     ),
///     child: child,
///   );
/// };
/// ```
typedef FocusEffectBuilder = Widget Function(
  BuildContext context,
  bool isFocused,
  Widget child,
);

/// Pre-built focus effects for common use cases.
///
/// This class provides a collection of ready-to-use focus effects that
/// cover the most common focus indication patterns in TV applications.
/// Each effect is highly customizable and can be combined with others.
///
/// **Available Effects:**
/// - [border]: Simple colored border highlight
/// - [glow]: Shadow/glow effect around focused widget
/// - [scale]: Scale animation when focused
/// - [gradient]: Gradient background change
/// - [elevation]: Material design elevation effect
/// - [scaleWithBorder]: Combined scale and border
/// - [opacity]: Opacity change on focus
/// - [colorTint]: Color overlay effect
/// - [combine]: Multiple effects combined
///
/// **Example Usage:**
/// ```dart
/// DpadFocusable(
///   builder: FocusEffects.border(color: Colors.blue),
///   child: MyWidget(),
/// )
/// ```
class FocusEffects {
  /// Simple border highlight effect.
  ///
  /// Shows a colored border around the widget when it receives focus.
  /// This is the most common and straightforward focus indication.
  ///
  /// **Example:**
  /// ```dart
  /// FocusEffects.border(
  ///   focusColor: Colors.blue,
  ///   width: 3.0,
  ///   borderRadius: BorderRadius.circular(12),
  ///   duration: Duration(milliseconds: 150),
  /// )
  /// ```
  ///
  /// **Parameters:**
  /// - [focusColor]: Color of the border when focused (defaults to theme primary)
  /// - [unfocusedColor]: Color when not focused (defaults to transparent)
  /// - [width]: Border width when focused (defaults to 2.0)
  /// - [borderRadius]: Border radius for the container
  /// - [duration]: Animation duration (defaults to 200ms)
  ///
  /// **Returns:** A [FocusEffectBuilder] that applies the border effect
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
  ///
  /// Creates a shadow/glow effect around the widget when it receives focus.
  /// This effect is great for drawing attention to focused elements
  /// with a subtle but noticeable glow.
  ///
  /// **Example:**
  /// ```dart
  /// FocusEffects.glow(
  ///   glowColor: Colors.blue,
  ///   blurRadius: 15.0,
  ///   spreadRadius: 5.0,
  /// )
  /// ```
  ///
  /// **Parameters:**
  /// - [glowColor]: Color of the glow (defaults to theme primary)
  /// - [blurRadius]: Blur radius of the shadow (defaults to 20.0)
  /// - [spreadRadius]: How much the shadow spreads (defaults to 2.0)
  /// - [borderRadius]: Border radius for the container
  /// - [duration]: Animation duration (defaults to 200ms)
  ///
  /// **Returns:** A [FocusEffectBuilder] that applies the glow effect
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
  ///
  /// Animates the widget size by scaling it up when focused.
  /// This creates a smooth zoom effect that draws attention
  /// to the focused element.
  ///
  /// **Example:**
  /// ```dart
  /// FocusEffects.scale(
  ///   scale: 1.15,
  ///   curve: Curves.elasticOut,
  ///   duration: Duration(milliseconds: 300),
  /// )
  /// ```
  ///
  /// **Parameters:**
  /// - [scale]: Scale factor when focused (defaults to 1.1)
  /// - [duration]: Animation duration (defaults to 200ms)
  /// - [curve]: Animation curve (defaults to Curves.easeInOut)
  ///
  /// **Returns:** A [FocusEffectBuilder] that applies the scale effect
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
  ///
  /// Changes the widget background to a gradient when focused,
  /// and optionally when unfocused. This effect is great for
  /// colorful, modern focus indicators.
  ///
  /// **Example:**
  /// ```dart
  /// FocusEffects.gradient(
  ///   focusedColors: [Colors.blue, Colors.purple],
  ///   unfocusedColors: [Colors.grey.shade600],
  /// )
  /// ```
  ///
  /// **Parameters:**
  /// - [focusedColors]: Required list of colors for focused gradient
  /// - [unfocusedColors]: Optional list for unfocused gradient
  /// - [borderRadius]: Border radius for the container
  /// - [duration]: Animation duration (defaults to 250ms)
  ///
  /// **Returns:** A [FocusEffectBuilder] that applies the gradient effect
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
  ///
  /// Applies Material Design elevation when focused, creating a
  /// shadow effect that simulates lifting the widget off the surface.
  /// This provides depth and follows Material Design principles.
  ///
  /// **Example:**
  /// ```dart
  /// FocusEffects.elevation(
  ///   focusedElevation: 12.0,
  ///   unfocusedElevation: 2.0,
  ///   shadowColor: Colors.blue,
  /// )
  /// ```
  ///
  /// **Parameters:**
  /// - [focusedElevation]: Elevation when focused (defaults to 8.0)
  /// - [unfocusedElevation]: Elevation when not focused (defaults to 0.0)
  /// - [shadowColor]: Color of the shadow (defaults to black)
  /// - [borderRadius]: Border radius for the container
  /// - [duration]: Animation duration (defaults to 200ms)
  ///
  /// **Returns:** A [FocusEffectBuilder] that applies the elevation effect
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
  ///
  /// Combines scale animation with border highlight for
  /// a more prominent focus indication. The widget scales up
  /// and shows a colored border when focused.
  ///
  /// **Example:**
  /// ```dart
  /// FocusEffects.scaleWithBorder(
  ///   scale: 1.08,
  ///   borderColor: Colors.amber,
  ///   borderWidth: 4.0,
  /// )
  /// ```
  ///
  /// **Parameters:**
  /// - [scale]: Scale factor when focused (defaults to 1.05)
  /// - [borderColor]: Color of the border (defaults to theme primary)
  /// - [borderWidth]: Width of the border (defaults to 3.0)
  /// - [borderRadius]: Border radius for the container
  /// - [duration]: Animation duration (defaults to 200ms)
  ///
  /// **Returns:** A [FocusEffectBuilder] that combines scale and border effects
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
  ///
  /// Changes the widget opacity when focused, making focused elements
  /// more prominent while dimming unfocused ones.
  /// This effect is subtle but effective for focus hierarchy.
  ///
  /// **Example:**
  /// ```dart
  /// FocusEffects.opacity(
  ///   focusedOpacity: 1.0,
  ///   unfocusedOpacity: 0.5,
  /// )
  /// ```
  ///
  /// **Parameters:**
  /// - [focusedOpacity]: Opacity when focused (defaults to 1.0)
  /// - [unfocusedOpacity]: Opacity when not focused (defaults to 0.6)
  /// - [duration]: Animation duration (defaults to 200ms)
  ///
  /// **Returns:** A [FocusEffectBuilder] that applies the opacity effect
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
  ///
  /// Applies a colored overlay (tint) to the widget when focused.
  /// This creates a subtle color filter effect that can be
  /// used for consistent theming across focus states.
  ///
  /// **Example:**
  /// ```dart
  /// FocusEffects.colorTint(
  ///   focusedTint: Colors.blue.withValues(alpha: 0.2),
  ///   unfocusedTint: Colors.transparent,
  /// )
  /// ```
  ///
  /// **Parameters:**
  /// - [focusedTint]: Color overlay when focused (defaults to theme primary with alpha)
  /// - [unfocusedTint]: Color overlay when not focused (defaults to transparent)
  /// - [duration]: Animation duration (defaults to 200ms)
  ///
  /// **Returns:** A [FocusEffectBuilder] that applies the color tint effect
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
  ///
  /// Allows you to stack multiple focus effects together.
  /// Effects are applied in reverse order, so the first effect
  /// in the list is the outermost (closest to child).
  /// 
  /// **Example:**
  /// ```dart
  /// FocusEffects.combine([
  ///   FocusEffects.scale(scale: 1.1),
  ///   FocusEffects.border(color: Colors.blue),
  ///   FocusEffects.glow(glowColor: Colors.purple),
  /// ])
  /// ```
  ///
  /// **Parameters:**
  /// - [effects]: List of focus effect builders to combine
  ///
  /// **Returns:** A [FocusEffectBuilder] that applies all effects
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
