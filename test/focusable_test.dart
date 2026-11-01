import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  group('selection', () {
    testWidgets('select key fires onSelect exactly once per press',
        (tester) async {
      final node = FocusNode();
      int selected = 0;

      await tester.pumpWidget(tvApp(
        home: item('a', node, autofocus: true, onSelect: () => selected++),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(selected, 2);
    });

    testWidgets('held select key does not repeat onSelect', (tester) async {
      final node = FocusNode();
      int selected = 0;

      await tester.pumpWidget(tvApp(
        home: item('a', node, autofocus: true, onSelect: () => selected++),
      ));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 1);
    });

    testWidgets(
        'a held select key does not machine-gun the next focused item',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      int aSelected = 0;
      int bSelected = 0;

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            item('a', a, autofocus: true, onSelect: () {
              aSelected++;
              b.requestFocus();
            }),
            item('b', b, onSelect: () => bSelected++),
          ],
        ),
      ));
      await tester.pump();

      // The key-down lands on `a`, whose onSelect moves focus to `b`. The
      // OS repeats that follow never saw a key-down — they must not read
      // as fresh presses of `b`.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(a.hasPrimaryFocus, isFalse);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(aSelected, 1);
      expect(bSelected, 0);

      // The release ends the hold; a fresh press on `b` selects normally.
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(bSelected, 1);
    });

    testWidgets(
        'repeats of a key pressed on a plain button never select the item '
        'focus moved to', (tester) async {
      final button = FocusNode();
      final poster = FocusNode();
      int selected = 0;

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            TextButton(
              focusNode: button,
              autofocus: true,
              onPressed: poster.requestFocus,
              child: const Text('OK'),
            ),
            item('poster', poster, onSelect: () => selected++),
          ],
        ),
      ));
      await tester.pump();

      // The key-down activates the button, which moves focus to the
      // poster: no DpadFocusable saw the press begin.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(poster.hasPrimaryFocus, isTrue);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(selected, 0);
    });

    testWidgets('holding select fires onLongSelect instead of onSelect',
        (tester) async {
      final node = FocusNode();
      int selected = 0;
      int longSelected = 0;

      await tester.pumpWidget(tvApp(
        home: item(
          'a',
          node,
          autofocus: true,
          onSelect: () => selected++,
          onLongSelect: () => longSelected++,
        ),
      ));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(longSelected, 1);
      expect(selected, 0);
    });

    testWidgets(
        'quick press with onLongSelect set fires onSelect on '
        'release', (tester) async {
      final node = FocusNode();
      int selected = 0;
      int longSelected = 0;

      await tester.pumpWidget(tvApp(
        home: item(
          'a',
          node,
          autofocus: true,
          onSelect: () => selected++,
          onLongSelect: () => longSelected++,
        ),
      ));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 1);
      expect(longSelected, 0);
    });

    testWidgets('losing focus mid-hold cancels the pending long-select',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      int selected = 0;
      int longSelected = 0;

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            item(
              'a',
              a,
              autofocus: true,
              onSelect: () => selected++,
              onLongSelect: () => longSelected++,
            ),
            item('b', b),
          ],
        ),
      ));
      await tester.pump();

      // Hold the select key, then navigate away before the threshold.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(longSelected, 0, reason: 'the timer must die with the focus');
      expect(selected, 0, reason: 'a canceled hold must not fire on release');

      // Same via a programmatic unfocus mid-hold.
      a.requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 100));
      Dpad.of(tester.element(find.text('a'))).clearFocus();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(longSelected, 0);
      expect(selected, 0);
    });

    testWidgets('a shorter longSelectDuration fires onLongSelect sooner',
        (tester) async {
      final node = FocusNode();
      int selected = 0;
      int longSelected = 0;

      await tester.pumpWidget(tvApp(
        theme: const DpadThemeData(
          longSelectDuration: Duration(milliseconds: 200),
        ),
        home: item(
          'a',
          node,
          autofocus: true,
          onSelect: () => selected++,
          onLongSelect: () => longSelected++,
        ),
      ));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 150));
      expect(longSelected, 0, reason: 'below the custom 200ms threshold');

      await tester.pump(const Duration(milliseconds: 150)); // 300ms total
      expect(longSelected, 1,
          reason: 'the default 500ms threshold was overridden to 200ms');

      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 0,
          reason: 'the long-press already consumed the gesture');
    });

    testWidgets('tapping the item focuses it and fires onSelect',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      int selected = 0;

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item('a', a, autofocus: true),
            item('b', b, onSelect: () => selected++),
          ],
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('b'));
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
      expect(selected, 1);
    });
  });

  group('keys on the item', () {
    testWidgets('onDirection can consume directional presses', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final seen = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item(
              'a',
              a,
              autofocus: true,
              onDirection: (direction) {
                seen.add(direction);
                return direction == TraversalDirection.right;
              },
            ),
            item('b', b),
          ],
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(seen, [TraversalDirection.right]);
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'consumed press must not move focus');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(seen, [TraversalDirection.right, TraversalDirection.down]);
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'no target below, focus stays put');
    });
  });

  group('focus state', () {
    testWidgets('onFocusChange reports gain and loss', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final log = <bool>[];

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item('a', a, autofocus: true, onFocusChange: log.add),
            item('b', b),
          ],
        ),
      ));
      await tester.pump();
      expect(log, [true]);

      b.requestFocus();
      await tester.pump();
      expect(log, [true, false]);
    });

    testWidgets('builder receives the pressed state', (tester) async {
      final node = FocusNode();

      await tester.pumpWidget(tvApp(
        home: DpadFocusable(
          focusNode: node,
          autofocus: true,
          onSelect: () {},
          builder: (context, state, child) =>
              Text(state.pressed ? 'pressed' : 'idle'),
          child: const SizedBox.shrink(),
        ),
      ));
      await tester.pump();
      expect(find.text('idle'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('pressed'), findsOneWidget);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('idle'), findsOneWidget);
    });

    testWidgets('theme effects apply when the item declares none',
        (tester) async {
      final node = FocusNode();

      await tester.pumpWidget(tvApp(
        home: DpadFocusable(
          focusNode: node,
          autofocus: true,
          child: const SizedBox(width: 60, height: 60),
        ),
      ));
      await tester.pump();

      final scale = tester.widget<AnimatedScale>(
        find.descendant(
          of: find.byType(DpadFocusable),
          matching: find.byType(AnimatedScale),
        ),
      );
      expect(scale.scale, const DpadScaleEffect().scale);
    });

    testWidgets('child focusables are excluded by default', (tester) async {
      final node = FocusNode();
      final sibling = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            DpadFocusable(
              focusNode: node,
              autofocus: true,
              effects: const <DpadEffect>[],
              child: ElevatedButton(onPressed: () {}, child: const Text('go')),
            ),
            item('sibling', sibling),
          ],
        ),
      ));
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);

      // There is somewhere real to land, and the wrapped button must not
      // be a second d-pad stop on the way there.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(sibling.hasPrimaryFocus, isTrue,
          reason: 'the move lands on the sibling, not the wrapped button');
      expect(
        node.traversalDescendants,
        isEmpty,
        reason: 'the child button is not a traversal candidate',
      );
    });

    testWidgets('disabling a focused item releases focus handling',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      bool enabled = true;
      late StateSetter setState;

      await tester.pumpWidget(tvApp(
        home: StatefulBuilder(
          builder: (context, set) {
            setState = set;
            return Row(
              children: [
                item('a', a, autofocus: true, enabled: enabled),
                item('b', b),
              ],
            );
          },
        ),
      ));
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);

      setState(() => enabled = false);
      await tester.pumpAndSettle();
      expect(a.hasPrimaryFocus, isFalse);
    });
  });

  group('auto scroll', () {
    testWidgets('autoScroll: false focuses off-screen items without scrolling',
        (tester) async {
      final controller = ScrollController();
      final nodes = List<FocusNode>.generate(4, (_) => FocusNode());

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          height: 200,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                for (int i = 0; i < 4; i++)
                  DpadFocusable(
                    focusNode: nodes[i],
                    autofocus: i == 0,
                    autoScroll: false,
                    effects: const <DpadEffect>[],
                    child: SizedBox(
                      width: 60,
                      height: 100,
                      child: Center(child: Text('i$i')),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(nodes[0].hasPrimaryFocus, isTrue);

      // Walk past the viewport bottom: focus keeps moving, but the
      // viewport stays pinned.
      for (int i = 1; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(nodes[i].hasPrimaryFocus, isTrue);
      }
      expect(controller.offset, 0.0,
          reason: 'autoScroll: false must never reveal the item');
    });
  });

  group('wrapped text fields', () {
    testWidgets('typing keys reach the field, never the item handlers',
        (tester) async {
      final node = FocusNode();
      final inner = FocusNode();
      final controller = TextEditingController();
      int selected = 0;
      TraversalDirection? interceptedDirection;

      await tester.pumpWidget(tvApp(
        home: Center(
          child: DpadFocusable(
            focusNode: node,
            autofocus: true,
            excludeChildFocus: false,
            onSelect: () => selected++,
            onDirection: (direction) {
              interceptedDirection = direction;
              return true;
            },
            effects: const <DpadEffect>[],
            child: SizedBox(
              width: 220,
              child: TextField(
                focusNode: inner,
                controller: controller,
                maxLines: 3,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      inner.requestFocus();
      await tester.pumpAndSettle();
      expect(inner.hasPrimaryFocus, isTrue);

      // Space and enter are the default select keys — while the caret
      // lives inside, they belong to the field (tests cannot observe the
      // inserted characters, which arrive through the IME channel, so
      // the observable half is that select never fires).
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selected, 0,
          reason: 'Select must not fire while the caret lives inside.');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 0);

      // Arrows edit the caret; the item's interceptor stands down.
      controller.text = 'hello';
      controller.selection =
          const TextSelection.collapsed(offset: 5);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(controller.selection.extentOffset, 4,
          reason: 'The arrow reached the caret instead of being consumed.');
      expect(interceptedDirection, isNull);

      // The guard cuts both ways: with the item itself focused, select
      // still works.
      node.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 1);
    });
  });

  group('semantics', () {
    testWidgets('screen reader activation fires onSelect exactly once',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final node = FocusNode();
      int selected = 0;

      await tester.pumpWidget(tvApp(
        home: Center(
          child: DpadFocusable(
            focusNode: node,
            autofocus: true,
            semanticLabel: 'pick me',
            onSelect: () => selected++,
            effects: const <DpadEffect>[],
            child: const SizedBox(width: 60, height: 60),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final SemanticsData data = find
          .semantics.byLabel('pick me')
          .evaluate()
          .single
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue,
          reason: 'an activatable item exposes a tap action');

      tester.semantics.tap(find.semantics.byLabel('pick me'));
      await tester.pumpAndSettle();
      expect(selected, 1,
          reason: 'assistive activation dispatches exactly one select');
      handle.dispose();
    });

    testWidgets('long-select items expose tap and long-press actions',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final node = FocusNode();
      int selected = 0;
      int longSelected = 0;

      await tester.pumpWidget(tvApp(
        home: Center(
          child: DpadFocusable(
            focusNode: node,
            autofocus: true,
            semanticLabel: 'poster',
            onSelect: () => selected++,
            onLongSelect: () => longSelected++,
            effects: const <DpadEffect>[],
            child: const SizedBox(width: 60, height: 60),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // The gesture detector stands down from semantics entirely; the
      // semantics wrapper provides both actions.
      final SemanticsData data = find
          .semantics.byLabel('poster')
          .evaluate()
          .single
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.longPress), isTrue);

      tester.semantics.tap(find.semantics.byLabel('poster'));
      await tester.pumpAndSettle();
      expect(selected, 1,
          reason: 'a semantic tap is a full tap: select fires');
      expect(longSelected, 0);

      tester.semantics.longPress(find.semantics.byLabel('poster'));
      await tester.pumpAndSettle();
      expect(longSelected, 1);
      expect(selected, 1, reason: 'the long press does not double-fire select');
      handle.dispose();
    });

    testWidgets('assistive activation also focuses the item', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final node = FocusNode();
      final other = FocusNode();
      int selected = 0;

      await tester.pumpWidget(tvApp(
        home: Center(
          child: Row(children: <Widget>[
            DpadFocusable(
              focusNode: node,
              semanticLabel: 'remote target',
              onSelect: () => selected++,
              effects: const <DpadEffect>[],
              child: const SizedBox(width: 60, height: 60),
            ),
            item('other', other, autofocus: true),
          ]),
        ),
      ));
      await tester.pumpAndSettle();
      expect(other.hasPrimaryFocus, isTrue);

      // Like the touch path (tap-down focuses), a screen reader activation
      // of an unfocused item must not fire onSelect out of focus context.
      tester.semantics.tap(find.semantics.byLabel('remote target'));
      await tester.pumpAndSettle();
      expect(node.hasPrimaryFocus, isTrue,
          reason: 'activation focuses the item first');
      expect(selected, 1);
      handle.dispose();
    });

    testWidgets('the accessibility label is announced',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final node = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Center(
          child: DpadFocusable(
            focusNode: node,
            autofocus: true,
            semanticLabel: 'Play Castaway',
            onSelect: () {},
            effects: const <DpadEffect>[],
            child: const SizedBox(width: 60, height: 60),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find
            .semantics.byLabel('Play Castaway')
            .evaluate()
            .single
            .getSemanticsData()
            .label,
        contains('Play Castaway'),
        reason: 'the explicit label is what screen readers announce',
      );
      handle.dispose();
    });

    testWidgets('disabled items expose no activation',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final node = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Center(
          child: DpadFocusable(
            focusNode: node,
            autofocus: true,
            enabled: false,
            semanticLabel: 'locked',
            onSelect: () {},
            effects: const <DpadEffect>[],
            child: const SizedBox(width: 60, height: 60),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Raw flags instead of an `isSemantics` matcher — the package's own
      // declared floor (Flutter 3.19) must be able to run this suite.
      final SemanticsData data =
          find.semantics.byLabel('locked').evaluate().single.getSemanticsData();
      // `hasFlag` is deprecated past 3.32 but its replacement does not
      // exist on the 3.19 floor — the raw flags are the portable form.
      // ignore: deprecated_member_use
      expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
      // ignore: deprecated_member_use
      expect(data.hasFlag(SemanticsFlag.isEnabled), isFalse,
          reason: 'still a focus target, just not an enabled one');
      handle.dispose();
    });

    testWidgets(
        'an interactive child keeps its own semantics and activation',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final node = FocusNode();
      int selected = 0;
      int pressed = 0;

      // The README's best-practice shape: a Material button as pure
      // visuals. The child is a semantics boundary, so the labeled node
      // is the button's — its tap runs onPressed, not the wrapper's
      // onSelect. Wiring them to the same behavior (or ExcludeSemantics)
      // is the app's call; the contract to pin is that neither pipeline
      // silently steals the other.
      await tester.pumpWidget(tvApp(
        home: Center(
          child: DpadFocusable(
            focusNode: node,
            autofocus: true,
            semanticLabel: 'item',
            onSelect: () => selected++,
            effects: const <DpadEffect>[],
            child: ElevatedButton(
              onPressed: () => pressed++,
              child: const Text('go'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      tester.semantics.tap(find.semantics.byLabel('go'));
      await tester.pumpAndSettle();
      expect(pressed, 1,
          reason: 'the child node carries its own activation');
      expect(selected, 0,
          reason: 'the wrapper must not shadow an interactive child');

      // The wrapper node keeps its own button role and serves its own
      // action for readers that reach it.
      final SemanticsData wrapper =
          find.semantics.byLabel('item').evaluate().single.getSemanticsData();
      // ignore: deprecated_member_use
      expect(wrapper.hasFlag(SemanticsFlag.isButton), isTrue);
      tester.semantics.tap(find.semantics.byLabel('item'));
      await tester.pumpAndSettle();
      expect(selected, 1,
          reason: 'tapping the wrapper node itself fires onSelect');
      handle.dispose();
    });

    testWidgets('tapToSelect: false still exposes activation',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final node = FocusNode();
      int selected = 0;

      await tester.pumpWidget(tvApp(
        home: Center(
          child: DpadFocusable(
            focusNode: node,
            autofocus: true,
            tapToSelect: false,
            semanticLabel: 'keyboard only',
            onSelect: () => selected++,
            effects: const <DpadEffect>[],
            child: const SizedBox(width: 60, height: 60),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      tester.semantics.tap(find.semantics.byLabel('keyboard only'));
      await tester.pumpAndSettle();
      expect(selected, 1,
          reason: 'with the gesture off, the semantics wrapper serves the tap');
      handle.dispose();
    });
  });
}
