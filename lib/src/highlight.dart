import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'colors.dart';
import 'marks.dart';
import 'root.dart';

/// The configuration of the flying highlight — the single focus indicator
/// that slides from item to item as the d-pad moves, the way mainstream TV
/// and game interfaces do.
///
/// One type, three placement points, resolved nearest-first for wherever
/// focus lands:
///
/// * [Dpad.highlight] — enables it app-wide and provides the default style.
/// * [DpadHighlightTheme] — restyles (or enables it for) a page or section.
/// * [DpadFocusable.highlight] — restyles one item, or opts it out with
///   [DpadHighlight.none].
///
/// ```dart
/// Dpad(
///   highlight: const DpadHighlight(),  // ring by default, 220ms flights
///   child: app,
/// )
/// ```
///
/// Motion lives on this object; looks live in [effects], which follow the
/// focused item's corner shape by default ([radiusOf]). The flight follows
/// the focused item through scrolls, route transitions and focus-effect
/// transforms, chains smoothly when keys are pressed faster than flights
/// finish, fades in place on first appearance and fades out when focus is
/// lost.
@immutable
class DpadHighlight {
  /// Creates a flying highlight configuration.
  const DpadHighlight({
    this.effects = defaultEffects,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
    this.padding = EdgeInsets.zero,
    this.appearDuration = const Duration(milliseconds: 150),
    this.nudgeOffset = 0.0,
  });

  /// A configuration that paints nothing — pass it to
  /// [DpadFocusable.highlight] to opt an item out of the flying highlight
  /// (for items that draw their own focus presentation).
  static const DpadHighlight none = DpadHighlight(
    effects: <DpadHighlightEffect>[],
  );

  /// The default look: a single [DpadHighlightRingEffect].
  static const List<DpadHighlightEffect> defaultEffects =
      <DpadHighlightEffect>[DpadHighlightRingEffect()];

  /// The corner radius of [node]'s visual silhouette — the first
  /// shape-defining render object below the node (`ClipRRect`, a
  /// `BoxDecoration` corner radius or circle, `ClipOval`, physical
  /// models), scaled by the item's focus lift.
  ///
  /// The engine interpolates this between a flight's endpoints into
  /// [DpadHighlightState.radius], which the built-in effects follow.
  /// Public so custom effects can mix it with their own data:
  ///
  /// ```dart
  /// double? myRadiusOf(FocusNode? node) => node == null
  ///     ? null
  ///     : myShapeTable[node] ?? DpadHighlight.radiusOf(node);
  /// ```
  static double? radiusOf(FocusNode node) => _detectShapeRadius(node);

  /// What the highlight paints, first effect painted first (below the rest).
  ///
  /// Combine freely — a ring over a vignette, brackets with a glow — or
  /// subclass [DpadHighlightEffect] for anything else.
  final List<DpadHighlightEffect> effects;

  /// Flight duration. The default matches [DpadThemeData.scrollDuration] so
  /// the highlight and the auto-scroll arrive together.
  final Duration duration;

  /// Flight curve. [Curves.easeOutCubic] by default; try
  /// [Curves.easeOutBack] for the springy feel of game UIs.
  final Curve curve;

  /// How far the highlight extends beyond the focused item's bounds, so it
  /// can frame items without touching their content.
  final EdgeInsets padding;

  /// Fade-in duration for the first appearance, and fade-out when focus is
  /// lost (no flight in either case — the tvOS behavior).
  final Duration appearDuration;

  /// How far the highlight bounces when navigation hits an edge (the last
  /// item of a row, the bottom of a list) — directional feedback in the
  /// direction of the blocked move. A non-positive value (the default
  /// `0.0`) disables the bounce.
  ///
  /// The bounce is for moves no boundary consumed — a bare layout's dead
  /// end, or a `leave` edge with nothing beyond it. Boundaries a
  /// `DpadRegion` handles itself (`stop`, `wrap`, `lineWrap`) consume the
  /// key and report through `DpadRegion.onEdge` instead; pair the two for
  /// per-region feedback.
  final double nudgeOffset;

  /// Creates a copy of this configuration with the given fields replaced.
  DpadHighlight copyWith({
    List<DpadHighlightEffect>? effects,
    Duration? duration,
    Curve? curve,
    EdgeInsets? padding,
    Duration? appearDuration,
    double? nudgeOffset,
  }) {
    return DpadHighlight(
      effects: effects ?? this.effects,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      padding: padding ?? this.padding,
      appearDuration: appearDuration ?? this.appearDuration,
      nudgeOffset: nudgeOffset ?? this.nudgeOffset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DpadHighlight &&
        listEquals(other.effects, effects) &&
        other.duration == duration &&
        other.curve == curve &&
        other.padding == padding &&
        other.appearDuration == appearDuration &&
        other.nudgeOffset == nudgeOffset;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(effects),
        duration,
        curve,
        padding,
        appearDuration,
        nudgeOffset,
      );
  }

/// Provides a [DpadHighlight] to a subtree — the page- or section-level
/// placement point of the flying highlight's style.
///
/// The style is resolved for wherever focus lands, nearest first:
/// [DpadFocusable.highlight], then the closest [DpadHighlightTheme], then
/// [Dpad.highlight]. A scope also works on its own: with no highlight at the
/// root, the layer stays hidden until focus enters a scoped subtree. The
/// layer re-resolves when focus moves, so a scope whose [data] changes while
/// focus stands still inside it applies on the next focus change.
///
/// ```dart
/// DpadHighlightTheme(
///   data: const DpadHighlight(
///     effects: [DpadHighlightBracketsEffect()],
///   ),
///   child: CharacterGrid(),
/// )
/// ```
class DpadHighlightTheme extends InheritedWidget {
  /// Provides [data] to descendants.
  const DpadHighlightTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The flying-highlight configuration for this subtree.
  final DpadHighlight data;

