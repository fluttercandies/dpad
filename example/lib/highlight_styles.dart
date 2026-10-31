import 'dart:math' as math;

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

/// The demo's focus-presentation catalog, cycled from the Settings section.
/// Index 0 is the classic per-item effects (no flying highlight); the rest
/// are flying-highlight looks — the shipped effects in their natural
/// combinations, motion knobs, and custom effects driving their paint from
/// the live [DpadHighlightState] (timeline, trail history, gradients).
const List<String> highlightChoices = <String>[
  'Classic',
  'Flying ring',
  'Flying brackets + glow',
  'Flying spotlight',
  'Vignette + ring',
  'Springy ring',
  'Flight color lerp (custom)',
  'Neon glow',
  'Comet trail (custom)',
  'Rainbow sweep (custom)',
  'Chrome sweep (custom)',
  'Pinned corners',
  'Item-hued flight (custom)',
  'Press-reactive (custom)',
  'Cinematic fade',
];

/// The [Dpad.highlight] configuration for [highlightChoices]`[style]` —
/// `null` for the classic look.
///
/// The custom looks are built once into top-level objects (not inline in
/// the switch) so a root rebuild hands the highlight the *same* instance
/// and the engine's same-look guard keeps a landed flight landed.
DpadHighlight? highlightFor(int style) {
  return switch (style) {
    // Classic per-item effects — the flying highlight stays off.
    0 => null,
    // The tvOS default: an adaptive ring that hugs each item's shape.
    1 => const DpadHighlight(nudgeOffset: 8),
    // The game look: a glow under reticle brackets.
    2 => const DpadHighlight(
          nudgeOffset: 8,
          effects: <DpadHighlightEffect>[
            DpadHighlightGlowEffect(opacity: 0.35),
            DpadHighlightBracketsEffect(length: 26),
          ],
        ),
    // The "on" look: a translucent fill under a thin ring.
    3 => const DpadHighlight(
          effects: <DpadHighlightEffect>[
            DpadHighlightSpotlightEffect(opacity: 0.18),
            DpadHighlightRingEffect(width: 2),
          ],
        ),
    // The character-select look: everything outside the item dims away.
    4 => const DpadHighlight(
          effects: <DpadHighlightEffect>[
            DpadHighlightVignetteEffect(opacity: 0.45),
            DpadHighlightRingEffect(width: 2),
          ],
        ),
    // Motion knobs: an overshooting landing plus a press squash.
    5 => const DpadHighlight(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          nudgeOffset: 8,
          effects: <DpadHighlightEffect>[
            DpadHighlightRingEffect(width: 3, pressedScale: 0.97),
          ],
        ),
    // The escape hatch, smallest version: blend the ring color from the
    // flight timeline (state.t drives the lerp, so the hue sweeps with
    // every move and settles on the destination's).
    6 => _colorLerpHighlight,
    // Layered glows around a bright core — the neon sign.
    7 => const DpadHighlight(
          nudgeOffset: 8,
          effects: <DpadHighlightEffect>[
            DpadHighlightGlowEffect(
                blurRadius: 34, spreadRadius: 7, opacity: 0.45),
            DpadHighlightGlowEffect(
                blurRadius: 12, spreadRadius: 2, opacity: 0.75),
            DpadHighlightRingEffect(color: Color(0xFFFFFFFF), width: 1.5),
          ],
        ),
    // The comet: the engine hands the effect the live rect every flight
    // frame, so a small history buffer paints fading ghosts behind it.
    8 => _cometHighlight,
    // The rainbow: the hue rides the flight timeline, twice around.
    9 => _rainbowHighlight,
    // The chrome sweep: a gradient ring whose shader rotates exactly once
    // per flight (t == 1.0 restores the takeoff orientation).
    10 => _chromeHighlight,
    // Pinned corners: shape-following off — an explicit radius that every
    // item shares, regardless of its own silhouette.
    11 => const DpadHighlight(
          nudgeOffset: 8,
          effects: <DpadHighlightEffect>[
            DpadHighlightSpotlightEffect(opacity: 0.12, borderRadius: 4),
            DpadHighlightRingEffect(borderRadius: 4, width: 2.5),
          ],
        ),
    // Per-item data: every node carries its own hue (here hashed; a real
    // app looks up its model), and the flight blends origin hue into
    // destination hue — node, fromNode and t together.
    12 => _itemHuedHighlight,
    // The press state beyond scale: hold SELECT and the ring thickens
    // while the glow flares.
    13 => _pressReactiveHighlight,
    // The appear knob: a slow cinematic fade-in/out over a slower flight.
    14 => const DpadHighlight(
          duration: Duration(milliseconds: 280),
          appearDuration: Duration(milliseconds: 420),
          nudgeOffset: 8,
          effects: <DpadHighlightEffect>[
            DpadHighlightGlowEffect(opacity: 0.4),
            DpadHighlightRingEffect(width: 2),
          ],
        ),
    _ => throw ArgumentError('No highlight look for style $style'),
  };
}

final DpadHighlight _colorLerpHighlight = DpadHighlight(
  nudgeOffset: 8,
  effects: <DpadHighlightEffect>[
    DpadHighlightCustomEffect(
      (BuildContext context, DpadHighlightState state) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final Color color =
            Color.lerp(scheme.primary, scheme.tertiary, state.t)!;
        return DpadHighlightRingEffect(color: color).build(context, state);
      },
    ),
  ],
);

/// The last few rects the comet effect has seen — its fading trail. Bounded
/// and converging on the item at rest, so it never paints at standstill.
final List<Rect> _cometTrail = <Rect>[];

