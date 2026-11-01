import 'dart:ui' show lerpDouble;

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

/// The rect of the focusable showing [id].
Rect itemRect(WidgetTester tester, String id) {
  return tester.getRect(
    find
        .ancestor(of: find.text(id), matching: find.byType(DpadFocusable))
        .first,
  );
}

/// The rect of the flying ring.
Rect ringRect(WidgetTester tester) {
  return tester.getRect(find.byKey(DpadHighlightRingEffect.debugKey));
}

/// The adaptive corner radius the ring is painting right now.
double ringRadius(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.byKey(DpadHighlightRingEffect.debugKey),
  );
  final BoxDecoration decoration = box.decoration as BoxDecoration;
  return decoration.borderRadius!
      .resolve(TextDirection.ltr)
      .topLeft
      .x;
}

/// A focusable whose silhouette is a rounded box of [radius].
Widget roundedItem(
  String id,
  FocusNode node, {
  required double radius,
  double width = 80,
  double height = 60,
  bool autofocus = false,
}) {
  return DpadFocusable(
    focusNode: node,
    autofocus: autofocus,
    effects: const <DpadEffect>[],
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: Center(child: Text(id)),
        ),
      ),
    ),
  );
}

/// Pumps short steps until the highlight leaves [from] towards [to], then
/// returns where it currently is. Test-frame arithmetic delays when the
/// flight's clock starts by a frame or two; stepping until motion appears
/// keeps the mid-flight assertions about geometry, not frame bookkeeping.
Future<Rect> pumpMidFlight(
  WidgetTester tester,
  Rect Function(WidgetTester tester) rectOf,
  Rect from,
  Rect to,
) async {
  Rect current = from;
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    current = rectOf(tester);
    if (current.left > from.left + 0.5 && current.left < to.left - 0.5) {
      break;
    }
  }
  return current;
}

