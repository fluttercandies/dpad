import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  group('controller', () {
    testWidgets('move / select / requestFocus work programmatically',
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

      final dpad = Dpad.of(tester.element(find.text('a')));

      expect(dpad.moveRight(), isTrue);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
      expect(dpad.focused, b);

      expect(dpad.select(), isTrue);
      await tester.pump();
      expect(selected, 1);

      expect(dpad.requestFocus(a), isTrue);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);

      dpad.clearFocus();
      await tester.pump();
      expect(dpad.focused, isNull);
    });

    testWidgets('next and previous walk the reading order', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final c = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item('a', a, autofocus: true),
            item('b', b),
            item('c', c),
          ],
        ),
      ));
      await tester.pump();

      final dpad = Dpad.of(tester.element(find.text('a')));

      expect(dpad.next(), isTrue);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      expect(dpad.next(), isTrue);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue);

      // The reading order wraps around, like Tab.
      expect(dpad.next(), isTrue);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);

      expect(dpad.previous(), isTrue);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue);
    });

    testWidgets('requestFocus moves focus and scrolls the target into view',
        (tester) async {
      final controller = ScrollController();
      final nodes = List<FocusNode>.generate(6, (_) => FocusNode());

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          height: 200,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                for (int i = 0; i < 6; i++) item('$i', nodes[i], size: 100),
              ],
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(nodes[0].hasPrimaryFocus, isTrue);

      final dpad = Dpad.of(tester.element(find.text('0')));
      expect(dpad.requestFocus(nodes[5]), isTrue);
      await tester.pumpAndSettle();
      expect(nodes[5].hasPrimaryFocus, isTrue);
      expect(controller.offset, greaterThan(0),
          reason: 'the far-off target must be revealed');
    });
  });

  group('frozen navigation (enabled: false)', () {
    testWidgets('arrow keys are consumed and focus never moves',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final c = FocusNode();

      await tester.pumpWidget(tvApp(
        enabled: false,
        home: Column(
          children: [
            Row(children: [item('a', a, autofocus: true), item('b', b)]),
            item('c', c),
          ],
        ),
      ));
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);

      // Every direction has somewhere to go, and none may be taken — not
      // by Dpad, and not by the framework's own default arrow shortcuts,
      // which navigate with this very policy and must not leak through.
      for (final LogicalKeyboardKey key in const [
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowUp,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(a.hasPrimaryFocus, isTrue, reason: '$key must be swallowed');
      }
    });

    testWidgets('select keys keep working while frozen', (tester) async {
      final a = FocusNode();
      int selected = 0;

      await tester.pumpWidget(tvApp(
        enabled: false,
        home: item('a', a, autofocus: true, onSelect: () => selected++),
      ));
      await tester.pump();

      // Select is what lets a frozen UI (an on-screen toggle) come back.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 1);

      final dpad = Dpad.of(tester.element(find.text('a')));
      expect(dpad.select(), isTrue);
      await tester.pump();
      expect(selected, 2);
    });

    testWidgets('back, menu and app shortcuts stand down while frozen',
        (tester) async {
      final a = FocusNode();
      int backs = 0;
      int menus = 0;
      int hits = 0;

      await tester.pumpWidget(tvApp(
        enabled: false,
        onBack: () {
          backs++;
          return true;
        },
        onMenu: () => menus++,
        shortcuts: {LogicalKeyboardKey.keyG: () => hits++},
        home: item('a', a, autofocus: true),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.pump();
      expect(backs, 0, reason: 'back keys stand down while frozen');
      expect(menus, 0, reason: 'menu keys stand down while frozen');
      expect(hits, 0, reason: 'app shortcuts stand down while frozen');
    });

    testWidgets('while frozen, arrows still edit a focused text field',
        (tester) async {
      final field = FocusNode();
      final controller = TextEditingController(text: 'ab');
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        enabled: false,
        home: TextField(focusNode: field, controller: controller),
      ));
      field.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 1);
      await tester.pump();

      // Frozen navigation falls back to plain caret editing inside the
      // field — the keys are still consumed there, so nothing leaks out.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(controller.selection.baseOffset, 2,
          reason: 'the caret must still move while frozen');
      expect(field.hasFocus, isTrue);

      // At the caret end the editing layer keeps consuming the key: focus
      // must not escape the field while frozen.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(field.hasFocus, isTrue,
          reason: 'frozen navigation must never move focus, not even out '
              'of a field');
    });

    testWidgets('controller back stands down in a focused text field',
        (tester) async {
      final field = FocusNode();
      final a = FocusNode();
      int backs = 0;

      await tester.pumpWidget(tvApp(
        onBack: () {
          backs++;
          return true;
        },
        home: Column(
          children: [
            item('a', a),
            TextField(focusNode: field),
          ],
        ),
      ));
      await tester.pump();
      field.requestFocus();
      await tester.pump();

      final dpad = Dpad.of(tester.element(find.byType(TextField)));
      // The IME owns the back key while editing; the programmatic
      // equivalent must not act where the remote itself would not.
      expect(dpad.back(), isFalse);
      expect(backs, 0, reason: 'the IME owns the keys while editing');

      // A programmatic move, by contrast, acts directly — the caret-editing
      // gates belong to the key pipeline (documented difference).
      expect(dpad.move(TraversalDirection.up), isTrue);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'a programmatic move bypasses the caret gates');
    });

    testWidgets('controller moves report failure while frozen', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      int backs = 0;

      await tester.pumpWidget(tvApp(
        enabled: false,
        onBack: () {
          backs++;
          return true;
        },
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
      ));
      await tester.pump();

      final dpad = Dpad.of(tester.element(find.text('a')));
      expect(dpad.moveDown(), isFalse);
      expect(dpad.move(TraversalDirection.right), isFalse);
      // Tab-order moves and the programmatic back are remote-equivalent
      // actions: a scripted caller must not navigate around the freeze.
      expect(dpad.next(), isFalse);
      expect(dpad.previous(), isFalse);
      expect(dpad.back(), isFalse);
      expect(backs, 0, reason: 'the programmatic back stands down too');
      await tester.pump();
      expect(b.hasPrimaryFocus, isFalse);
    });
  });

  group('key handling', () {
    testWidgets('custom key set remaps directions', (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        keySet: const DpadKeySet().copyWith(
          right: const [LogicalKeyboardKey.keyD],
        ),
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      // Arrow right was remapped away.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('an equal-but-rebuilt key set keeps the shortcut map',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      DpadKeySet keys() => const DpadKeySet().copyWith(
            right: const [LogicalKeyboardKey.keyD],
          );

      await tester.pumpWidget(tvApp(
        keySet: keys(),
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
      ));
      await tester.pump();
      final Finder shortcuts = find.descendant(
        of: find.byType(Dpad),
        matching: find.byType(Shortcuts),
      );
      final Map<ShortcutActivator, Intent> first =
          tester.widget<Shortcuts>(shortcuts).shortcuts;

      // A root rebuild (the settings-toggle pattern) hands over a new but
      // equal instance; the memoized map must survive it — the key set
      // compares by value, not identity.
      await tester.pumpWidget(tvApp(
        keySet: keys(),
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
      ));
      await tester.pump();
      expect(
          identical(first, tester.widget<Shortcuts>(shortcuts).shortcuts),
          isTrue,
          reason: 'an equal rebuild must not re-resolve the shortcut map');

      // And the remapped key still drives through the reused map.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('an equal-but-rebuilt shortcuts map keeps the memo too',
        (tester) async {
      final a = FocusNode();
      int hitsOne = 0;
      int hitsTwo = 0;
      // Top-level-stable callbacks: mapEquals compares values, and
      // closures compare by identity — so the same tear-offs across
      // rebuilds are what an app hoists (see the example's _shortcuts).
      void callbackOne() => hitsOne++;
      void callbackTwo() => hitsTwo++;

      await tester.pumpWidget(tvApp(
        shortcuts: <LogicalKeyboardKey, VoidCallback>{
          LogicalKeyboardKey.f5: callbackOne,
        },
        home: item('a', a, autofocus: true),
      ));
      await tester.pump();
      final Finder shortcuts = find.descendant(
        of: find.byType(Dpad),
        matching: find.byType(Shortcuts),
      );
      final Map<ShortcutActivator, Intent> first =
          tester.widget<Shortcuts>(shortcuts).shortcuts;

      // A fresh but equal map literal keeps the memoized shortcut map.
      await tester.pumpWidget(tvApp(
        shortcuts: <LogicalKeyboardKey, VoidCallback>{
          LogicalKeyboardKey.f5: callbackOne,
        },
        home: item('a', a, autofocus: true),
      ));
      await tester.pump();
      expect(
          identical(first, tester.widget<Shortcuts>(shortcuts).shortcuts),
          isTrue,
          reason: 'an equal rebuild must not re-resolve the shortcut map');

      // A genuinely different callback re-resolves — and the new one
      // fires.
      await tester.pumpWidget(tvApp(
        shortcuts: <LogicalKeyboardKey, VoidCallback>{
          LogicalKeyboardKey.f5: callbackTwo,
        },
        home: item('a', a, autofocus: true),
      ));
      await tester.pump();
      expect(identical(first, tester.widget<Shortcuts>(shortcuts).shortcuts),
          isFalse,
          reason: 'a changed callback must rebuild the shortcut map');
      await tester.sendKeyEvent(LogicalKeyboardKey.f5);
      await tester.pump();
      expect(hitsOne, 0);
      expect(hitsTwo, 1);
    });

    testWidgets('onBack consumes back keys when it returns true',
        (tester) async {
      final a = FocusNode();
      int backs = 0;

      await tester.pumpWidget(tvApp(
        onBack: () {
          backs++;
          return true;
        },
        home: item('a', a, autofocus: true),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(backs, 1);
    });

    testWidgets('onMenu fires for menu keys', (tester) async {
      final a = FocusNode();
      int menus = 0;

      await tester.pumpWidget(tvApp(
        onMenu: () => menus++,
        home: item('a', a, autofocus: true),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(menus, 1);
    });

    testWidgets('app shortcuts fire, but never while editing text',
        (tester) async {
      final a = FocusNode();
      int hits = 0;
      final field = FocusNode();

      await tester.pumpWidget(tvApp(
        shortcuts: {LogicalKeyboardKey.keyG: () => hits++},
        home: Column(
          children: [
            TextField(focusNode: field),
            item('a', a),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.pump();
      expect(hits, 0, reason: 'shortcuts must stand down while typing');

      a.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.pump();
      expect(hits, 1);
    });

    testWidgets('arrow keys keep moving the caret while editing text',
        (tester) async {
      final a = FocusNode();
      final field = FocusNode();
      final controller = TextEditingController(text: 'hello');
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            TextField(focusNode: field, controller: controller),
            item('a', a),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 5);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(field.hasFocus, isTrue,
          reason: 'arrows must not steal focus mid-text');
      expect(controller.selection.baseOffset, 4);
    });

    testWidgets('down leaves a focused single-line text field', (tester) async {
      final a = FocusNode();
      final field = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            TextField(focusNode: field),
            item('a', a),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'a remote-only user must never be trapped in a field');
    });

    testWidgets('left at the caret start leaves the text field',
        (tester) async {
      final left = FocusNode();
      final field = FocusNode();
      final controller = TextEditingController(text: 'hi');
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item('left', left),
            SizedBox(
              width: 200,
              child: TextField(focusNode: field, controller: controller),
            ),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(left.hasPrimaryFocus, isTrue,
          reason: 'caret at the start: left exits the field');
    });

    testWidgets('RTL text fields edit logically and exit at the caret ends',
        (tester) async {
      final outside = FocusNode();
      final field = FocusNode();
      final controller = TextEditingController(text: 'لكن');
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 200,
                child: TextField(focusNode: field, controller: controller),
              ),
              // In RTL this sits physically to the *left* of the field.
              item('outside', outside),
            ],
          ),
        ),
      ));
      field.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();

      // The caret at logical offset 0 renders on the right edge, but the
      // field moves it logically: right edits, left exits — same as LTR.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(field.hasPrimaryFocus, isTrue,
          reason: 'logical offset 1 is reachable: right must edit, not exit');
      expect(controller.selection.baseOffset, 1);

      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(outside.hasPrimaryFocus, isTrue,
          reason: 'caret at the logical start: left exits the field');
    });

    testWidgets('right at the caret end leaves the text field', (tester) async {
      final right = FocusNode();
      final field = FocusNode();
      final controller = TextEditingController(text: 'hi');
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            SizedBox(
              width: 200,
              child: TextField(focusNode: field, controller: controller),
            ),
            item('right', right),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(right.hasPrimaryFocus, isTrue,
          reason: 'caret at the end: right exits the field');
    });

    testWidgets('down leaves the field with the caret resting at the end',
        (tester) async {
      final below = FocusNode();
      final field = FocusNode();
      final controller = TextEditingController(text: 'hi');
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            SizedBox(
              width: 200,
              child: TextField(focusNode: field, controller: controller),
            ),
            item('below', below),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(below.hasPrimaryFocus, isTrue,
          reason: 'a single-line field has no vertical caret movement: '
              'down exits it wherever the caret rests');
    });

    testWidgets('right mid-text edits the caret instead of leaving',
        (tester) async {
      final field = FocusNode();
      final controller = TextEditingController(text: 'hello');
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        home: TextField(focusNode: field, controller: controller),
      ));
      field.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(field.hasFocus, isTrue,
          reason: 'mid-text arrows must not steal focus');
      expect(controller.selection.baseOffset, 3);
    });

    testWidgets('onBack returning false lets the framework dismiss the dialog',
        (tester) async {
      final a = FocusNode();
      int backs = 0;

      await tester.pumpWidget(tvApp(
        onBack: () {
          backs++;
          return false;
        },
        home: item('a', a, autofocus: true),
      ));
      await tester.pump();

      showDialog<void>(
        context: tester.element(find.text('a')),
        builder: (context) => const AlertDialog(title: Text('dialog')),
      );
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(backs, 1);
      expect(find.text('dialog'), findsNothing,
          reason: 'returning false hands the key back to the framework, '
              'which pops the dismissible dialog route');
    });

    testWidgets('onBack returning true keeps the dialog open', (tester) async {
      final a = FocusNode();
      int backs = 0;

      await tester.pumpWidget(tvApp(
        onBack: () {
          backs++;
          return true;
        },
        home: item('a', a, autofocus: true),
      ));
      await tester.pump();

      showDialog<void>(
        context: tester.element(find.text('a')),
        builder: (context) => const AlertDialog(title: Text('dialog')),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(backs, 1);
      expect(find.text('dialog'), findsOneWidget,
          reason: 'returning true consumes the key: the route stays');
    });

    testWidgets('back and menu keys stand down while editing and return after',
        (tester) async {
      final a = FocusNode();
      final field = FocusNode();
      int backs = 0;
      int menus = 0;

      await tester.pumpWidget(tvApp(
        onBack: () {
          backs++;
          return true;
        },
        onMenu: () => menus++,
        home: Column(
          children: [
            TextField(focusNode: field),
            item('a', a),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(backs, 0, reason: 'the IME owns the back key while editing');
      expect(menus, 0, reason: 'the IME owns the menu key while editing');

      a.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(backs, 1, reason: 'back resumes once the field is left');
      expect(menus, 1, reason: 'menu resumes once the field is left');
    });

    testWidgets('WASD movement keys never hijack typing in a text field',
        (tester) async {
      final b = FocusNode();
      final field = FocusNode();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        keySet: const DpadKeySet().copyWith(
          up: const [LogicalKeyboardKey.keyW, ...DpadKeySet.defaultUp],
          left: const [LogicalKeyboardKey.keyA, ...DpadKeySet.defaultLeft],
          down: const [LogicalKeyboardKey.keyS, ...DpadKeySet.defaultDown],
          right: const [LogicalKeyboardKey.keyD, ...DpadKeySet.defaultRight],
        ),
        home: Row(
          children: [
            SizedBox(
              width: 200,
              child: TextField(focusNode: field, controller: controller),
            ),
            item('b', b),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();

      // Remapped movement keys fall through while an editable is focused:
      // pressing them must neither move focus nor disturb the field.
      for (final LogicalKeyboardKey key in const [
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyS,
        LogicalKeyboardKey.keyD,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(field.hasFocus, isTrue, reason: '$key must not steal focus');
      }

      // The IME text channel keeps working: typing "wasd" inserts it.
      await tester.enterText(find.byType(TextField), 'wasd');
      await tester.pump();
      expect(controller.text, 'wasd');
      expect(field.hasFocus, isTrue);

      // The physical arrows keep the caret-edge escape contract even with
      // the remap (enterText leaves the caret at the end).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'caret at the end: right still exits the field');
    });

    testWidgets('remapped select and back keys take over their roles',
        (tester) async {
      final a = FocusNode();
      int selected = 0;
      int backs = 0;

      await tester.pumpWidget(tvApp(
        keySet: const DpadKeySet().copyWith(
          select: const [LogicalKeyboardKey.keyF],
          back: const [LogicalKeyboardKey.keyB],
        ),
        onBack: () {
          backs++;
          return true;
        },
        home: item('a', a, autofocus: true, onSelect: () => selected++),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pump();
      expect(selected, 1, reason: 'keyF is the remapped select key');

      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pump();
      expect(backs, 1, reason: 'keyB is the remapped back key');

      // The dropped default back key no longer requests back navigation.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(backs, 1);
    });

    // Deliberate semantics (documented on DpadKeySet.select): keyboard
    // activation keys (enter, space) reach DpadFocusable through the
    // framework's own ActivateIntent shortcuts — like any Flutter button —
    // so remapping select ADDS keys, it cannot disarm the keyboard ones.
    testWidgets(
      'remapping select is additive: keyboard activation keys keep working',
      (tester) async {
        final a = FocusNode();
        int selected = 0;

        await tester.pumpWidget(tvApp(
          keySet: const DpadKeySet().copyWith(
            select: const [LogicalKeyboardKey.keyF],
          ),
          home: item('a', a, autofocus: true, onSelect: () => selected++),
        ));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(selected, 1, reason: 'space activates like any Flutter button');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(selected, 2, reason: 'enter activates like any Flutter button');

        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.pump();
        expect(selected, 3, reason: 'the remapped select key also selects');
      },
    );

    testWidgets('arrows do not escape a field mid-composition', (tester) async {
      final b = FocusNode();
      final field = FocusNode();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            TextField(focusNode: field, controller: controller),
            item('b', b),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();
      // An active composing region (the IME mid-word): every key, arrows
      // included, belongs to the IME.
      controller.value = const TextEditingValue(
        text: 'ab',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(field.hasFocus, isTrue,
          reason: 'the IME owns the arrows while composing');

      // Once the composition is committed, the caret-edge contract resumes.
      controller.value = controller.value.copyWith(composing: TextRange.empty);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('multiline fields keep vertical caret movement inside',
        (tester) async {
      final below = FocusNode();
      final field = FocusNode();
      final controller = TextEditingController(text: 'one\ntwo\nthree');
      addTearDown(controller.dispose);

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                focusNode: field,
                controller: controller,
                maxLines: 3,
              ),
            ),
            item('below', below),
          ],
        ),
      ));
      field.requestFocus();
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 4); // 'two'
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(field.hasFocus, isTrue);
      expect(controller.selection.baseOffset, 0,
          reason: 'the caret moved up to line 1');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(field.hasFocus, isTrue);
      expect(controller.selection.baseOffset, 4,
          reason: 'and back down to line 2');
    });

    testWidgets(
      'multiline fields escape vertically at the text bounds',
      (tester) async {
        final above = FocusNode();
        final below = FocusNode();
        final field = FocusNode();
        final controller = TextEditingController(text: 'one\ntwo\nthree');
        addTearDown(controller.dispose);

        await tester.pumpWidget(tvApp(
          home: Column(
            children: [
              item('above', above),
              SizedBox(
                width: 200,
                child: TextField(
                  focusNode: field,
                  controller: controller,
                  maxLines: 3,
                ),
              ),
              item('below', below),
            ],
          ),
        ));
        field.requestFocus();
        await tester.pump();

        // Caret at the text's very start: no line above — up must leave.
        controller.selection = const TextSelection.collapsed(offset: 0);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(above.hasPrimaryFocus, isTrue,
            reason: 'up from the first line escapes the field');

        // Caret at the text's very end: no line below — down must leave.
        field.requestFocus();
        await tester.pump();
        controller.selection =
            TextSelection.collapsed(offset: controller.text.length);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(below.hasPrimaryFocus, isTrue,
            reason: 'down from the last line escapes the field');
      },
    );

    testWidgets('held arrow keys keep moving focus on repeats', (tester) async {
      final nodes = List<FocusNode>.generate(4, (_) => FocusNode());

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            for (int i = 0; i < 4; i++) item('$i', nodes[i], autofocus: i == 0),
          ],
        ),
      ));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue);

      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[2].hasPrimaryFocus, isTrue);

      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue);

      // One repeat past the end: consumed, no crash, focus stays put.
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue);
    });
  });

  group('focus resilience', () {
    testWidgets('removing the focused item moves focus to its neighbor',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      bool showA = true;
      late StateSetter setState;

      await tester.pumpWidget(tvApp(
        home: StatefulBuilder(
          builder: (context, set) {
            setState = set;
            return Row(
              children: [
                if (showA) item('a', a, autofocus: true),
                item('b', b),
              ],
            );
          },
        ),
      ));
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);

      setState(() => showA = false);
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'focus must never die with its widget');
    });

    testWidgets('popping a route restores focus on the previous page',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      final navigator = Navigator.of(tester.element(find.text('a')));
      navigator.push(MaterialPageRoute<void>(
        builder: (context) => const Scaffold(
          body: DpadFocusable(
            autofocus: true,
            effects: <DpadEffect>[],
            child: SizedBox(width: 60, height: 60, child: Text('p')),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isFalse);

      navigator.pop();
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'route scopes remember their focused child');
    });

    testWidgets('restoreFocus: false leaves the app unfocused until a key',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        restoreFocus: false,
        home: Row(children: [item('a', a), item('b', b)]),
      ));
      await tester.pumpAndSettle();
      expect(Dpad.of(tester.element(find.text('a'))).focused, isNull,
          reason: 'no autofocus and no fabricated startup focus');

      // The first key press lands on the initial candidate: still drivable.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);
    });

    testWidgets('restoreFocus: false does not resurrect a dead focus',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      bool showA = true;
      late StateSetter setState;

      await tester.pumpWidget(tvApp(
        restoreFocus: false,
        home: StatefulBuilder(
          builder: (context, set) {
            setState = set;
            return Row(
              children: [
                if (showA) item('a', a, autofocus: true),
                item('b', b),
              ],
            );
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(a.hasPrimaryFocus, isTrue);

      setState(() => showA = false);
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isFalse,
          reason: 'focus must not jump to the neighbor on its own');
      expect(Dpad.of(tester.element(find.text('b'))).focused, isNull);

      // The remote still works: a press lands on the surviving item.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('restoreFocus: false gives a pushed route no initial focus',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final p1 = FocusNode();
      final p2 = FocusNode();

      await tester.pumpWidget(tvApp(
        restoreFocus: false,
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
      ));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      final navigator = Navigator.of(tester.element(find.text('a')));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: Row(children: [item('p1', p1), item('p2', p2)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(p1.hasPrimaryFocus, isFalse,
          reason: 'contrast with the default: the root no longer hands '
              'fresh routes an initial focus');
      expect(p2.hasPrimaryFocus, isFalse);

      navigator.pop();
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'route scope memory is native and independent of '
              'restoreFocus');
    });

    testWidgets('resuming from background returns focus to where the user was',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
      ));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      // A deliberate unfocus is left alone by the root...
      Dpad.of(tester.element(find.text('a'))).clearFocus();
      await tester.pumpAndSettle();
      expect(Dpad.of(tester.element(find.text('a'))).focused, isNull);

      // ...but coming back from background returns the user to where they
      // were.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'resume restores the last focused item');

      // Keys keep working after the lifecycle round-trip.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);
    });

    testWidgets(
        'a resume arriving while a plain restore is queued still restores',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
      ));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      // A deliberate unfocus queues a plain (non-resume) restore. The
      // focus notification is deferred to a microtask by FocusManager, so
      // yield once — the restore is now queued but, with no frame pumped,
      // still unexecuted.
      Dpad.of(tester.element(find.text('a'))).clearFocus();
      await null;
      await null;

      // On a device, frames are suspended while backgrounded, so a
      // restore queued just before the pause survives it, and the resume
      // event arrives before the post-frame callback runs. The pending
      // restore must keep the resume flag instead of running as a plain
      // one (which would treat the unfocus as deliberate and skip).
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'the queued restore must not downgrade the resume');

      // Keys keep working after the interleaved round-trip.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);
    });

    testWidgets(
        'repeated resumes while a plain restore is queued restore once',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final restored = <String>[];

      await tester.pumpWidget(tvApp(
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
        onFocusChange: (node) {
          if (node == b) {
            restored.add('b');
          }
        },
      ));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
      restored.clear();

      // A queued plain restore followed by two resume events in a row:
      // the flag accumulates idempotently and the restore runs once.
      Dpad.of(tester.element(find.text('a'))).clearFocus();
      await null;
      await null;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue);
      expect(restored, ['b'],
          reason: 'focus returns to b exactly once, not per resume event');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);
    });

    // Deliberate semantics: Dpad does not gate key handling on lifecycle
    // states — the OS delivers no key events while the app is truly
    // backgrounded anyway, and on desktops a brief `inactive` (window
    // blur) must not freeze navigation. Resuming restores focus (covered
    // above); that is the entire lifecycle contract.
    testWidgets('keys keep working while the app is inactive', (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
      ));
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'a window blur must not freeze navigation');
    });
  });

  group('blocked moves (onBlockedMove)', () {
    testWidgets('a dead end reports the blocked direction', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final List<TraversalDirection> blocked = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        home: Row(children: [item('a', a, autofocus: true), item('b', b)]),
        onBlockedMove: blocked.add,
      ));
      await tester.pump();

      final DpadController dpad = Dpad.of(tester.element(find.text('a')));
      expect(dpad.moveRight(), isTrue);
      await tester.pump();
      expect(blocked, isEmpty,
          reason: 'a successful move is not a blocked move');

      expect(dpad.moveRight(), isFalse);
      expect(blocked, <TraversalDirection>[TraversalDirection.right],
          reason: 'past the last item there is nothing to land on');
    });

    testWidgets('a region stop edge reports even though the key is consumed',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final List<TraversalDirection> blocked = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        onBlockedMove: blocked.add,
        home: DpadRegion(
          verticalEdge: DpadEdgeBehavior.stop,
          child: Column(children: [
            item('a', a, autofocus: true),
            item('b', b),
          ]),
        ),
      ));
      await tester.pump();

      final DpadController dpad = Dpad.of(tester.element(find.text('a')));
      expect(dpad.moveDown(), isTrue);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
      expect(blocked, isEmpty,
          reason: 'moving within the region is not blocked');

      // The stop edge consumes the key (move() reports true) — the
      // callback still fires.
      expect(dpad.moveDown(), isTrue);
      expect(blocked, <TraversalDirection>[TraversalDirection.down]);
    });

    testWidgets('a lineWrap with nowhere to line-step reports too',
        (tester) async {
      final a = FocusNode();
      final List<TraversalDirection> blocked = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        onBlockedMove: blocked.add,
        home: DpadRegion(
          verticalEdge: DpadEdgeBehavior.lineWrap,
          child: Column(children: [item('a', a, autofocus: true)]),
        ),
      ));
      await tester.pump();

      final DpadController dpad = Dpad.of(tester.element(find.text('a')));
      expect(dpad.moveDown(), isTrue,
          reason: 'the key is consumed, like stop');
      expect(blocked, <TraversalDirection>[TraversalDirection.down],
          reason: 'a failed line step reads the same as any other block');
    });

    testWidgets('a region stop edge also fires DpadRegion.onEdge',
        (tester) async {
      final a = FocusNode();
      final List<TraversalDirection> blocked = <TraversalDirection>[];
      final List<TraversalDirection> edges = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        onBlockedMove: blocked.add,
        home: DpadRegion(
          verticalEdge: DpadEdgeBehavior.stop,
          onEdge: edges.add,
          child: Column(children: [item('a', a, autofocus: true)]),
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(blocked, <TraversalDirection>[TraversalDirection.up]);
      expect(edges, <TraversalDirection>[TraversalDirection.up],
          reason: 'the region and the root both learn about the block');
    });

    testWidgets('a successful wrap is not a blocked move', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final List<TraversalDirection> blocked = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        onBlockedMove: blocked.add,
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.wrap,
          child: Row(children: [item('a', a, autofocus: true), item('b', b)]),
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
      expect(blocked, isEmpty,
          reason: 'the wrap moved focus — nothing was blocked');

      // Wrapping back around at the other end is also a success.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue);
      expect(blocked, isEmpty);
    });

    testWidgets('a wrap with nothing to wrap to is blocked', (tester) async {
      final a = FocusNode();
      final List<TraversalDirection> blocked = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        onBlockedMove: blocked.add,
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.wrap,
          child: Center(child: item('a', a, autofocus: true)),
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'the key was consumed by the boundary');
      expect(blocked, <TraversalDirection>[TraversalDirection.right],
          reason: 'a one-item line has nothing to wrap to');
    });

    testWidgets('a blocked move does not leak into the next press',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final List<TraversalDirection> blocked = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        onBlockedMove: blocked.add,
        home: Column(children: [
          item('a', a, autofocus: true),
          item('b', b),
        ]),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(blocked, <TraversalDirection>[TraversalDirection.up]);

      // A successful press right after must not see the stale edge from
      // the previous one.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
      expect(blocked, <TraversalDirection>[TraversalDirection.up],
          reason: 'the blocked flag is reset on every fresh press');
    });

    testWidgets('a frozen d-pad never reports blocked moves', (tester) async {
      final a = FocusNode();
      final List<TraversalDirection> blocked = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        enabled: false,
        onBlockedMove: blocked.add,
        home: Row(children: [item('a', a, autofocus: true)]),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(blocked, isEmpty, reason: 'a frozen UI swallows keys silently');
    });

    testWidgets('a direction consumed by onDirection is not blocked',
        (tester) async {
      final a = FocusNode();
      final List<TraversalDirection> blocked = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        onBlockedMove: blocked.add,
        home: item(
          'a',
          a,
          autofocus: true,
          onDirection: (direction) => true,
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(blocked, isEmpty,
          reason: 'the item consumed the key before navigation ran');
    });
  });

  group('select press pulse', () {
    testWidgets('select() pulses the pressed state around the activation',
        (tester) async {
      final a = FocusNode();
      int selected = 0;
      final List<bool> pressedLog = <bool>[];

      await tester.pumpWidget(tvApp(
        home: DpadFocusable(
          focusNode: a,
          autofocus: true,
          onSelect: () => selected++,
          builder: (context, state, child) {
            pressedLog.add(state.pressed);
            return SizedBox(
              width: 60,
              height: 60,
              child: Center(child: Text('a${state.pressed ? '!' : ''}')),
            );
          },
          child: const SizedBox.shrink(),
        ),
      ));
      await tester.pumpAndSettle();
      pressedLog.clear();

      final DpadController dpad = Dpad.of(tester.element(find.text('a')));
      expect(dpad.select(), isTrue);
      await tester.pump();
      expect(selected, 1);
      expect(pressedLog.last, isTrue,
          reason: 'the activation visibly presses the item');

      await tester.pump(DpadController.selectPulseDuration +
          const Duration(milliseconds: 20));
      expect(pressedLog.last, isFalse,
          reason: 'the pulse releases after a beat');
      expect(selected, 1,
          reason: 'the pulse itself never dispatches a second activation');
    });

    testWidgets('the pulse defers to a real key press taking over',
        (tester) async {
      final a = FocusNode();
      final List<bool> pressedLog = <bool>[];

      await tester.pumpWidget(tvApp(
        home: DpadFocusable(
          focusNode: a,
          autofocus: true,
          onSelect: () {},
          builder: (context, state, child) {
            pressedLog.add(state.pressed);
            return SizedBox(
              width: 60,
              height: 60,
              child: Center(child: Text('a${state.pressed ? '!' : ''}')),
            );
          },
          child: const SizedBox.shrink(),
        ),
      ));
      await tester.pumpAndSettle();
      pressedLog.clear();

      final DpadController dpad = Dpad.of(tester.element(find.text('a')));
      dpad.select();
      await tester.pump();

      // A real key press mid-pulse takes the visuals over; its key-up
      // ends the press even though the pulse timer is canceled.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(pressedLog.last, isFalse,
          reason: 'the real press lifecycle finishes cleanly');
    });

    testWidgets('a nested Dpad root owns its subtree\'s focus reporting',
        (tester) async {
      final FocusNode outer = FocusNode();
      final FocusNode inner = FocusNode();
      final List<String> outerReports = <String>[];

      await tester.pumpWidget(tvApp(
        onFocusChange: (FocusNode? node) => outerReports.add('report'),
        home: Row(children: <Widget>[
          item('o', outer, autofocus: true),
          // A nested root: focus inside it belongs to it.
          Dpad(child: item('i', inner)),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(outer.hasPrimaryFocus, isTrue);
      outerReports.clear();

      inner.requestFocus();
      await tester.pumpAndSettle();
      expect(inner.hasPrimaryFocus, isTrue);
      expect(outerReports, isEmpty,
          reason: 'moves inside the nested root do not report to the outer '
              'root, and the outer root does not remember inner nodes');

      // Coming back out reports again, with the outer's own node.
      outer.requestFocus();
      await tester.pumpAndSettle();
      expect(outer.hasPrimaryFocus, isTrue);
      expect(outerReports, <String>['report']);
    });

    testWidgets('select() on a plain button still works (foreign target)',
        (tester) async {
      final a = FocusNode();
      int selected = 0;
      final List<bool> pressedLog = <bool>[];

      await tester.pumpWidget(tvApp(
        highlight: DpadHighlight(
          effects: <DpadHighlightEffect>[
            DpadHighlightCustomEffect(
              (BuildContext context, DpadHighlightState state) {
                pressedLog.add(state.pressed);
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        home: Center(
          child: TextButton(
            focusNode: a,
            autofocus: true,
            onPressed: () => selected++,
            child: const Text('plain'),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      pressedLog.clear();

      final DpadController dpad = Dpad.of(tester.element(find.text('plain')));
      expect(dpad.select(), isTrue);
      await tester.pump();
      expect(selected, 1,
          reason: 'activation works on targets outside the focusable pipeline');
      expect(pressedLog.last, isTrue,
          reason: 'the flying highlight sees the pressed pulse');

      await tester.pump(DpadController.selectPulseDuration +
          const Duration(milliseconds: 20));
      expect(pressedLog.last, isFalse,
          reason: 'the foreign pulse releases after the same beat');
    });
  });
}