  /// The [DpadHighlight] of the closest enclosing [DpadHighlightTheme], if
  /// any.
  static DpadHighlight? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DpadHighlightTheme>()
        ?.data;
  }

  @override
  bool updateShouldNotify(DpadHighlightTheme oldWidget) =>
      data != oldWidget.data;
}

/// The live state of the flying highlight, handed to [DpadHighlightEffect]s
/// on every frame while the highlight is on screen.
@immutable
class DpadHighlightState {
  /// Creates a snapshot of the flying highlight.
  const DpadHighlightState({
    required this.rect,
    required this.visible,
    required this.pressed,
    this.node,
    this.fromNode,
    this.t = 1.0,
    this.radius,
  });

  /// Where the highlight currently is, in the overlay's coordinate space —
  /// already lerping between items during a flight, inflated by
  /// [DpadHighlight.padding], and shifted by any edge bounce.
  final Rect rect;

  /// The focus node the highlight is tracking — the focused item's own
  /// node or the nearest enclosing `DpadFocusable`'s. The lowest-level
  /// handle on the item for custom effects (look up your own model).
  final FocusNode? node;

  /// The node the current flight started from — `null` when the highlight
  /// materialized in place (first appearance). With [t], the complete
  /// timeline for effects that interpolate values the engine does not
  /// (colors, shadows, private shape tables).
  final FocusNode? fromNode;

  /// Flight progress: `0.0` at takeoff, `1.0` landed — already
  /// curve-adjusted, and `1.0` whenever the highlight is not flying.
  ///
  /// With an overshooting curve (like `Curves.easeOutBack`) `t` passes
  /// `1.0` mid-flight and the rect and radius extrapolate with it — the
  /// springiness itself. Effects interpolating their own values from [t]
  /// get the same overshoot for free.
  final double t;

  /// The tracked item's corner radius — [DpadHighlight.radiusOf] at the
  /// flight's endpoints, lerping between them mid-flight so a 12-corner
  /// poster morphs into a circular avatar's full rounding. `null` means
  /// not detectable; effects that follow the shape fall back to their own
  /// corners.
  final double? radius;

  /// Whether the highlight currently has a focus target — `false` while
  /// it fades out after focus is lost, and until the first appearance.
  final bool visible;

  /// Whether the select key (or a pointer) is currently held down on the
  /// focused item.
  final bool pressed;

  /// Places [child] at [rect] — the standard wrapper for effects that
  /// decorate the focused item. Full-overlay effects (like
  /// [DpadHighlightVignetteEffect]) position themselves instead.
  Widget positioned(Widget child) =>
      Positioned.fromRect(rect: rect, child: child);
}

/// One layer of the flying highlight's presentation.
///
/// Built-in effects cover the common TV and game looks; subclass or use
/// [DpadHighlightCustomEffect] for anything else. Effects receive the live
/// [DpadHighlightState] every frame, so custom presentations can react to
/// flights and presses as they happen.
abstract class DpadHighlightEffect {
  /// Const constructor for subclasses.
  const DpadHighlightEffect();

  /// Builds this effect's presentation for the current [state].
  Widget build(BuildContext context, DpadHighlightState state);
}

/// Signature for building a custom flying-highlight presentation.
typedef DpadHighlightEffectBuilder = Widget Function(
  BuildContext context,
  DpadHighlightState state,
);

/// Adapts an arbitrary [builder] into a [DpadHighlightEffect], for one-off
/// presentations that do not deserve its own class.
///
/// Effects compare structurally so a rebuilt-but-equal configuration keeps
/// a landed flight landed — but a closure cannot. Build the
/// [DpadHighlight] that carries a custom effect once (a `static final` or
/// top-level field) instead of inline in a `MaterialApp.builder`, or every
/// root rebuild replays the flight timeline.
class DpadHighlightCustomEffect extends DpadHighlightEffect {
  /// Creates an effect backed by [builder].
  const DpadHighlightCustomEffect(this.builder);

  /// The function that paints the highlight.
  final DpadHighlightEffectBuilder builder;

  @override
  Widget build(BuildContext context, DpadHighlightState state) {
    return builder(context, state);
  }
}

/// Draws a rounded border around the focused item — the tvOS focus ring, and
/// the flying highlight's default look.
class DpadHighlightRingEffect extends DpadHighlightEffect {
  /// Creates a ring effect.
  const DpadHighlightRingEffect({
    this.color,
    this.width = 2.5,
    this.followShape = true,
    this.borderRadius,
    this.pressedScale,
  });

  /// Identifies the rendered ring; a hook for tests and inspections.
  static const Key debugKey = ValueKey<String>('dpad.highlight.ring');

  /// Ring color. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Stroke width.
  final double width;

  /// Whether the corners follow the focused item's own shape — its
  /// detected corner radius ([DpadHighlightState.radius]), morphing
  /// between items as the highlight flies. `true` by default; `false`
  /// keeps fixed 12-pixel corners. An explicit [borderRadius] wins over
  /// both.
  final bool followShape;

  /// Fixed corner radius of the ring — beats [followShape].
  final double? borderRadius;

  /// Scale factor while the focused item is pressed — a subtle "push" of
  /// the ring with the select key. `null` (the default) keeps the ring
  /// still and leaves press feedback to per-item effects.
  final double? pressedScale;