void main() {
  group('flight', () {
    testWidgets('slides from item to item and lands on the target',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Row(children: <Widget>[
          item('a', a, autofocus: true),
          item('b', b),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'a'),
          reason: 'The highlight starts on the autofocused item.');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      final Rect mid = await pumpMidFlight(
        tester,
        ringRect,
        itemRect(tester, 'a'),
        itemRect(tester, 'b'),
      );
      expect(
        mid.left,
        allOf(
          greaterThan(itemRect(tester, 'a').left),
          lessThan(itemRect(tester, 'b').left),
        ),
        reason: 'While the flight is running the ring sits between A and B.',
      );

      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'b'),
          reason: 'The flight ends exactly on the new target.');
    });

    testWidgets('retargets mid-flight when keys outrun the animation',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      final FocusNode c = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Row(children: <Widget>[
          item('a', a, autofocus: true),
          item('b', b),
          item('c', c),
        ]),
      ));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(ringRect(tester), itemRect(tester, 'c'),
          reason: 'A second press mid-flight chains towards the new target.');
    });

    testWidgets('a retarget mid-flight continues from where the ring is',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      final FocusNode c = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Align(
          alignment: Alignment.topLeft,
          child: Row(children: <Widget>[
            item('a', a, autofocus: true),
            const SizedBox(width: 100),
            item('b', b),
            const SizedBox(width: 100),
            item('c', c),
          ]),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      final Rect mid = await pumpMidFlight(
        tester,
        ringRect,
        itemRect(tester, 'a'),
        itemRect(tester, 'b'),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      double previous = mid.left;
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        final double left = ringRect(tester).left;
        expect(left - previous, lessThan(40.0),
            reason: 'No frame may teleport the ring onto B: the new flight '
                'takes off from the mid-flight rect on screen.');
        previous = left;
      }
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'c'));
    });

    testWidgets('a sleeping ring follows a reflow that moves the item',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final ValueNotifier<bool> inserted = ValueNotifier<bool>(false);
      addTearDown(inserted.dispose);
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: ValueListenableBuilder<bool>(
          valueListenable: inserted,
          builder: (BuildContext context, bool on, Widget? child) =>
              Column(children: <Widget>[
            if (on) const SizedBox(height: 120),
            item('a', a, autofocus: true),
          ]),
        ),
      ));
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'a'));

      // Data arrives and a row appears above: no focus, scroll or metrics
      // event reaches the highlight.
      inserted.value = true;
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'a'),
          reason: 'The asleep tracker notices the item moved and re-glues.');
    });

    testWidgets('materializes in place on first appearance',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Center(child: item('a', a, autofocus: true)),
      ));
      await tester.pump(const Duration(milliseconds: 75));
      expect(ringRect(tester), itemRect(tester, 'a'),
          reason: 'While fading in, the highlight already sits on the item '
              'instead of flying in from elsewhere.');
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'a'));
    });

    testWidgets('fades out and disappears when focus is lost',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        restoreFocus: false,
        home: Center(child: item('a', a, autofocus: true)),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsOneWidget);

      Dpad.of(tester.element(find.text('a'))).clearFocus();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsNothing,
          reason: 'Losing focus fades the highlight out.');
    });

    testWidgets('inflates the rect by the configured padding',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(padding: EdgeInsets.all(6)),
        home: Center(child: item('a', a, autofocus: true)),
      ));
      await tester.pumpAndSettle();
      final Rect ring = ringRect(tester);
      final Rect inner = itemRect(tester, 'a');
      expect(ring.width, closeTo(inner.width + 12, 0.5));
      expect(ring.height, closeTo(inner.height + 12, 0.5),
          reason: 'padding: EdgeInsets.all(6) grows the ring by 6 on each '
              'side.');
    });

    testWidgets('frames the scaled visual of a lifted item',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Center(
          child: DpadFocusable(
            focusNode: a,
            autofocus: true,
            effects: const <DpadEffect>[DpadScaleEffect(scale: 1.2)],
            child: const SizedBox(width: 100, height: 50),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final Rect layout = tester.getRect(find.byType(DpadFocusable));
      final Rect scaled = Rect.fromCenter(
        center: layout.center,
        width: layout.width * 1.2,
        height: layout.height * 1.2,
      );
      expect(ringRect(tester), scaled,
          reason: 'The ring frames the scaled visual, not the un-scaled '
              'layout rect, so a lifted card never pokes out of the '
              'highlight.');
    });

    testWidgets('follows the focused item\'s own corner radius',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Row(children: <Widget>[
          roundedItem('a', a, radius: 20, autofocus: true),
          DpadFocusable(
            focusNode: b,
            effects: const <DpadEffect>[],
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFFFFF),
              ),
              child: const Center(child: Text('b')),
            ),
          ),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 20,
          reason: 'A ClipRRect silhouette rounds the ring to match, with '
              'zero configuration.');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 30,
          reason: 'A circular item (60px) rounds the ring into a full '
              'circle.');
    });

    testWidgets('morphs the corner radius during a flight',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Row(children: <Widget>[
          roundedItem('a', a, radius: 8, autofocus: true),
          roundedItem('b', b, radius: 28),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 8);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      // Step until the radius is visibly between the endpoint shapes.
      double radius = 8;
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        radius = ringRadius(tester);
        if (radius > 8.5 && radius < 27.5) {
          break;
        }
      }
      expect(radius, allOf(greaterThan(8.5), lessThan(27.5)),
          reason: 'Mid-flight the radius lerps between the two shapes.');
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 28,
          reason: 'The flight ends on the target shape.');
    });

    testWidgets('items without a measurable shape keep the 12-pixel default',
        (WidgetTester tester) async {
      final FocusNode plain = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Center(
          child: DpadFocusable(
            focusNode: plain,
            autofocus: true,
            effects: const <DpadEffect>[],
            child: const SizedBox(
              width: 80,
              height: 60,
              child: ColoredBox(
                color: Color(0xFFFFFFFF),
                child: Center(child: Text('plain')),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 12,
          reason: 'Nothing shape-defining below the node — the ring keeps '
              'its own default corners.');
    });

    testWidgets('an explicit borderRadius on the effect pins the shape',
        (WidgetTester tester) async {
      final FocusNode pinned = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(
          effects: <DpadHighlightEffect>[
            DpadHighlightRingEffect(
              borderRadius: 15,
            ),
          ],
        ),
        home: Center(
            child: roundedItem('pinned', pinned, radius: 28, autofocus: true)),
      ));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 15,
          reason: 'An explicit effect radius beats the detected shape.');
    });

    testWidgets('followShape: false keeps fixed corners on a rounded item',
        (WidgetTester tester) async {
      final FocusNode rounded = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(
          effects: <DpadHighlightEffect>[
            DpadHighlightRingEffect(followShape: false),
          ],
        ),
        home: Center(
            child: roundedItem('rounded', rounded, radius: 28, autofocus: true)),
      ));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 12,
          reason: 'The explicit switch opts the effect out of shape '
              'following — fixed 12-pixel corners.');
    });

    testWidgets('the timeline drives custom interpolation — t and fromNode',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      final List<(FocusNode?, FocusNode?, double)> seen =
          <(FocusNode?, FocusNode?, double)>[];
      await tester.pumpWidget(tvApp(
        highlight: DpadHighlight(
          effects: <DpadHighlightEffect>[
            DpadHighlightCustomEffect(
                (BuildContext context, DpadHighlightState state) {
              seen.add((state.fromNode, state.node, state.t));
              return const SizedBox.shrink();
            }),
          ],
        ),
        home: Row(children: <Widget>[
          roundedItem('a', a, radius: 20, autofocus: true),
          roundedItem('b', b, radius: 28),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(
        seen.any(((FocusNode?, FocusNode?, double) s) =>
            s.$1 == null && s.$2 == a && s.$3 == 1.0),
        isTrue,
        reason: 'First appearance: no origin node, already settled.',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      bool sawMidFlight = false;
      for (int i = 0; i < 8 && !sawMidFlight; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        sawMidFlight = seen.any(((FocusNode?, FocusNode?, double) s) =>
            s.$1 == a && s.$2 == b && s.$3 > 0.0 && s.$3 < 1.0);
      }
      expect(sawMidFlight, isTrue,
          reason: 'Mid-flight: fromNode is the takeoff item, node the '
              'target, t between the endpoints.');
      await tester.pumpAndSettle();
      expect(
        seen.any(((FocusNode?, FocusNode?, double) s) =>
            s.$2 == b && s.$3 == 1.0),
        isTrue,
        reason: 'Landed: t settles at 1.',
      );
    });

    testWidgets('a custom effect mixes its own shape table with radiusOf',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      final Map<FocusNode, double> table = <FocusNode, double>{a: 16};
      double? shapeOf(FocusNode? node) =>
          node == null ? null : table[node] ?? DpadHighlight.radiusOf(node);
      await tester.pumpWidget(tvApp(
        highlight: DpadHighlight(
          effects: <DpadHighlightEffect>[
            DpadHighlightCustomEffect(
              (BuildContext context, DpadHighlightState state) {
                final double radius =
                    lerpDouble(shapeOf(state.fromNode), shapeOf(state.node),
                            state.t) ??
                        shapeOf(state.node) ??
                        12.0;
                return DpadHighlightRingEffect(borderRadius: radius)
                    .build(context, state);
              },
            ),
          ],
        ),
        home: Row(children: <Widget>[
          roundedItem('a', a, radius: 40, autofocus: true),
          roundedItem('b', b, radius: 28),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 16,
          reason: 'The private table wins where it knows the item.');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 28,
          reason: 'Unknown to the table, the item falls back to the '
              'shipped detection via radiusOf.');
    });

    testWidgets('tracks the focused item as a list scrolls it into view',
        (WidgetTester tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(12, (int i) => FocusNode());
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: SizedBox(
          height: 240,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < nodes.length; i++)
                  item('i$i', nodes[i], autofocus: i == 0),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      Dpad.of(tester.element(find.text('i8'))).requestFocus(nodes[8]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 110));
      await tester.pumpAndSettle();

      expect(ringRect(tester), itemRect(tester, 'i8'),
          reason: 'After the auto-scroll the ring hugs the item on screen.');
    });

    testWidgets('flies, never teleports, into a still-building route',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      final Key push = UniqueKey();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Builder(
          builder: (BuildContext context) {
            return Align(
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  item('a', a, autofocus: true),
                  TextButton(
                    key: push,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Align(
                          alignment: Alignment.topLeft,
                          child: item('b', b, autofocus: true),
                        ),
                      ),
                    ),
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(push));
      // Sample every frame through the push: the highlight must move
      // continuously — the opposite corner of the screen in a single frame
      // would be a teleport (the pre-fix behavior for targets whose geometry
      // appears after the focus change).
      final List<Rect> frames = <Rect>[];
      for (int i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.byKey(DpadHighlightRingEffect.debugKey).evaluate().isNotEmpty) {
          frames.add(ringRect(tester));
        }
      }
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'b'),
          reason: 'The flight ends on the pushed page\'s item.');
      expect(frames, isNotEmpty,
          reason: 'The highlight stayed visible through the transition.');
      for (int i = 1; i < frames.length; i++) {
        expect(
          (frames[i].topLeft - frames[i - 1].topLeft).distance,
          lessThan(400),
          reason: 'Frame $i moved the ring across the screen in one step — '
              'the flight teleported instead of animating.',
        );
      }
    });

    testWidgets('bounces when a move hits an edge',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(nudgeOffset: 8),
        home: Center(child: item('a', a, autofocus: true)),
      ));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      final Rect base = itemRect(tester, 'a');
      // Step until the bounce is visibly underway, then confirm it is a
      // nudge (rightwards, never past the configured offset) that settles.
      double left = base.left;
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        left = ringRect(tester).left;
        if (left > base.left + 1.5) {
          break;
        }
      }
      expect(left, greaterThan(base.left),
          reason: 'A blocked move bounces the highlight towards the edge.');
      expect(left, lessThanOrEqualTo(base.left + 8.01),
          reason: 'The bounce never exceeds nudgeOffset.');
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'a'),
          reason: 'The bounce settles back onto the item.');
    });

    testWidgets('a region stop edge bounces too', (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(nudgeOffset: 8),
        home: DpadRegion(
          verticalEdge: DpadEdgeBehavior.stop,
          child: Center(child: item('a', a, autofocus: true)),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      final Rect base = itemRect(tester, 'a');
      double top = base.top;
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        top = ringRect(tester).top;
        if (top < base.top - 1.5) {
          break;
        }
      }
      expect(top, lessThan(base.top),
          reason: 'A stop edge the region consumed still bounces — the '
              'blocked press reads the same as a dead end.');
      expect(top, greaterThanOrEqualTo(base.top - 8.01),
          reason: 'The bounce never exceeds nudgeOffset.');
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'a'));
    });
  });

  group('resolution', () {
    testWidgets('stays hidden without any configuration',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(tvApp(
        home: Row(children: <Widget>[
          item('a', a, autofocus: true),
          item('b', b),
        ]),
      ));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsNothing,
          reason: 'The default app has no flying highlight.');
    });

    testWidgets('a scope enables the highlight without the root',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(tvApp(
        home: Row(children: <Widget>[
          DpadHighlightTheme(
            data: const DpadHighlight(),
            child: item('a', a, autofocus: true),
          ),
          item('b', b),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'a'),
          reason: 'The scope turns the highlight on for its subtree.');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsNothing,
          reason: 'Outside the scope there is nothing to paint.');
    });

    testWidgets('a scope restyles its subtree',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Row(children: <Widget>[
          item('a', a, autofocus: true),
          DpadHighlightTheme(
            data: const DpadHighlight(
              effects: <DpadHighlightEffect>[DpadHighlightBracketsEffect()],
            ),
            child: item('b', b),
          ),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightBracketsEffect.debugKey), findsOneWidget,
          reason: 'Focus inside the scope resolves to its configuration.');
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsOneWidget,
          reason: 'Flying back out restores the root configuration.');
    });

    testWidgets('an item override wins over the scope, and none opts out',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Row(children: <Widget>[
          item('a', a, autofocus: true, highlight: DpadHighlight.none),
          item('b', b),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsNothing,
          reason: 'DpadHighlight.none keeps the ring off the item.');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'b'),
          reason: 'Items without an override inherit the root style.');
    });

    testWidgets('nested Dpad roots do not double-paint',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Row(children: <Widget>[
          item('a', a, autofocus: true),
          Dpad(
            highlight: const DpadHighlight(),
            child: item('b', b),
          ),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsOneWidget);

      b.requestFocus();
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsOneWidget,
          reason: 'Only the innermost root paints for its own items.');
      expect(ringRect(tester), itemRect(tester, 'b'));
    });
  });

  group('effects', () {
    testWidgets('built-in effects compose freely',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(
          effects: <DpadHighlightEffect>[
            DpadHighlightVignetteEffect(),
            DpadHighlightSpotlightEffect(),
            DpadHighlightGlowEffect(),
            DpadHighlightBracketsEffect(),
          ],
        ),
        home: Center(child: item('a', a, autofocus: true)),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightVignetteEffect.debugKey), findsOneWidget);
      expect(find.byKey(DpadHighlightSpotlightEffect.debugKey), findsOneWidget);
      expect(find.byKey(DpadHighlightGlowEffect.debugKey), findsOneWidget);
      expect(find.byKey(DpadHighlightBracketsEffect.debugKey), findsOneWidget,
          reason: 'All four effects paint together, first listed first.');
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsNothing);
    });

    testWidgets('custom effects see the live rect and press state',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      DpadHighlightState? last;
      await tester.pumpWidget(tvApp(
        highlight: DpadHighlight(
          effects: <DpadHighlightEffect>[
            DpadHighlightCustomEffect((BuildContext context, DpadHighlightState state) {
              last = state;
              return state.positioned(const SizedBox.shrink());
            }),
          ],
        ),
        home: Row(children: <Widget>[
          item('a', a, autofocus: true),
          item('b', b),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(last, isNotNull);
      expect(last!.rect, itemRect(tester, 'a'));
      expect(last!.visible, isTrue);
      expect(last!.pressed, isFalse,
          reason: 'Nothing is held down yet.');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(last!.pressed, isTrue,
          reason: 'Holding select marks the highlight state as pressed.');

      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(last!.pressed, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      final Rect mid = await pumpMidFlight(
        tester,
        (WidgetTester t) => last!.rect,
        itemRect(tester, 'a'),
        itemRect(tester, 'b'),
      );
      expect(
        mid.left,
        allOf(
          greaterThan(itemRect(tester, 'a').left),
          lessThan(itemRect(tester, 'b').left),
        ),
        reason: 'Custom effects receive the lerping rect every frame.',
      );
      await tester.pumpAndSettle();
      expect(last!.rect, itemRect(tester, 'b'));
    });
  });

  group('configuration', () {
    test('DpadHighlight equality covers every field', () {
      expect(const DpadHighlight(), const DpadHighlight());
      expect(
        DpadHighlight.none,
        const DpadHighlight(effects: <DpadHighlightEffect>[]),
        reason: 'none is just the empty-effects configuration.',
      );
      expect(
        const DpadHighlight(duration: Duration(milliseconds: 1)),
        isNot(equals(const DpadHighlight())),
      );
      expect(
        const DpadHighlight(curve: Curves.linear),
        isNot(equals(const DpadHighlight())),
      );
      expect(
        const DpadHighlight(nudgeOffset: 1),
        isNot(equals(const DpadHighlight())),
      );
      expect(
        const DpadHighlight().copyWith(padding: const EdgeInsets.all(2)),
        const DpadHighlight(padding: EdgeInsets.all(2)),
      );
    });
  });

  group('boundaries', () {
    testWidgets('clamps an oversized detected radius to a pill',
        (WidgetTester tester) async {
      final FocusNode huge = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Center(
            child: roundedItem('huge', huge, radius: 200, autofocus: true)),
      ));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 30,
          reason: 'A 200-pixel radius on a 60-pixel-tall item clamps to '
              'shortestSide / 2 — fully rounded, never looping inward.');
    });

    testWidgets('scales the detected radius with the item\'s focus lift',
        (WidgetTester tester) async {
      final FocusNode lifted = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Center(
          child: DpadFocusable(
            focusNode: lifted,
            autofocus: true,
            effects: const <DpadEffect>[DpadScaleEffect(scale: 1.2)],
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const SizedBox(
                width: 80,
                height: 60,
                child: ColoredBox(
                  color: Color(0xFFFFFFFF),
                  child: Center(child: Text('lifted')),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 24,
          reason: 'The detected 20-pixel radius scales with the 1.2 focus '
              'lift, matching the scaled rect the ring frames.');
    });

    testWidgets('frames a zero-size item without crashing',
        (WidgetTester tester) async {
      final FocusNode zero = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Center(
          child: DpadFocusable(
            focusNode: zero,
            autofocus: true,
            effects: const <DpadEffect>[],
            child: const SizedBox(
              width: 0,
              height: 0,
              child: ColoredBox(color: Color(0xFFFFFFFF)),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(
        find.byKey(DpadHighlightRingEffect.debugKey),
        findsOneWidget,
        reason: 'A zero-size focus target still paints (a degenerate ring), '
            'and nothing throws.',
      );
      expect(ringRadius(tester), 0,
          reason: 'The fallback radius clamps to shortestSide / 2 = 0.');
    });
  });
group('boundaries (motion)', () {
    testWidgets('re-materializes in place after fading out',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Row(children: <Widget>[
          roundedItem('a', a, radius: 20, autofocus: true),
          roundedItem('b', b, radius: 28),
        ]),
      ));
      await tester.pumpAndSettle();
      a.unfocus();
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsNothing,
          reason: 'Fully faded out after losing focus.');

      b.requestFocus();
      Rect? firstSeen;
      for (int i = 0; i < 10 && firstSeen == null; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        if (find.byKey(DpadHighlightRingEffect.debugKey).evaluate().isNotEmpty) {
          firstSeen = ringRect(tester);
        }
      }
      expect(firstSeen, isNotNull, reason: 'The highlight came back.');
      expect(firstSeen, itemRect(tester, 'b'),
          reason: 'After a full fade-out the next appearance materializes '
              'in place — no flight from a stale rect.');
    });

    testWidgets('survives the origin being disposed mid-flight',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      final Row withA = Row(children: <Widget>[
        roundedItem('a', a, radius: 20, autofocus: true),
        roundedItem('b', b, radius: 28),
      ]);
      final Row withoutA = Row(children: <Widget>[roundedItem('b', b, radius: 28)]);
      await tester.pumpWidget(tvApp(highlight: const DpadHighlight(), home: withA));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpWidget(
          tvApp(highlight: const DpadHighlight(), home: withoutA));
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'b'),
          reason: 'Losing the takeoff item mid-flight leaves the flight '
              'intact; nothing throws.');
    });

    testWidgets('flights land correctly in RTL layouts',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(children: <Widget>[
            roundedItem('a', a, radius: 20, autofocus: true),
            roundedItem('b', b, radius: 28),
          ]),
        ),
      ));
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'a'));

      // In RTL the next (visually left) item is reached with arrow-left.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'b'),
          reason: 'The flight measures through the item transform, so RTL '
              'needs no special-casing.');
    });

    testWidgets('a config swap mid-flight keeps the flight',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      Widget home() => Row(children: <Widget>[
            roundedItem('a', a, radius: 20, autofocus: true),
            roundedItem('b', b, radius: 28),
          ]);
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: home(),
      ));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(
          effects: <DpadHighlightEffect>[DpadHighlightBracketsEffect()],
        ),
        home: home(),
      ));
      // Step until the new-style painter is visibly between the items —
      // test-frame arithmetic delays the flight start by a frame or two.
      Rect mid = itemRect(tester, 'a');
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        mid = tester.getRect(
            find.byKey(DpadHighlightBracketsEffect.debugKey));
        if (mid.left > itemRect(tester, 'a').left + 0.5 &&
            mid.left < itemRect(tester, 'b').left - 0.5) {
          break;
        }
      }
      expect(
        mid.left,
        allOf(
          greaterThan(itemRect(tester, 'a').left),
          lessThan(itemRect(tester, 'b').left),
        ),
        reason: 'Swapping the configuration mid-flight repaints in the new '
            'style without teleporting.',
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(DpadHighlightBracketsEffect.debugKey)),
        itemRect(tester, 'b'),
      );
    });
  });

  group('performance', () {
    DpadHighlight counted(int Function() tick) => DpadHighlight(
          effects: <DpadHighlightEffect>[
            DpadHighlightCustomEffect(
                (BuildContext context, DpadHighlightState state) {
              tick();
              return const SizedBox.shrink();
            }),
          ],
        );

    testWidgets('the ticker sleeps while idle — zero effect rebuilds',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      int builds = 0;
      await tester.pumpWidget(tvApp(
        highlight: counted(() => builds++),
        home: Row(children: <Widget>[
          roundedItem('a', a, radius: 20, autofocus: true),
          roundedItem('b', b, radius: 28),
        ]),
      ));
      await tester.pumpAndSettle();
      final int settled = builds;

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(builds, settled,
          reason: 'With the target stationary the ticker sleeps: no frames '
              'scheduled, no effect rebuilds — the idle cost is zero.');
    });

    testWidgets('a single flight costs a bounded number of effect builds',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      int builds = 0;
      await tester.pumpWidget(tvApp(
        highlight: counted(() => builds++),
        home: Row(children: <Widget>[
          roundedItem('a', a, radius: 20, autofocus: true),
          roundedItem('b', b, radius: 28),
        ]),
      ));
      await tester.pumpAndSettle();

      builds = 0;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(builds, lessThan(60),
          reason: 'A 220ms flight plus settle frames rebuilds the effect '
              'stack roughly once per frame, never in a storm '
              '(observed: $builds builds).');
    });
  });