final DpadHighlight _cometHighlight = DpadHighlight(
  duration: const Duration(milliseconds: 170),
  nudgeOffset: 8,
  effects: <DpadHighlightEffect>[
    DpadHighlightCustomEffect(
      (BuildContext context, DpadHighlightState state) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        // A jump no flight could produce means the trail is stale (the
        // look was switched off and back on elsewhere) — start it over
        // instead of ghosting across the screen.
        if (_cometTrail.isNotEmpty &&
            (_cometTrail.last.center - state.rect.center).distanceSquared >
                100.0 * 100.0) {
          _cometTrail.clear();
        }
        _cometTrail.add(state.rect);
        if (_cometTrail.length > 6) {
          _cometTrail.removeAt(0);
        }
        return Positioned.fill(
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              // Older ghosts fade out; converged ones (at rest) vanish.
              for (int i = 0; i < _cometTrail.length - 1; i++)
                if ((_cometTrail[i].center - state.rect.center).distance > 2.0)
                  Positioned.fromRect(
                    rect: _cometTrail[i],
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          (state.radius ?? 12.0)
                              .clamp(0.0, _cometTrail[i].shortestSide / 2),
                        ),
                        border: Border.all(
                          color: scheme.primary.withAlpha(
                            ((i + 1) / _cometTrail.length * 0.30 * 255)
                                .round(),
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              const DpadHighlightRingEffect().build(context, state),
            ],
          ),
        );
      },
    ),
  ],
);

final DpadHighlight _rainbowHighlight = DpadHighlight(
  duration: const Duration(milliseconds: 260),
  nudgeOffset: 8,
  effects: <DpadHighlightEffect>[
    DpadHighlightCustomEffect(
      (BuildContext context, DpadHighlightState state) {
        final Color color = HSVColor.fromAHSV(
          1.0,
          (state.t * 720.0) % 360.0,
          0.75,
          1.0,
        ).toColor();
        return Positioned.fill(
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              DpadHighlightGlowEffect(
                color: color,
                blurRadius: 24,
                spreadRadius: 3,
                opacity: 0.7,
              ).build(context, state),
              DpadHighlightRingEffect(color: color, width: 2.5)
                  .build(context, state),
            ],
          ),
        );
      },
    ),
  ],
);

final DpadHighlight _chromeHighlight = DpadHighlight(
  nudgeOffset: 8,
  padding: const EdgeInsets.all(3),
  effects: <DpadHighlightEffect>[
    DpadHighlightCustomEffect(
      (BuildContext context, DpadHighlightState state) {
        return state.positioned(
          CustomPaint(
            painter: _ChromeRingPainter(
              radius: (state.radius ?? 12.0)
                  .clamp(0.0, state.rect.shortestSide / 2),
              t: state.t,
            ),
          ),
        );
      },
    ),
  ],
);

final DpadHighlight _itemHuedHighlight = DpadHighlight(
  nudgeOffset: 8,
  effects: <DpadHighlightEffect>[
    DpadHighlightCustomEffect(
      (BuildContext context, DpadHighlightState state) {
        final Color color =
            Color.lerp(_hueOf(state.fromNode), _hueOf(state.node), state.t)!;
        return Positioned.fill(
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              DpadHighlightGlowEffect(
                color: color,
                blurRadius: 20,
                spreadRadius: 2,
                opacity: 0.6,
              ).build(context, state),
              DpadHighlightRingEffect(color: color, width: 2.5)
                  .build(context, state),
            ],
          ),
        );
      },
    ),
  ],
);

/// A stable-per-session hue for [node] — the stand-in for a real app's
/// per-item data (look up your model the same way).
Color _hueOf(FocusNode? node) {
  if (node == null) {
    return const Color(0xFFFFFFFF);
  }
  return HSVColor.fromAHSV(
    1.0,
    (node.hashCode % 360).toDouble(),
    0.7,
    1.0,
  ).toColor();
}

final DpadHighlight _pressReactiveHighlight = DpadHighlight(
  nudgeOffset: 8,
  effects: <DpadHighlightEffect>[
    DpadHighlightCustomEffect(
      (BuildContext context, DpadHighlightState state) {
        final bool held = state.pressed;
        return Positioned.fill(
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              DpadHighlightGlowEffect(
                blurRadius: held ? 34 : 16,
                spreadRadius: held ? 4 : 2,
                opacity: held ? 0.9 : 0.45,
              ).build(context, state),
              DpadHighlightRingEffect(width: held ? 4 : 2.5)
                  .build(context, state),
            ],
          ),
        );
      },
    ),
  ],
);

/// Paints the highlight rect as a gradient stroke, rotated by the flight
/// progress — one full sweep per flight, back to the takeoff orientation
/// when landed.
class _ChromeRingPainter extends CustomPainter {
  const _ChromeRingPainter({required this.radius, required this.t});

  final double radius;
  final double t;

  static const List<Color> _colors = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFF8AE9FF),
    Color(0xFFFFC8F0),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const double inset = 1.75; // Half the stroke, so it hugs the bounds.
    final RRect rrect = RRect.fromRectAndRadius(
      rect.deflate(inset),
      Radius.circular(radius.clamp(0.0, rect.shortestSide / 2)),
    );
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..shader = const SweepGradient(colors: _colors)
          .createShader(rect, textDirection: TextDirection.ltr);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(t * 2.0 * math.pi);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawRRect(rrect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChromeRingPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.t != t;
}