  @override
  Widget build(BuildContext context, DpadHighlightState state) {
    Widget ring = DecoratedBox(
      key: debugKey,
      decoration: BoxDecoration(
        borderRadius: _corners(state, borderRadius, followShape),
        border: Border.all(color: color ?? defaultEffectColor(context), width: width),
      ),
    );
    final double scale = state.pressed ? (pressedScale ?? 1.0) : 1.0;
    if (scale != 1.0) {
      ring = Transform.scale(scale: scale, child: ring);
    }
    return state.positioned(ring);
  }

  @override
  bool operator ==(Object other) {
    return other is DpadHighlightRingEffect &&
        other.color == color &&
        other.width == width &&
        other.followShape == followShape &&
        other.borderRadius == borderRadius &&
        other.pressedScale == pressedScale;
  }

  @override
  int get hashCode => Object.hash(
        color,
        width,
        followShape,
        borderRadius,
        pressedScale,
      );
}

/// The adaptive corner radius for [state] — what an effect paints with when
/// it follows the item's shape ([followShape] is `true`):
/// [DpadHighlightState.radius], clamped so pill-shaped items render fully
/// rounded instead of looping back inward, with a 12-pixel fallback when
/// the shape is not resolvable.
BorderRadius _shapeRadius(DpadHighlightState state) {
  final double radius = (state.radius ?? 12.0)
      .clamp(0.0, state.rect.shortestSide / 2);
  return BorderRadius.circular(radius);
}

/// The fixed 12-pixel corners an effect paints with when it does not follow
/// the item's shape.
BorderRadius _fixedRadius(DpadHighlightState state) {
  final double radius = 12.0.clamp(0.0, state.rect.shortestSide / 2);
  return BorderRadius.circular(radius);
}

/// Resolves an effect's corners: an explicit pin wins (clamped so it can
/// never loop back inward), then the item's own shape, then fixed 12-pixel
/// corners.
BorderRadius _corners(
  DpadHighlightState state,
  double? borderRadius,
  bool followShape,
) {
  if (borderRadius != null) {
    return BorderRadius.circular(
      borderRadius.clamp(0.0, state.rect.shortestSide / 2),
    );
  }
  return followShape ? _shapeRadius(state) : _fixedRadius(state);
}

/// Surrounds the focused item with a soft glow.
class DpadHighlightGlowEffect extends DpadHighlightEffect {
  /// Creates a glow effect.
  const DpadHighlightGlowEffect({
    this.color,
    this.blurRadius = 18.0,
    this.spreadRadius = 2.0,
    this.opacity = 0.55,
    this.followShape = true,
    this.borderRadius,
  });

  /// Identifies the rendered glow; a hook for tests and inspections.
  static const Key debugKey = ValueKey<String>('dpad.highlight.glow');

  /// Glow color. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Blur radius of the glow.
  final double blurRadius;

  /// Spread radius of the glow.
  final double spreadRadius;

  /// Peak opacity of the glow, `0.0` – `1.0`.
  final double opacity;

  /// Whether the shadow's corners follow the focused item's own shape,
  /// like [DpadHighlightRingEffect.followShape].
  final bool followShape;

  /// Fixed corner radius the shadow is cast from — beats [followShape].
  final double? borderRadius;