group('fade and lift regressions', () {
    testWidgets('the fade-out is visible halfway through, then gone',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Center(child: roundedItem('a', a, radius: 20, autofocus: true)),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsOneWidget);

      a.unfocus();
      await tester.pump(const Duration(milliseconds: 75));
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsOneWidget,
          reason: 'Halfway through appearDuration the ring is still being '
              'painted, fading — not popped out in a single frame.');
      await tester.pumpAndSettle();
      expect(find.byKey(DpadHighlightRingEffect.debugKey), findsNothing,
          reason: 'The fade completes and the layer empties.');
    });

    testWidgets('a reused external focus node does not inherit its old lift',
        (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      Widget scaledApp({required double scale}) => tvApp(
            highlight: const DpadHighlight(),
            home: Center(
              child: DpadFocusable(
                focusNode: node,
                autofocus: true,
                effects: <DpadEffect>[
                  if (scale != 1.0) DpadScaleEffect(scale: scale),
                ],
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const SizedBox(
                    width: 80,
                    height: 60,
                    child: ColoredBox(
                      color: Color(0xFFFFFFFF),
                      child: Center(child: Text('reused')),
                    ),
                  ),
                ),
              ),
            ),
          );
      await tester.pumpWidget(scaledApp(scale: 1.2));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 24,
          reason: 'While mounted: 20 x 1.2 lift.');

      // Actually unmount the focusable (the node's owner hands it back),
      // let the highlight fade, then remount the same node on a lift-free
      // item — the stale mark must not survive the handback.
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: const SizedBox(),
      ));
      await tester.pumpAndSettle();
      await tester.pumpWidget(scaledApp(scale: 1.0));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 20,
          reason: 'The visualScale mark is cleared on unmark, so the node '
              'starts clean with its new owner.');
    });
  });

  group('shape, flight and idle regressions', () {
    testWidgets('a Material shape border defines the followed silhouette',
        (WidgetTester tester) async {
      final FocusNode card = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Center(
          child: DpadFocusable(
            focusNode: card,
            autofocus: true,
            effects: const <DpadEffect>[],
            child: const Material(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: SizedBox(
                width: 80,
                height: 60,
                child: ColoredBox(color: Color(0xFFFFFFFF)),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 24,
          reason: 'Material(shape:) clips through a physical shape — '
              'Material 3 cards land there, and shape-following must not '
              'silently fall back to 12.');
    });

    testWidgets('a circular shape border rounds fully',
        (WidgetTester tester) async {
      final FocusNode dot = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: Center(
          child: DpadFocusable(
            focusNode: dot,
            autofocus: true,
            effects: const <DpadEffect>[],
            child: const Material(
              shape: CircleBorder(),
              child: SizedBox(
                width: 80,
                height: 60,
                child: ColoredBox(color: Color(0xFFFFFFFF)),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(ringRadius(tester), 30,
          reason: 'A circular border rounds to shortestSide / 2.');
    });

    testWidgets('fading out reports the landed, invisible state',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      final Key probe = UniqueKey();
      DpadHighlightState? last;
      await tester.pumpWidget(tvApp(
        home: Row(children: <Widget>[
          DpadHighlightTheme(
            data: DpadHighlight(
              effects: <DpadHighlightEffect>[
                DpadHighlightCustomEffect(
                    (_, DpadHighlightState state) {
                  last = state;
                  return state.positioned(SizedBox.shrink(key: probe));
                }),
              ],
            ),
            child: item('a', a, autofocus: true),
          ),
          item('b', b),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(last!.visible, isTrue);
      expect(last!.node, same(a));
      expect(last!.t, 1.0);

      // Landing on the unconfigured item fades the highlight out.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(last!.visible, isFalse, reason: 'The state reports fading out.');
      expect(last!.node, isNull, reason: 'Nothing is tracked while fading.');
      expect(last!.t, 1.0, reason: 'The fade paints the landed look.');
      expect(find.byKey(probe), findsOneWidget,
          reason: 'The effect keeps painting through the fade.');
      await tester.pumpAndSettle();
      expect(find.byKey(probe), findsNothing);
    });

    testWidgets('the flight interpolates from where the origin is now',
        (WidgetTester tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(8, (int i) => FocusNode());
      const Key painted = ValueKey<String>('painted');
      DpadHighlightState? last;
      await tester.pumpWidget(tvApp(
        highlight: DpadHighlight(
          curve: Curves.linear,
          effects: <DpadHighlightEffect>[
            DpadHighlightCustomEffect((_, DpadHighlightState state) {
              last = state;
              return state.positioned(const SizedBox.shrink(key: painted));
            }),
          ],
        ),
        home: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < nodes.length; i++)
                  item('i$i', nodes[i], autofocus: i == 0),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final Rect originAtRest = itemRect(tester, 'i0');

      // Far enough that the auto-scroll moves the origin mid-flight.
      Dpad.of(tester.element(find.text('i0'))).requestFocus(nodes[6]);
      Rect? mid;
      double? midT;
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        final Rect origin = itemRect(tester, 'i0');
        if (last != null &&
            last!.t > 0.02 &&
            last!.t < 0.95 &&
            origin.left < originAtRest.left - 1.0) {
          mid = tester.getRect(find.byKey(painted));
          midT = last!.t;
          break;
        }
      }
      expect(mid, isNotNull,
          reason: 'The setup never produced a scrolled mid-flight sample.');
      // Comparing distances instead of absolutes: the engine and the
      // assertion can be a scroll tick apart, but the current-position
      // lerp is always the nearer anchor — a frozen takeoff rect trails
      // the whole scrolled distance behind.
      final Rect freshFrom = itemRect(tester, 'i0');
      final Rect target = itemRect(tester, 'i6');
      final double dFresh =
          (mid!.left - Rect.lerp(freshFrom, target, midT!)!.left).abs();
      final double dFrozen =
          (mid.left - Rect.lerp(originAtRest, target, midT)!.left).abs();
      expect(dFresh, lessThan(dFrozen),
          reason: 'Mid-flight the rect lerps from the origin\'s CURRENT '
              'position — a frozen takeoff rect cuts across scrolled '
              'content.');
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(painted)), itemRect(tester, 'i6'));
    });

    testWidgets('a repeat while the bounce is running does not restart it',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(nudgeOffset: 8),
        home: Center(child: item('a', a, autofocus: true)),
      ));
      await tester.pumpAndSettle();
      final Rect base = itemRect(tester, 'a');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      // ~115ms in: past the arc's peak (sin peaks at half of the 180ms
      // arc), where the offset is strictly settling.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 115));
      final double offsetAtRepeat = ringRect(tester).left - base.left;
      expect(offsetAtRepeat, greaterThan(0.0));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      double previous = offsetAtRepeat;
      bool monotone = true;
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        final double offset = ringRect(tester).left - base.left;
        if (offset > previous + 1.0) {
          monotone = false;
        }
        previous = offset;
      }
      expect(monotone, isTrue,
          reason: 'After the peak the arc only settles — restarting it from '
              'zero on a key repeat would climb again and read as a '
              'stutter.');
      await tester.pumpAndSettle();
      expect(ringRect(tester), itemRect(tester, 'a'));
    });

    testWidgets('a scroll that cannot move the item leaves the tracker asleep',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      int builds = 0;
      await tester.pumpWidget(tvApp(
        highlight: DpadHighlight(
          effects: <DpadHighlightEffect>[
            DpadHighlightCustomEffect((_, __) {
              builds++;
              return const SizedBox.shrink();
            }),
          ],
        ),
        home: Row(
          children: <Widget>[
            SizedBox(
              width: 200,
              child: Center(child: item('a', a, autofocus: true)),
            ),
            SizedBox(
              width: 250,
              child: ListView(
                children: <Widget>[
                  for (int i = 0; i < 40; i++) Text('row$i'),
                ],
              ),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      builds = 0;

      await tester.fling(find.byType(ListView), const Offset(0, -400), 2000);
      for (int i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(builds, 0,
          reason: 'An unrelated scrollable elsewhere on screen must not '
              'wake the highlight tracker.');
      await tester.pumpAndSettle();
      expect(builds, 0);
    });

    testWidgets('a root rebuild with an equal inline config restarts nothing',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      int builds = 0;
      DpadHighlight config() => DpadHighlight(
            effects: <DpadHighlightEffect>[
              DpadHighlightCustomEffect((_, __) {
                builds++;
                return const SizedBox.shrink();
              }),
            ],
          );
      final Widget home = Center(child: item('a', a, autofocus: true));
      await tester.pumpWidget(tvApp(highlight: config(), home: home));
      await tester.pumpAndSettle();
      expect(builds, greaterThan(0));
      builds = 0;

      await tester.pumpWidget(tvApp(highlight: config(), home: home));
      await tester.pumpAndSettle();
      expect(builds, lessThan(3),
          reason: 'A fresh-but-equal configuration (inline effects now '
              'compared structurally) rebuilds once with the root — it '
              'must not relaunch a 220ms flight of rebuilds.');
    });
  });

  group('reduced motion', () {
    Widget motionApp(WidgetTester tester, {required Widget home}) {
      return MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: Dpad(
              highlight: const DpadHighlight(
                duration: Duration(milliseconds: 400),
                nudgeOffset: 8,
              ),
              child: child!,
            ),
          );
        },
        home: Scaffold(body: home),
      );
    }

    testWidgets('disableAnimations lands flights instantly',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(motionApp(
        tester,
        home: Row(children: <Widget>[
          item('a', a, autofocus: true),
          item('b', b),
        ]),
      ));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      // One frame is enough — a 400ms flight must not run under the
      // platform's reduced-motion request.
      await tester.pump();
      expect(ringRect(tester), itemRect(tester, 'b'),
          reason: 'disableAnimations lands the flight immediately');
      await tester.pump(const Duration(milliseconds: 50));
      expect(ringRect(tester), itemRect(tester, 'b'),
          reason: 'and nothing animates afterwards');
    });

    testWidgets('disableAnimations stands the edge bounce down',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      await tester.pumpWidget(
        motionApp(tester, home: Center(child: item('a', a, autofocus: true))),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        expect(ringRect(tester), itemRect(tester, 'a'),
            reason: 'frame $i: no bounce under reduced motion');
      }
    });

    testWidgets('toggling disableAnimations re-resolves the durations',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      final FocusNode c = FocusNode();
      bool reduceMotion = false;
      final Widget row = Row(children: <Widget>[
        item('a', a, autofocus: true),
        item('b', b),
        item('c', c),
      ]);

      await tester.pumpWidget(MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: Dpad(
              highlight: const DpadHighlight(),
              child: child!,
            ),
          );
        },
        home: Scaffold(body: row),
      ));
      await tester.pumpAndSettle();

      // Animated while the setting is off: mid-flight frames exist.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 110));
      final Rect mid = ringRect(tester);
      expect(mid, isNot(itemRect(tester, 'b')));
      await tester.pumpAndSettle();

      // On: the same move lands within a frame.
      reduceMotion = true;
      await tester.pumpWidget(MaterialApp(
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: Dpad(
              highlight: const DpadHighlight(),
              child: child!,
            ),
          );
        },
        home: Scaffold(body: row),
      ));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(ringRect(tester), itemRect(tester, 'c'),
          reason: 'the landed configuration adopted the zero durations');
    });
  });

  group('high refresh rates', () {
    // One 120Hz frame; 240Hz halves it again.
    const Duration frame120 = Duration(microseconds: 8333);
    const Duration frame240 = Duration(microseconds: 4167);

    testWidgets('the ring stays on its item in every frame of a scroll',
        (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      final List<FocusNode> nodes =
          List<FocusNode>.generate(12, (int i) => FocusNode());
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: SizedBox(
          height: 200,
          child: ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            itemCount: nodes.length,
            itemBuilder: (BuildContext context, int i) => DpadFocusable(
              focusNode: nodes[i],
              autofocus: i == 2,
              autoScroll: false,
              effects: const <DpadEffect>[],
              child: SizedBox(width: 200, child: Text('i$i')),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      for (final Duration frame in <Duration>[frame120, frame240]) {
        controller.animateTo(
          controller.offset + 300,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        for (int i = 0; i < 40; i++) {
          await tester.pump(frame);
          expect(
            (ringRect(tester).left - itemRect(tester, 'i2').left).abs(),
            lessThan(0.5),
            reason: 'The ring is painted where the item is in this frame, '
                'not where it was one frame ago.',
          );
        }
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the flight origin follows a scrolling item in every frame',
        (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      final List<FocusNode> nodes =
          List<FocusNode>.generate(12, (int i) => FocusNode());
      DpadHighlightState? last;
      await tester.pumpWidget(tvApp(
        highlight: DpadHighlight(
          curve: Curves.linear,
          effects: <DpadHighlightEffect>[
            DpadHighlightCustomEffect((_, DpadHighlightState state) {
              last = state;
              return state.positioned(
                const SizedBox.shrink(key: DpadHighlightRingEffect.debugKey),
              );
            }),
          ],
        ),
        home: Column(children: <Widget>[
          SizedBox(
            height: 100,
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: nodes.length,
              itemBuilder: (BuildContext context, int i) => DpadFocusable(
                focusNode: nodes[i],
                autofocus: i == 1,
                autoScroll: false,
                effects: const <DpadEffect>[],
                child: SizedBox(width: 100, child: Text('i$i')),
              ),
            ),
          ),
          item('below', FocusNode()),
        ]),
      ));
      await tester.pumpAndSettle();

      // Fly down to `below` while the row scrolls the takeoff item away.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      controller.animateTo(
        200,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
      for (int i = 0; i < 20; i++) {
        await tester.pump(frame120);
        final DpadHighlightState? state = last;
        if (state == null || state.t <= 0.0 || state.t >= 1.0) {
          continue;
        }
        final Rect from = itemRect(tester, 'i1');
        final Rect to = itemRect(tester, 'below');
        final Rect expected = Rect.lerp(from, to, state.t)!;
        expect(
          (ringRect(tester).left - expected.left).abs(),
          lessThan(0.5),
          reason: 'Mid-flight the painted rect blends the endpoints where '
              'they are in this frame.',
        );
      }
    });

    testWidgets('a landed ring sleeps after the same span at any rate',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(curve: Curves.linear),
        home: Row(children: <Widget>[
          item('a', a, autofocus: true),
          item('b', b),
        ]),
      ));
      await tester.pumpAndSettle();

      for (final Duration frame in <Duration>[frame120, frame240]) {
        final String to = b.hasPrimaryFocus ? 'a' : 'b';
        await tester.sendKeyEvent(
          b.hasPrimaryFocus
              ? LogicalKeyboardKey.arrowLeft
              : LogicalKeyboardKey.arrowRight,
        );
        // Step to the landing frame.
        for (int i = 0; i < 100; i++) {
          await tester.pump(frame);
          if ((ringRect(tester).left - itemRect(tester, to).left).abs() <
              0.01) {
            break;
          }
        }
        // Standing still for 40ms is not yet settled — though that is
        // four frames at 120Hz and nine at 240Hz.
        final int short = 40 * 1000 ~/ frame.inMicroseconds;
        for (int i = 0; i < short; i++) {
          await tester.pump(frame);
        }
        expect(tester.binding.hasScheduledFrame, isTrue,
            reason: 'The tracker keeps watching for a fixed span, not a '
                'fixed frame count.');
        await tester.pump(const Duration(milliseconds: 40));
        await tester.pump(frame);
        expect(tester.binding.hasScheduledFrame, isFalse,
            reason: 'Once the span has passed the tracker sleeps.');
      }
    });

    testWidgets('an unmeasurable target is waited for the same span at 240Hz',
        (WidgetTester tester) async {
      final FocusNode a = FocusNode();
      final FocusNode b = FocusNode();
      final ValueNotifier<bool> hidden = ValueNotifier<bool>(false);
      addTearDown(hidden.dispose);
      await tester.pumpWidget(tvApp(
        highlight: const DpadHighlight(),
        home: ValueListenableBuilder<bool>(
          valueListenable: hidden,
          builder: (BuildContext context, bool off, Widget? child) {
            final Widget target = item('b', b);
            return Row(children: <Widget>[
              item('a', a, autofocus: true),
              if (off) _Unlaid(child: target) else target,
            ]);
          },
        ),
      ));
      await tester.pumpAndSettle();
      b.requestFocus();
      await tester.pumpAndSettle();
      // The focused item stays mounted and focused but loses its geometry.
      hidden.value = true;
      await tester.pump();
      b.requestFocus();
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      double opacity() => tester
          .widget<FadeTransition>(find
              .ancestor(
                of: find.byKey(DpadHighlightRingEffect.debugKey),
                matching: find.byType(FadeTransition),
              )
              .first)
          .opacity
          .value;
      // 400ms of 240Hz frames: 96 frames, triple a 30-frame budget, but
      // inside the 500ms the budget means.
      for (int i = 0; i < 96; i++) {
        await tester.pump(frame240);
      }
      expect(opacity(), 1.0,
          reason: 'The highlight still waits for the target.');

      // Past 500ms it gives up and fades out.
      for (int i = 0; i < 36; i++) {
        await tester.pump(frame240);
      }
      expect(opacity(), lessThan(1.0));
    });
  });
}

/// Keeps [child] mounted but never lays it out: a focused item without
/// geometry.
class _Unlaid extends SingleChildRenderObjectWidget {
  const _Unlaid({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderUnlaid();
}

class _RenderUnlaid extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  @override
  void performLayout() => size = Size.zero;

  @override
  void paint(PaintingContext context, Offset offset) {}

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {}
}
