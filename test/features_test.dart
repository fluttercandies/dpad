import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  setUp(DpadRegionState.clearPersistentMemory);

  testWidgets('memoryKey keeps region memory across full rebuilds',
      (tester) async {
    final m1 = FocusNode();
    String? focusedLabel;
    int generation = 0;
    late StateSetter setState;

    Widget content() {
      return DpadRegion(
        key: ValueKey<int>(generation),
        memoryKey: 'content',
        debugLabel: 'content',
        child: Column(
          children: [
            for (final id in const ['c1', 'c2', 'c3'])
              DpadFocusable(
                onFocusChange: (focused) {
                  if (focused) {
                    focusedLabel = id;
                  }
                },
                effects: const <DpadEffect>[],
                child: SizedBox(
                    width: 60, height: 60, child: Center(child: Text(id))),
              ),
          ],
        ),
      );
    }

    await tester.pumpWidget(tvApp(
      home: StatefulBuilder(
        builder: (context, set) {
          setState = set;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DpadRegion(child: item('m1', m1, autofocus: true)),
              const SizedBox(width: 40),
              content(),
            ],
          );
        },
      ),
    ));
    await tester.pumpAndSettle();

    // Focus the middle content item, then go back to the menu.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedLabel, 'c2');
    m1.requestFocus();
    await tester.pumpAndSettle();

    // Rebuild the content region from scratch (new Key → new State and
    // brand-new focus nodes).
    setState(() => generation++);
    await tester.pumpAndSettle();

    // Re-entering must land on the new c2, via the persisted memory.
    focusedLabel = null;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedLabel, 'c2');
  });

  testWidgets('a changed memoryKey starts fresh instead of restoring stale '
      'memory', (tester) async {
    final m1 = FocusNode();
    String? focusedLabel;
    String memoryKey = 'first';
    late StateSetter setState;

    Widget content() {
      return DpadRegion(
        memoryKey: memoryKey,
        child: Column(
          children: [
            for (final id in const ['c1', 'c2', 'c3'])
              DpadFocusable(
                onFocusChange: (focused) {
                  if (focused) {
                    focusedLabel = id;
                  }
                },
                effects: const <DpadEffect>[],
                child: SizedBox(
                    width: 60, height: 60, child: Center(child: Text(id))),
              ),
          ],
        ),
      );
    }

    await tester.pumpWidget(tvApp(
      home: StatefulBuilder(
        builder: (context, set) {
          setState = set;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DpadRegion(child: item('m1', m1, autofocus: true)),
              const SizedBox(width: 40),
              content(),
            ],
          );
        },
      ),
    ));
    await tester.pumpAndSettle();

    // Focus the middle content item, then go back to the menu.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedLabel, 'c2');
    m1.requestFocus();
    await tester.pumpAndSettle();

    // Switch the region to a different logical identity (same State).
    setState(() => memoryKey = 'second');
    await tester.pumpAndSettle();

    // Nothing was ever recorded under 'second': entering must fall back to
    // the geometrically nearest item, not restore 'first' identity's c2.
    focusedLabel = null;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedLabel, 'c1');
  });

  testWidgets('a pushed route without autofocus receives initial focus',
      (tester) async {
    final a = FocusNode();
    final p1 = FocusNode();
    final p2 = FocusNode();

    await tester.pumpWidget(tvApp(
      home: item('a', a, autofocus: true),
    ));
    await tester.pumpAndSettle();
    expect(a.hasPrimaryFocus, isTrue);

    Navigator.of(tester.element(find.text('a'))).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: Row(children: [item('p1', p1), item('p2', p2)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(p1.hasPrimaryFocus, isTrue,
        reason: 'a new page must be immediately drivable by the remote');
  });

  testWidgets(
      'a pushed route without autofocus starts at the reading start in RTL',
      (tester) async {
    final p1 = FocusNode();
    final p2 = FocusNode();

    await tester.pumpWidget(tvApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: item('host', FocusNode(), autofocus: true),
      ),
    ));
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.text('host'))).push(
      MaterialPageRoute<void>(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Row(children: [item('p1', p1), item('p2', p2)]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(p1.hasPrimaryFocus, isTrue,
        reason: 'in RTL, p1 (the first child) is the rightmost item — '
            'the start of the reading order');
  });

  testWidgets('Dpad.onFocusChange reports every focus move', (tester) async {
    final a = FocusNode(debugLabel: 'a');
    final b = FocusNode(debugLabel: 'b');
    final log = <String?>[];

    await tester.pumpWidget(tvApp(
      onFocusChange: (node) => log.add(node?.debugLabel),
      home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
    ));
    await tester.pumpAndSettle();
    expect(log, contains('a'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(log.last, 'b');
  });

  testWidgets('debugOverlay outlines the focused node with its label',
      (tester) async {
    await tester.pumpWidget(tvApp(
      debugOverlay: true,
      home: const DpadFocusable(
        autofocus: true,
        debugLabel: 'hero-button',
        effects: <DpadEffect>[],
        child: SizedBox(width: 60, height: 60),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('60×60'), findsOneWidget);
    expect(find.textContaining('hero-button'), findsOneWidget);
  });

  testWidgets(
      'toggling debugOverlay/enabled at runtime keeps subtree '
      'state and focus', (tester) async {
    final a = FocusNode(debugLabel: 'a');
    int selected = 0;

    Widget app({required bool overlay, required bool enabled}) {
      return MaterialApp(
        builder: Dpad.wrap(debugOverlay: overlay, enabled: enabled),
        home: Scaffold(
          body: item('a', a, autofocus: true, onSelect: () => selected++),
        ),
      );
    }

    await tester.pumpWidget(app(overlay: false, enabled: true));
    await tester.pumpAndSettle();
    expect(a.hasPrimaryFocus, isTrue);

    // Flip the overlay on: the subtree must not be rebuilt from scratch,
    // so the same node instance keeps focus and still receives keys.
    await tester.pumpWidget(app(overlay: true, enabled: true));
    await tester.pump();
    expect(a.hasPrimaryFocus, isTrue,
        reason: 'structure must be stable across configuration changes');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, 1);

    // Same for `enabled`.
    await tester.pumpWidget(app(overlay: false, enabled: false));
    await tester.pump();
    expect(a.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(app(overlay: false, enabled: true));
    await tester.pump();
    expect(a.hasPrimaryFocus, isTrue);
  });

  testWidgets('the theme scrollPadding is honored for plain Focus nodes',
      (tester) async {
    final controller = ScrollController();
    final anchor = FocusNode();
    final far = FocusNode();

    await tester.pumpWidget(tvApp(
      theme: const DpadThemeData(scrollPadding: 90),
      home: SizedBox(
        width: 400,
        height: 100,
        child: SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              item('anchor', anchor, autofocus: true),
              const SizedBox(width: 600),
              Focus(
                focusNode: far,
                child: const SizedBox(
                  width: 60,
                  height: 60,
                  child: Text('far'),
                ),
              ),
              const SizedBox(width: 400),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(far.hasPrimaryFocus, isTrue,
        reason: 'traversal must reach the plain Focus node');

    // The node spans 660..720 in a 400px viewport; the themed 90px of
    // padding past its right edge puts the offset at 720 - (400 - 90).
    expect(controller.offset, closeTo(410, 0.5),
        reason: 'the themed scrollPadding must translate into viewport '
            'edge margin for unmanaged nodes');
  });

  test('built-in effects compare by value so inline themes stay equal', () {
    // An inline `DpadThemeData(effects: [...])` rebuilt on every root
    // build must not invalidate the theme (and rebuild every item) when
    // nothing changed. The values flow through variables so the instances
    // cannot be const-canonicalized — equality has to come from the
    // operators themselves. Every built-in is covered, one field apart.
    final double scale = double.parse('1.08');
    final double width = double.parse('2.5');
    final double blur = double.parse('18');
    final double elevation = double.parse('12');
    final double idleOpacity = double.parse('0.6');
    final double tintOpacity = double.parse('0.25');
    final List<(DpadEffect, DpadEffect, DpadEffect)> rows =
        <(DpadEffect, DpadEffect, DpadEffect)>[
      (
        DpadScaleEffect(scale: scale),
        DpadScaleEffect(scale: scale),
        DpadScaleEffect(scale: scale * 1.1),
      ),
      (
        DpadBorderEffect(width: width),
        DpadBorderEffect(width: width),
        DpadBorderEffect(width: width + 1),
      ),
      (
        DpadGlowEffect(blurRadius: blur),
        DpadGlowEffect(blurRadius: blur),
        DpadGlowEffect(blurRadius: blur + 2),
      ),
      (
        DpadElevationEffect(elevation: elevation),
        DpadElevationEffect(elevation: elevation),
        DpadElevationEffect(elevation: elevation + 2),
      ),
      (
        DpadOpacityEffect(idleOpacity: idleOpacity),
        DpadOpacityEffect(idleOpacity: idleOpacity),
        DpadOpacityEffect(idleOpacity: idleOpacity - 0.1),
      ),
      (
        DpadTintEffect(opacity: tintOpacity),
        DpadTintEffect(opacity: tintOpacity),
        DpadTintEffect(opacity: tintOpacity + 0.05),
      ),
    ];
    for (final (DpadEffect a, DpadEffect b, DpadEffect other) in rows) {
      expect(a, b, reason: '${a.runtimeType} equals its own configuration');
      expect(a.hashCode, b.hashCode,
          reason: '${a.runtimeType} hashes with its equal');
      expect(a, isNot(other),
          reason: '${a.runtimeType} distinguishes a changed field');
    }
    // And the theme compares through them by list equality.
    final List<DpadEffect> pair = <DpadEffect>[
      DpadScaleEffect(scale: scale),
      DpadGlowEffect(blurRadius: blur),
    ];
    expect(DpadThemeData(effects: pair), DpadThemeData(effects: pair));
    expect(
      DpadThemeData(effects: [DpadScaleEffect(scale: scale * 1.1)]),
      isNot(DpadThemeData(effects: [DpadScaleEffect(scale: scale)])),
    );
  });

  testWidgets(
      'a region without memory falls back to its entry item on first entry',
      (tester) async {
    final s1 = FocusNode();
    final c1 = FocusNode();
    final c2 = FocusNode();
    final c3 = FocusNode();

    await tester.pumpWidget(tvApp(
      home: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DpadRegion(
            debugLabel: 'sidebar',
            child: Column(children: [item('s1', s1, autofocus: true)]),
          ),
          const SizedBox(width: 40),
          DpadRegion(
            debugLabel: 'content',
            child: Column(
              children: [
                item('c1', c1),
                item('c2', c2, entry: true),
                item('c3', c3),
              ],
            ),
          ),
        ],
      ),
    ));
    await tester.pumpAndSettle();
    expect(s1.hasPrimaryFocus, isTrue,
        reason: 'autofocus keeps the startup restore out of the content');

    // The content region has never held focus: nothing to restore, so the
    // very first entry lands on the entry-marked item — not the
    // geometrically nearest (c1, level with s1).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(c2.hasPrimaryFocus, isTrue,
        reason: 'first entry must land on the entry item');
    expect(c1.hasPrimaryFocus, isFalse);
  });
}