  @override
  Widget build(BuildContext context, DpadHighlightState state) {
    return state.positioned(
      DecoratedBox(
        key: debugKey,
        decoration: BoxDecoration(
          borderRadius: _corners(state, borderRadius, followShape),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: (color ?? defaultEffectColor(context))
                  .withAlpha((opacity.clamp(0.0, 1.0) * 255).round()),
              blurRadius: blurRadius,
              spreadRadius: spreadRadius,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DpadHighlightGlowEffect &&
        other.color == color &&
        other.blurRadius == blurRadius &&
        other.spreadRadius == spreadRadius &&
        other.opacity == opacity &&
        other.followShape == followShape &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(
        color,
        blurRadius,
        spreadRadius,
        opacity,
        followShape,
        borderRadius,
      );
}

/// Lays a translucent color over the focused item — a spotlight that makes
/// it read as "on" against its neighbors.
class DpadHighlightSpotlightEffect extends DpadHighlightEffect {
  /// Creates a spotlight effect.
  const DpadHighlightSpotlightEffect({
    this.color,
    this.opacity = 0.25,
    this.followShape = true,
    this.borderRadius,
  });

  /// Identifies the rendered spotlight; a hook for tests and inspections.
  static const Key debugKey = ValueKey<String>('dpad.highlight.spotlight');

  /// Spotlight color. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Opacity of the overlay, `0.0` – `1.0`.
  final double opacity;

  /// Whether the corners follow the focused item's own shape, like
  /// [DpadHighlightRingEffect.followShape].
  final bool followShape;

  /// Fixed corner radius of the overlay — beats [followShape].
  final double? borderRadius;

  @override
  Widget build(BuildContext context, DpadHighlightState state) {
    return state.positioned(
      DecoratedBox(
        key: debugKey,
        decoration: BoxDecoration(
          color: (color ?? defaultEffectColor(context))
              .withAlpha((opacity.clamp(0.0, 1.0) * 255).round()),
          borderRadius: _corners(state, borderRadius, followShape),
        ),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DpadHighlightSpotlightEffect &&
        other.color == color &&
        other.opacity == opacity &&
        other.followShape == followShape &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(
        color,
        opacity,
        followShape,
        borderRadius,
      );
}

/// Frames the focused item with four corner brackets — the selection
/// reticle of game UIs and HUDs.
class DpadHighlightBracketsEffect extends DpadHighlightEffect {
  /// Creates a brackets effect.
  const DpadHighlightBracketsEffect({
    this.color,
    this.thickness = 3.0,
    this.length = 24.0,
  });

  /// Identifies the rendered brackets; a hook for tests and inspections.
  static const Key debugKey = ValueKey<String>('dpad.highlight.brackets');

  /// Bracket color. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Stroke width of each bracket arm.
  final double thickness;

  /// Arm length, clamped to half the highlight's shortest side.
  final double length;

  @override
  Widget build(BuildContext context, DpadHighlightState state) {
    return state.positioned(
      CustomPaint(
        key: debugKey,
        painter: _BracketPainter(
          color: color ?? defaultEffectColor(context),
          thickness: thickness,
          length: length,
        ),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DpadHighlightBracketsEffect &&
        other.color == color &&
        other.thickness == thickness &&
        other.length == length;
  }

  @override
  int get hashCode => Object.hash(color, thickness, length);
}

class _BracketPainter extends CustomPainter {
  _BracketPainter({
    required this.color,
    required this.thickness,
    required this.length,
  });

  final Color color;
  final double thickness;
  final double length;

  @override
  void paint(Canvas canvas, Size size) {
    final double arm =
        length.clamp(0.0, size.shortestSide / 2).toDouble();
    if (arm <= 0.0) {
      return;
    }
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      // Top-left.
      ..moveTo(0, arm)
      ..lineTo(0, 0)
      ..lineTo(arm, 0)
      // Top-right.
      ..moveTo(size.width - arm, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, arm)
      // Bottom-right.
      ..moveTo(size.width, size.height - arm)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - arm, size.height)
      // Bottom-left.
      ..moveTo(arm, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BracketPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.length != length;
  }
}

/// Dims everything outside the focused item — the spotlight-vignette of
/// game character screens and tvOS. The item itself stays fully lit.
class DpadHighlightVignetteEffect extends DpadHighlightEffect {
  /// Creates a vignette effect.
  const DpadHighlightVignetteEffect({
    this.color = const Color(0x00000000),
    this.opacity = 0.5,
    this.followShape = true,
    this.borderRadius,
    this.padding = 4.0,
  });

  /// Identifies the rendered vignette; a hook for tests and inspections.
  static const Key debugKey = ValueKey<String>('dpad.highlight.vignette');

  /// Vignette color. Black by default; any color with [opacity] sets the
  /// wash.
  final Color color;

  /// Opacity of the dimming outside the hole, `0.0` – `1.0`.
  final double opacity;

  /// Whether the hole's corners follow the focused item's own shape, like
  /// [DpadHighlightRingEffect.followShape].
  final bool followShape;

  /// Fixed corner radius of the hole cut around the focused item — beats
  /// [followShape].
  final double? borderRadius;

  /// Extra breathing room between the item and the hole's edge.
  final double padding;

  @override
  Widget build(BuildContext context, DpadHighlightState state) {
    final Rect hole = state.rect.inflate(padding);
    final double radius = (borderRadius ??
            (followShape ? state.radius : null) ??
            12.0)
        .clamp(0.0, hole.shortestSide / 2);
    return Positioned.fill(
      child: CustomPaint(
        key: debugKey,
        painter: _VignettePainter(
          hole: hole,
          color: color.withAlpha((opacity.clamp(0.0, 1.0) * 255).round()),
          radius: radius,
        ),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DpadHighlightVignetteEffect &&
        other.color == color &&
        other.opacity == opacity &&
        other.followShape == followShape &&
        other.borderRadius == borderRadius &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(
        color,
        opacity,
        followShape,
        borderRadius,
        padding,
      );
}

class _VignettePainter extends CustomPainter {
  _VignettePainter({
    required this.hole,
    required this.color,
    required this.radius,
  });

  final Rect hole;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    // Even-odd fill paints the hole directly — a saveLayer with a clear
    // blend would cost a full-screen offscreen pass on every flight frame.
    final Path wash = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(wash, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_VignettePainter oldDelegate) {
    return oldDelegate.hole != hole ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}

// ---------------------------------------------------------------------------
// Shape detection (internal)
// ---------------------------------------------------------------------------

/// The uniform corner radius of [node]'s visual silhouette, or `null` when
/// the item paints nothing the walker recognizes — the implementation
/// behind [DpadHighlight.radiusOf].
///
/// The first shape-defining render object below the node's box wins (the
/// outermost silhouette): a `ClipRRect`, a `BoxDecoration` with a corner
/// radius or the circle shape, a `ClipOval`, or a physical model. The
/// detected radius is scaled by the item's focus lift so it matches the
/// scaled rect the highlight frames.
double? _detectShapeRadius(FocusNode node) {
  final BuildContext? nodeContext = node.context;
  if (nodeContext == null || !nodeContext.mounted) {
    return null;
  }
  final RenderObject? renderObject = nodeContext.findRenderObject();
  if (renderObject == null || !renderObject.attached) {
    return null;
  }
  // Directional corners resolve per the app's text direction.
  final TextDirection direction =
      Directionality.maybeOf(nodeContext) ?? TextDirection.ltr;
  final double? detected = _searchShapeRadius(renderObject, 0, direction);
  if (detected == null) {
    return null;
  }
  final double scale =
      DpadMarks.visualScale[DpadMarks.itemOf(node) ?? node] ?? 1.0;
  return detected * scale;
}

/// How deep the silhouette walker digs before giving up — shape hints live
/// near the top of an item's subtree.
const int _kShapeSearchDepth = 8;

double? _searchShapeRadius(
  RenderObject object,
  int depth,
  TextDirection direction,
) {
  if (depth > _kShapeSearchDepth) {
    return null;
  }
  double? radius;
  if (object is RenderClipRRect) {
    radius = object.borderRadius.resolve(direction).topLeft.x;
  } else if (object is RenderClipOval) {
    radius = object.size.shortestSide / 2;
  } else if (object is RenderDecoratedBox) {
    final Decoration decoration = object.decoration;
    if (decoration is BoxDecoration) {
      radius = decoration.shape == BoxShape.circle
          ? object.size.shortestSide / 2
          : decoration.borderRadius?.resolve(direction).topLeft.x;
    } else if (decoration is ShapeDecoration) {
      radius = _shapeBorderRadius(decoration.shape, object.size, direction);
    }
  } else if (object is RenderPhysicalModel) {
    radius = object.shape == BoxShape.circle
        ? object.size.shortestSide / 2
        : object.borderRadius?.resolve(direction).topLeft.x;
  } else if (object is RenderPhysicalShape) {
    // Material(shape:) — and with it Material 3's default Card — clips
    // through a shape border clipper rather than a physical model.
    final CustomClipper<Path>? clipper = object.clipper;
    radius = clipper is ShapeBorderClipper
        ? _shapeBorderRadius(clipper.shape, object.size, direction)
        : null;
  }
  if (radius != null && radius > 0) {
    return radius;
  }
  double? found;
  object.visitChildren((RenderObject child) {
    found ??= _searchShapeRadius(child, depth + 1, direction);
  });
  return found;
}

/// The uniform corner radius a [ShapeBorder] implies — circles round all
/// the way, rounded rectangles to their own corners.
double? _shapeBorderRadius(
  ShapeBorder? border,
  Size size,
  TextDirection direction,
) {
  if (border is CircleBorder) {
    return size.shortestSide / 2;
  }
  if (border is RoundedRectangleBorder) {
    return border.borderRadius.resolve(direction).topLeft.x;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Overlay (internal)
// ---------------------------------------------------------------------------

/// Internal link between a [Dpad] root and its highlight overlay — the
/// root's way to wake the tracker (scrolling, press changes) and to deliver
/// edge-bounce nudges for blocked moves.
class DpadHighlightHost {
  _DpadHighlightOverlayState? _overlay;

  void _attach(_DpadHighlightOverlayState state) {
    _overlay = state;
  }

  void _detach(_DpadHighlightOverlayState state) {
    if (identical(_overlay, state)) {
      _overlay = null;
    }
  }

  /// Wakes the overlay's per-frame tracker.
  void wake() => _overlay?._wake();

  /// Bounces the highlight towards [direction] — feedback for a move that
  /// was blocked by an edge.
  void nudge(TraversalDirection direction) => _overlay?._nudge(direction);

  /// Whether a scrollable built at [context] contains the tracked item —
  /// the only scrolls that can move it.
  bool touches(BuildContext? context) =>
      _overlay?._scrollTouches(context) ?? false;
}

/// The flying highlight layer mounted by a [Dpad] root. Internal.
class DpadHighlightOverlay extends StatefulWidget {
  /// Creates the overlay for a [Dpad] root.
  const DpadHighlightOverlay({
    super.key,
    required this.host,
    required this.owner,
    required this.defaultHighlight,
  });

  /// Identifies the rendered highlight content; a hook for tests and
  /// inspections.
  static const Key contentKey = ValueKey<String>('dpad.highlight');

  /// The root's bridge to this overlay.
  final DpadHighlightHost host;

  /// The controller of the owning [Dpad] root, used to keep nested roots
  /// from painting a highlight over each other's items.
  final DpadController owner;

  /// [Dpad.highlight] — the root-level default configuration.
  final DpadHighlight? defaultHighlight;

  @override
  State<DpadHighlightOverlay> createState() => _DpadHighlightOverlayState();
}

class _DpadHighlightOverlayState extends State<DpadHighlightOverlay>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final AnimationController _flight = AnimationController(vsync: this);
  late final AnimationController _appear = AnimationController(vsync: this);
  late final AnimationController _nudgeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final Ticker _ticker = createTicker(_onTick);

  /// The node the highlight is tracking, when it belongs to this root.
  FocusNode? _target;

  /// The node the current flight started from —
  /// [DpadHighlightState.fromNode]. `null` when the highlight materialized
  /// in place, and after fading out.
  FocusNode? _fromNode;

  /// The configuration resolved for [_target]; `null` hides the highlight.
  DpadHighlight? _config;

  /// The rect currently on screen, in this overlay's coordinate space.
  Rect? _displayed;

  /// The corner radius currently on screen, morphing between the shapes of
  /// the flight's endpoints.
  double? _displayedRadius;

  /// Where the current flight started from.
  Rect? _flightFrom;

  /// The corner radius the current flight started from.
  double? _radiusFrom;

  /// A focus change is waiting for the target's geometry (a route still
  /// building) — fly there as soon as it exists, instead of teleporting.
  bool _flightPending = false;

  /// The target geometry seen by the previous tick — the sleep check
  /// requires the target itself to have stopped moving, not just the
  /// highlight to have caught up (a gluing highlight always matches a
  /// target that is still sliding in with its route).
  ({Rect rect, double? radius})? _lastTarget;

  /// Focus is gone (or landed on an unconfigured target): the highlight is
  /// fading out in its last style, and the dismissed handler will clean up.
  bool _wantsHidden = false;

  /// The pressed state last painted — pressed changes arrive via the marks,
  /// so the tick loop compares against this to decide whether to rebuild.
  bool _pressed = false;

  /// The node the highlight was last shown for — the guard that keeps a
  /// re-reported focus event (a root rebuild, scope churn) from
  /// restarting a finished flight from standstill.
  FocusNode? _shownNode;

  /// Cached silhouette walk, keyed on the tracked node and its layout
  /// size (see [_shapeRadiusOf]).
  FocusNode? _radiusNode;
  Size? _radiusNodeSize;
  double? _radiusValue;

  /// Direction of the edge bounce in progress (unit vector), if any.
  Offset _nudgeDirection = Offset.zero;

  /// The bounce offset currently applied to the painted rect.
  Offset _nudgeVector = Offset.zero;

  int _stableFrames = 0;
  int _unmeasuredFrames = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_handleFocusChange);
    _appear.addStatusListener(_handleAppearStatus);
    widget.host._attach(this);
    // Autofocus below may have landed before this overlay was mounted; take
    // stock once the first frame has built the tree it points into.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleFocusChange();
      }
    });
  }

  @override
  void didUpdateWidget(DpadHighlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.defaultHighlight != oldWidget.defaultHighlight) {
      // The root-level default changed (e.g. a settings toggle): re-resolve
      // for the current target.
      _handleFocusChange();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.host._detach(this);
    FocusManager.instance.removeListener(_handleFocusChange);
    WidgetsBinding.instance.removeObserver(this);
    _flight.dispose();
    _appear.dispose();
    _nudgeController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _wake();
  }

  // ---------------------------------------------------------------------
  // Focus tracking
  // ---------------------------------------------------------------------

  void _handleFocusChange() {
    FocusNode? node = FocusManager.instance.primaryFocus;
    if (node is FocusScopeNode) {
      node = null;
    }
    if (node != null) {
      final BuildContext? nodeContext = node.context;
      // Foreign nodes (inside a nested Dpad) belong to that root's overlay.
      if (nodeContext == null ||
          !nodeContext.mounted ||
          Dpad.maybeOf(nodeContext) != widget.owner) {
        node = null;
      }
    }
    final FocusNode? previous = _target;
    _target = node;
    // A flight starts from wherever the highlight was last anchored —
    // `null` on first appearance, the old target on chained retargets, and
    // the node the fade-out is still painting when focus returns before it
    // finished (so custom effects blending from [fromNode] keep a real
    // origin instead of a `null` flash).
    _applyTarget(
      fromNode: node != null && !identical(node, previous) && _displayed != null
          ? previous ?? _shownNode
          : null,
    );
  }

  /// Resolves the configuration for wherever focus now stands: item
  /// override, then the closest [DpadHighlightTheme], then the root's
  /// [Dpad.highlight].
  DpadHighlight? _resolveFor(FocusNode node) {
    final FocusNode? item = DpadMarks.itemOf(node);
    final DpadHighlight? itemStyle =
        item == null ? null : DpadMarks.highlightStyle[item];
    if (itemStyle != null) {
      return itemStyle;
    }
    final BuildContext? nodeContext = node.context;
    if (nodeContext != null && nodeContext.mounted) {
      final DpadHighlightTheme? scope =
          nodeContext.getInheritedWidgetOfExactType<DpadHighlightTheme>();
      if (scope != null) {
        return scope.data;
      }
    }
    return widget.defaultHighlight;
  }

  void _applyTarget({FocusNode? fromNode}) {
    final FocusNode? node = _target;
    if (node == null) {
      _fadeOut();
      return;
    }
    final DpadHighlight? config = _resolveFor(node);
    if (config == null) {
      // Focus landed where no highlight is configured: stop tracking it
      // (the painted state's node and visible follow the target) and fade
      // out in the style the user was just looking at — the last resolved
      // config keeps painting until the fade completes.
      _target = null;
      _fromNode = null;
      _fadeOut();
      return;
    }
    if (!_wantsHidden &&
        _displayed != null &&
        identical(node, _shownNode) &&
        config == _config) {
      // The same target re-reported with the same look (a root rebuild, a
      // focus-tree event): keep the current flight instead of restarting
      // it from standstill.
      _wake();
      return;
    }
    _wantsHidden = false;
    _fromNode = fromNode;
    _config = config;
    _appear.duration = config.appearDuration;
    final Rect? target = _measure(node, config);
    if (target == null) {
      // Not laid out yet (the focus change outran the route's first frame —
      // the tick loop takes over as soon as geometry exists).
      _unmeasuredFrames = 0;
      _flightPending = _displayed != null;
      _wake();
      return;
    }
    _showAt(target, _detectShapeRadius(node), config);
  }

  void _showAt(Rect target, double? radius, DpadHighlight config) {
    _shownNode = _target;
    _flightPending = false;
    if (_displayed == null) {
      // First appearance: materialize in place, no flight.
      _displayed = target;
      _displayedRadius = radius;
      _flightFrom = target;
      _radiusFrom = radius;
      _flight.duration = config.duration;
      _flight.value = 1.0;
    } else {
      // Fly from wherever the highlight currently is. Retargeting mid-flight
      // keeps the motion continuous when keys outrun the animation; the
      // corner radius morphs along with the rect.
      _flightFrom = _displayed;
      _radiusFrom = _displayedRadius ?? radius;
      _flight.duration = config.duration;
      _flight.forward(from: 0.0);
    }
    _appear.forward();
    _unmeasuredFrames = 0;
    if (mounted) {
      // The fields above changed outside a tick — this build is what first
      // puts the effect stack on screen (the tick loop's own setState is
      // skipped on unchanged frames).
      setState(() {});
    }
    _wake();
  }

  /// Starts the fade-out. The last resolved config keeps painting until the
  /// fade completes; the [AnimationStatus.dismissed] handler cleans up.
  void _fadeOut() {
    if (_displayed == null) {
      _config = null;
      _wantsHidden = false;
      _radiusNode = null;
      if (mounted) {
        setState(() {});
      }
      return;
    }
    _wantsHidden = true;
    // The motion is over — land the flight and cancel any bounce so the
    // ticker has nothing left to compute while the fade runs.
    _flight.stop();
    _nudgeController
      ..stop()
      ..value = 0.0;
    _fromNode = null;
    _radiusNode = null;
    _appear.reverse();
    if (mounted) {
      // One rebuild so effects see the fade-out begin: landed (t == 1.0),
      // no node, [DpadHighlightState.visible] already `false`. The
      // opacity then animates on without further rebuilds.
      setState(() {});
    }
    _wake();
  }

  void _handleAppearStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _wantsHidden) {
      // Faded out after focus was lost (or landed on an unconfigured
      // target): forget everything so the next appearance fades in fresh
      // instead of flying from a stale rect.
      _displayed = null;
      _flightFrom = null;
      _radiusFrom = null;
      _fromNode = null;
      _shownNode = null;
      _radiusNode = null;
      _config = null;
      _wantsHidden = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  // ---------------------------------------------------------------------
  // Geometry
  // ---------------------------------------------------------------------

  /// The tracked node's rect in this overlay's coordinate space, inflated
  /// by the item's focus scale and the configuration's padding. `null` when
  /// not currently measurable.
  Rect? _measure(FocusNode node, DpadHighlight config) {
    final BuildContext? nodeContext = node.context;
    if (nodeContext == null || !nodeContext.mounted) {
      return null;
    }
    final RenderObject? nodeObject = nodeContext.findRenderObject();
    final RenderObject? overlayObject = context.findRenderObject();
    if (nodeObject is! RenderBox ||
        !nodeObject.attached ||
        !nodeObject.hasSize ||
        overlayObject is! RenderBox ||
        !overlayObject.attached ||
        !overlayObject.hasSize) {
      return null;
    }
    // One transform chain walk (node → overlay) — two global round-trips
    // would walk the chain to the root and invert the matrix twice.
    final Rect local = MatrixUtils.transformRect(
      nodeObject.getTransformTo(overlayObject),
      Offset.zero & nodeObject.size,
    );
    // Frame the scaled visual: a lifted item (DpadScaleEffect) grows around
    // its center beyond its layout rect, and the un-scaled rect would cut
    // into the card.
    final FocusNode? item = DpadMarks.itemOf(node);
    final double scale =
        item == null ? 1.0 : (DpadMarks.visualScale[item] ?? 1.0);
    final Rect visual = scale == 1.0
        ? local
        : Rect.fromCenter(
            center: local.center,
            width: local.width * scale,
            height: local.height * scale,
          );
    return config.padding.inflateRect(visual);
  }

  // ---------------------------------------------------------------------
  // Frame loop
  // ---------------------------------------------------------------------

  void _wake() {
    if (!mounted) {
      return;
    }
    _stableFrames = 0;
    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _nudge(TraversalDirection direction) {
    final DpadHighlight? config = _config;
    if (config == null ||
        _wantsHidden ||
        config.nudgeOffset <= 0.0 ||
        _displayed == null) {
      return;
    }
    if (_nudgeController.isAnimating) {
      // A repeat while the previous bounce is still running must not
      // restart it from zero — that reads as a stutter, not a rhythm. Let
      // the arc finish; the next repeat starts the next bounce.
      return;
    }
    _nudgeDirection = switch (direction) {
      TraversalDirection.up => const Offset(0, -1),
      TraversalDirection.down => const Offset(0, 1),
      TraversalDirection.left => const Offset(-1, 0),
      TraversalDirection.right => const Offset(1, 0),
    };
    _nudgeController.forward(from: 0.0);
    _wake();
  }

  void _onTick(Duration elapsed) {
    final FocusNode? node = _target;
    final DpadHighlight? config = _config;

    final Rect? before = _displayed;
    final double? beforeRadius = _displayedRadius;

    // Measured once per tick and reused by the flight, the glue and the
    // sleep check below.
    Rect? target;
    double? radius;
    if (node != null && config != null && !_wantsHidden) {
      target = _measure(node, config);
      if (target == null) {
        // A first appearance waits longer than a tracked highlight that
        // went dark: slow first route frames are normal on low-end TVs,
        // while a defunct or offstage target never comes back.
        if (++_unmeasuredFrames > (_displayed == null ? 120 : 30)) {
          _target = null;
          _fadeOut();
        }
      } else {
        _unmeasuredFrames = 0;
        radius = _shapeRadiusOf(node);
        if (_displayed == null || _flightPending) {
          // First appearance, or geometry for a focus change that arrived
          // early (a route still building) — fly/materialize there.
          _showAt(target, radius, config);
        } else if (_flight.isAnimating) {
          // Both endpoints are re-measured every frame: the flight follows
          // the target and its origin through scrolls and route
          // transitions while it runs — a scrolling list moves the
          // takeoff item too, and a frozen origin would cut across the
          // content. The corner radius morphs between the endpoint shapes.
          final double t = config.curve.transform(_flight.value);
          final Rect from =
              (_fromNode != null ? _measure(_fromNode!, config) : null) ??
                  _flightFrom!;
          _displayed = Rect.lerp(from, target, t)!;
          _displayedRadius = _lerpRadius(_radiusFrom, radius, t);
        } else {
          // No flight: glue to the target so drift never accumulates.
          _displayed = target;
          _displayedRadius = radius;
        }
      }
    }

    final FocusNode? item = node == null ? null : DpadMarks.itemOf(node);
    final bool pressed = item != null && (DpadMarks.pressed[item] ?? false);

    // Edge bounce: out and back, peaking mid-way.
    final double bounce = config?.nudgeOffset ?? 0.0;
    final Offset nudgeVector = bounce <= 0.0
        ? Offset.zero
        : _nudgeDirection *
            (bounce *
                math.sin(
                  math.pi * _nudgeController.value.clamp(0.0, 1.0),
                ));

    // Skip the rebuild entirely on a frame where nothing moved — the
    // steady state costs nothing even while the ticker finishes settling.
    // A press change alone still rebuilds: it arrives through the marks,
    // not through any of the geometry above.
    if (mounted &&
        (_displayed != before ||
            _displayedRadius != beforeRadius ||
            nudgeVector != _nudgeVector ||
            pressed != _pressed)) {
      setState(() {
        _nudgeVector = nudgeVector;
        _pressed = pressed;
      });
    }

    _maybeStopTicker(target, radius);
  }

  /// [DpadHighlight.radiusOf] for the tracked node, memoized on the
  /// node and its layout size — the walk digs through the item's render
  /// subtree, and without this it would run on every frame the ticker is
  /// awake (scroll-following being the long-lived case). A same-size
  /// reshape while tracking keeps the old corners until the next focus
  /// change, matching the asleep steady state.
  double? _shapeRadiusOf(FocusNode node) {
    final Size? size = _layoutSizeOf(node);
    if (identical(node, _radiusNode) && _radiusNodeSize == size) {
      return _radiusValue;
    }
    _radiusNode = node;
    _radiusNodeSize = size;
    return _radiusValue = _detectShapeRadius(node);
  }

  /// The node's layout size — the cache key for [_shapeRadiusOf]: constant
  /// through transforms and scrolls, unlike the measured rect.
  static Size? _layoutSizeOf(FocusNode node) {
    final RenderObject? object = node.context?.findRenderObject();
    if (object is! RenderBox || !object.attached || !object.hasSize) {
      return null;
    }
    return object.size;
  }

  /// Whether the scrollable built at [scrollContext] contains the tracked
  /// item (see [DpadHighlightHost.touches]).
  bool _scrollTouches(BuildContext? scrollContext) {
    final BuildContext? targetContext = _target?.context;
    if (scrollContext == null ||
        targetContext == null ||
        !targetContext.mounted) {
      return false;
    }
    bool touches = false;
    targetContext.visitAncestorElements((Element ancestor) {
      if (identical(ancestor, scrollContext)) {
        touches = true;
        return false;
      }
      return true;
    });
    return touches;
  }

  void _maybeStopTicker(Rect? target, double? radius) {
    final bool animating = _flight.isAnimating ||
        _appear.isAnimating ||
        _nudgeController.isAnimating;
    bool settled = !animating;
    if (settled && _target != null && _config != null && !_wantsHidden) {
      settled = _displayed != null &&
          target != null &&
          _rectNear(_displayed!, target) &&
          _radiusNear(_displayedRadius, radius) &&
          (_lastTarget == null ||
              (_rectNear(_lastTarget!.rect, target) &&
                  _radiusNear(_lastTarget!.radius, radius)));
      _lastTarget = target == null ? null : (rect: target, radius: radius);
    } else if (settled && _displayed != null) {
      settled = false; // Still fading out.
    }
    if (!settled) {
      _stableFrames = 0;
    } else if (++_stableFrames >= 3) {
      _ticker.stop();
    }
  }

  /// Morphs the corner radius between the flight's endpoint shapes; an
  /// unknown endpoint shape jumps instead of lerping from a fallback.
  static double? _lerpRadius(double? from, double? to, double t) {
    if (from == null || to == null) {
      return to;
    }
    return from + (to - from) * t;
  }

  static bool _radiusNear(double? a, double? b) {
    if (a == null || b == null) {
      return a == null && b == null;
    }
    return (a - b).abs() < 0.5;
  }

  static bool _rectNear(Rect a, Rect b) {
    return (a.topLeft - b.topLeft).distanceSquared < 0.25 &&
        (a.width - b.width).abs() < 0.5 &&
        (a.height - b.height).abs() < 0.5;
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final DpadHighlight? config = _config;
    final Rect? displayed = _displayed;
    if (config == null || displayed == null) {
      return const SizedBox.shrink();
    }
    final FocusNode? node = _target;
    final DpadHighlightState state = DpadHighlightState(
      rect: displayed.shift(_nudgeVector),
      visible: node != null,
      pressed: _pressed,
      // The item's own focusable node even when focus sits on a wrapped
      // inner target (excludeChildFocus: false) — the handle effects
      // want. `null` while the highlight fades out.
      node: node == null ? null : DpadMarks.itemOf(node) ?? node,
      fromNode: _fromNode == null
          ? null
          : DpadMarks.itemOf(_fromNode!) ?? _fromNode,
      t: _flight.isAnimating
          ? config.curve.transform(_flight.value)
          : 1.0,
      radius: _displayedRadius,
    );
    return IgnorePointer(
      child: RepaintBoundary(
        child: FadeTransition(
          opacity: _appear,
          child: Stack(
            key: DpadHighlightOverlay.contentKey,
            textDirection: TextDirection.ltr,
            children: <Widget>[
              for (final DpadHighlightEffect effect in config.effects)
                effect.build(context, state),
            ],
          ),
        ),
      ),
    );
  }
}
