import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

void main() {
  group('directional traversal', () {
    testWidgets('arrow keys move along a row and back', (tester) async {
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
      expect(a.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('vertical navigation stays in the column (beam preference)',
        (tester) async {
      final nodes = List<FocusNode>.generate(6, (_) => FocusNode());

      // 2x3 grid:
      //   0 1 2
      //   3 4 5
      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            Row(children: [
              item('0', nodes[0]),
              item('1', nodes[1], autofocus: true),
              item('2', nodes[2]),
            ]),
            Row(children: [
              item('3', nodes[3]),
              item('4', nodes[4]),
              item('5', nodes[5]),
            ]),
          ],
        ),
      ));
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[4].hasPrimaryFocus, isTrue,
          reason: 'down from 1 must land on 4, not a diagonal neighbor');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue);
    });

    testWidgets(
        'startup focuses the top-left item automatically so the '
        'remote always works', (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(children: [item('a', a), item('b', b)]),
      ));
      await tester.pumpAndSettle();
      expect(a.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('autofocus wins over the automatic startup focus',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(children: [item('a', a), item('b', b, autofocus: true)]),
      ));
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('disabled items are skipped', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final c = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            item('a', a, autofocus: true),
            item('b', b, enabled: false),
            item('c', c),
          ],
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue);
    });

    testWidgets('lazy horizontal lists scroll to reveal unbuilt items',
        (tester) async {
      final controller = ScrollController();
      final first = FocusNode();

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          height: 100,
          child: DpadRegion(
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: 40,
              itemBuilder: (context, index) => DpadFocusable(
                focusNode: index == 0 ? first : null,
                autofocus: index == 0,
                effects: const <DpadEffect>[],
                child: SizedBox(width: 100, child: Text('item$index')),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(first.hasPrimaryFocus, isTrue);

      // Walk right far beyond the initially built children.
      for (int i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(controller.offset, greaterThan(0));
      expect(first.hasPrimaryFocus, isFalse);
    });

    testWidgets(
        'wrap rewinds a lazy list to the true first item, '
        'not the furthest cached one', (tester) async {
      final controller = ScrollController();
      final first = FocusNode();

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          height: 100,
          child: DpadRegion(
            horizontalEdge: DpadEdgeBehavior.wrap,
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: 40,
              itemBuilder: (context, index) => DpadFocusable(
                focusNode: index == 0 ? first : null,
                autofocus: index == 0,
                effects: const <DpadEffect>[],
                child: SizedBox(width: 100, child: Text('item$index')),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(first.hasPrimaryFocus, isTrue);

      // Walk to the far end of the lazy line.
      for (int i = 0; i < 39; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(controller.offset, greaterThan(2500));
      expect(first.hasPrimaryFocus, isFalse);

      // Wrap: the first items were long evicted from the cache; the wrap
      // must rewind the list and land on the real first item.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(first.hasPrimaryFocus, isTrue,
          reason: 'wrap must return to the true first item of the line');
      expect(controller.offset, lessThan(100));
    });

    testWidgets('RTL wrap rewinds to the reading start', (tester) async {
      final controller = ScrollController();
      final first = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: 100,
            child: DpadRegion(
              horizontalEdge: DpadEdgeBehavior.wrap,
              child: ListView.builder(
                controller: controller,
                scrollDirection: Axis.horizontal,
                itemCount: 40,
                itemBuilder: (context, index) => DpadFocusable(
                  focusNode: index == 0 ? first : null,
                  autofocus: index == 0,
                  effects: const <DpadEffect>[],
                  child: SizedBox(width: 100, child: Text('item$index')),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(first.hasPrimaryFocus, isTrue);

      // Reading order runs right-to-left: left walks the line.
      for (int i = 0; i < 39; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
      }
      expect(first.hasPrimaryFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(first.hasPrimaryFocus, isTrue,
          reason: 'RTL wrap must rewind to the rightmost (reading start)');
    });
  });

  group('regions', () {
    testWidgets(
        'focus returns to the remembered item when re-entering '
        'a region', (tester) async {
      final s1 = FocusNode();
      final s2 = FocusNode();
      final c1 = FocusNode();
      final c2 = FocusNode();
      final c3 = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(
              debugLabel: 'sidebar',
              child: Column(children: [item('s1', s1), item('s2', s2)]),
            ),
            const SizedBox(width: 40),
            DpadRegion(
              debugLabel: 'content',
              child: Column(
                children: [
                  item('c1', c1),
                  item('c2', c2, autofocus: true),
                  item('c3', c3),
                ],
              ),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      expect(c2.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(s2.hasPrimaryFocus, isTrue,
          reason: 'left from c2 lands on the in-beam sidebar item because '
              'the sidebar holds no memory yet');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c2.hasPrimaryFocus, isTrue,
          reason: 're-entering the content region must restore c2');

      // The sidebar now remembers s2; entering it again must restore that
      // even from a different row.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(c3.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(s2.hasPrimaryFocus, isTrue,
          reason: 'sidebar restores its own memory');
    });

    testWidgets('DpadEnterBehavior.entry always lands on the entry item',
        (tester) async {
      final s1 = FocusNode();
      final c1 = FocusNode();
      final c2 = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(
              child: Column(children: [item('s1', s1)]),
            ),
            DpadRegion(
              enter: DpadEnterBehavior.entry,
              child: Column(
                children: [
                  item('c1', c1, entry: true),
                  item('c2', c2),
                ],
              ),
            ),
          ],
        ),
      ));
      // Build memory inside content, then leave and re-enter.
      c2.requestFocus();
      await tester.pump();
      s1.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c1.hasPrimaryFocus, isTrue,
          reason: 'entry behavior ignores memory and picks the entry item');
    });

    testWidgets('DpadEnterBehavior.nearest picks the geometric target',
        (tester) async {
      final s2 = FocusNode();
      final c1 = FocusNode();
      final c2 = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(
              child: Column(
                children: [item('s1', FocusNode()), item('s2', s2)],
              ),
            ),
            DpadRegion(
              enter: DpadEnterBehavior.nearest,
              child: Column(children: [item('c1', c1), item('c2', c2)]),
            ),
          ],
        ),
      ));
      // Remember c1, then approach from s2 (in beam with c2).
      c1.requestFocus();
      await tester.pump();
      s2.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c2.hasPrimaryFocus, isTrue);
    });

    testWidgets('wrap edge cycles within the region', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final c = FocusNode();

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.wrap,
          child: Row(
            children: [item('a', a), item('b', b), item('c', c)],
          ),
        ),
      ));
      c.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue, reason: 'right past c wraps to a');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue, reason: 'left past a wraps to c');
    });

    testWidgets('stop edge consumes the key and reports onEdge',
        (tester) async {
      final outside = FocusNode();
      final a = FocusNode();
      final b = FocusNode();
      final edges = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        home: Column(
          children: [
            item('outside', outside),
            DpadRegion(
              verticalEdge: DpadEdgeBehavior.stop,
              onEdge: edges.add,
              child: Column(children: [item('a', a), item('b', b)]),
            ),
          ],
        ),
      ));
      a.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'focus must not escape a stop edge');
      expect(outside.hasPrimaryFocus, isFalse);
      expect(edges, [TraversalDirection.up]);
    });

    testWidgets('leave edge (default) crosses into the neighbor region',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            DpadRegion(child: item('a', a)),
            DpadRegion(child: item('b', b)),
          ],
        ),
      ));
      a.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue);
    });

    testWidgets('per-direction edges: right stops while left still leaves',
        (tester) async {
      final rail = FocusNode();
      final a = FocusNode();
      final c = FocusNode();
      final edges = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(child: item('rail', rail)),
            DpadRegion(
              horizontalEdge: DpadEdgeBehavior.stop,
              leftEdge: DpadEdgeBehavior.leave,
              onEdge: edges.add,
              child: Row(
                children: [
                  item('a', a),
                  item('b', FocusNode()),
                  item('c', c),
                ],
              ),
            ),
          ],
        ),
      ));
      c.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue,
          reason: 'rightEdge override keeps the axis stop');
      expect(edges, [TraversalDirection.right]);

      a.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(rail.hasPrimaryFocus, isTrue,
          reason: 'leftEdge override lets focus reach the rail');
    });

    testWidgets('lineWrap edge steps between grid rows', (tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(9, (_) => FocusNode());
      final edges = <TraversalDirection>[];
      Widget row(int r) => Row(
            children: <Widget>[
              for (int c = 0; c < 3; c++)
                item('i${r * 3 + c}', nodes[r * 3 + c]),
            ],
          );

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.lineWrap,
          onEdge: edges.add,
          child: Column(children: <Widget>[row(0), row(1), row(2)]),
        ),
      ));
      nodes[2].requestFocus(); // row 0, col 2 — end of the first row
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue,
          reason: 'right past a row steps to the first cell of the row below');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(nodes[2].hasPrimaryFocus, isTrue,
          reason:
              'left past a row steps back to the last cell of the row above');

      nodes[8].requestFocus(); // row 2, col 2 — last cell of the grid
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[8].hasPrimaryFocus, isTrue,
          reason: 'no line below the last row: the key is consumed');
      expect(edges, [TraversalDirection.right]);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(nodes[7].hasPrimaryFocus, isTrue,
          reason: 'line wrap never blocks movement inside a row');
      expect(edges, [TraversalDirection.right],
          reason: 'in-row movement must not report an edge');

      nodes[0].requestFocus(); // row 0, col 0 — start of the first row
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(nodes[0].hasPrimaryFocus, isTrue,
          reason: 'no line above the first row: left is consumed');
      expect(edges, [TraversalDirection.right, TraversalDirection.left]);
    });

    testWidgets('lineWrap edge steps between grid columns vertically',
        (tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(6, (_) => FocusNode());
      final edges = <TraversalDirection>[];
      Widget col(int c) => Column(
            children: <Widget>[
              for (int r = 0; r < 3; r++)
                item('i${r * 2 + c}', nodes[r * 2 + c]),
            ],
          );

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          verticalEdge: DpadEdgeBehavior.lineWrap,
          onEdge: edges.add,
          child: Row(children: <Widget>[col(0), col(1)]),
        ),
      ));
      nodes[4].requestFocus(); // column 0, bottom
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue,
          reason: 'down past a column steps to the top cell of the next one');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(nodes[4].hasPrimaryFocus, isTrue,
          reason: 'up past a column steps to the bottom cell of the previous');

      nodes[0].requestFocus(); // column 0, top — start of the grid
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(nodes[0].hasPrimaryFocus, isTrue,
          reason: 'no column before the first: up is consumed');
      expect(edges, [TraversalDirection.up]);

      nodes[5].requestFocus(); // last column, bottom — end of the grid
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[5].hasPrimaryFocus, isTrue,
          reason: 'no column after the last: down is consumed');
      expect(edges, [TraversalDirection.up, TraversalDirection.down]);
    });

    testWidgets('lineWrap follows the reading order in RTL grids',
        (tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(9, (_) => FocusNode());
      final edges = <TraversalDirection>[];
      Widget row(int r) => Row(
            children: <Widget>[
              for (int c = 0; c < 3; c++)
                item('i${r * 3 + c}', nodes[r * 3 + c]),
            ],
          );

      await tester.pumpWidget(tvApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: DpadRegion(
            horizontalEdge: DpadEdgeBehavior.lineWrap,
            onEdge: edges.add,
            // In RTL the first child of each Row sits rightmost, so the
            // reading order of a row is i0 (right) … i2 (left).
            child: Column(children: <Widget>[row(0), row(1), row(2)]),
          ),
        ),
      ));
      nodes[2].requestFocus(); // row 0, col 2 — reading end of the first row
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue,
          reason: 'left past a row steps to the row below in RTL');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[2].hasPrimaryFocus, isTrue,
          reason: 'right past a row steps back up in RTL');

      nodes[0].requestFocus(); // row 0, col 0 — reading start of the grid
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[0].hasPrimaryFocus, isTrue,
          reason: 'no line above the first row: the key is consumed');
      expect(edges, [TraversalDirection.right]);
    });

    testWidgets('lineWrap scrolls to reveal the next unbuilt grid row',
        (tester) async {
      final controller = ScrollController();
      final row1End = FocusNode(); // index 5: last cell of the last built row
      final row2First = FocusNode(); // index 6: first cell of the unbuilt row

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          width: 180,
          height: 120, // exactly two 60px rows — row 2 is not built
          child: DpadRegion(
            horizontalEdge: DpadEdgeBehavior.lineWrap,
            child: GridView.builder(
              controller: controller,
              // scrollCacheExtent (the 3.41+ rename) does not exist on 3.19.
              // ignore: deprecated_member_use
              cacheExtent: 0,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
              ),
              itemCount: 30,
              itemBuilder: (context, index) => DpadFocusable(
                focusNode: index == 5
                    ? row1End
                    : index == 6
                        ? row2First
                        : null,
                autofocus: index == 5,
                effects: const <DpadEffect>[],
                child: Text('item$index'),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(row1End.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0),
          reason: 'the grid must scroll down to build the next row');
      expect(row2First.hasPrimaryFocus, isTrue,
          reason:
              'right past the built rows lands on the next row\'s first cell');
    });

    testWidgets('upEdge and downEdge override the vertical axis',
        (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final edges = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          verticalEdge: DpadEdgeBehavior.leave,
          upEdge: DpadEdgeBehavior.stop,
          downEdge: DpadEdgeBehavior.stop,
          onEdge: edges.add,
          child: Column(children: [item('a', a), item('b', b)]),
        ),
      ));
      a.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'upEdge override keeps the top boundary sealed');
      expect(edges, [TraversalDirection.up]);

      b.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'downEdge override keeps the bottom boundary sealed');
      expect(edges, [TraversalDirection.up, TraversalDirection.down]);
    });

    testWidgets('per-direction wrap: left wraps while right leaves',
        (tester) async {
      final outside = FocusNode();
      final a = FocusNode();
      final c = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(
              leftEdge: DpadEdgeBehavior.wrap,
              child: Row(
                children: [
                  item('a', a),
                  item('b', FocusNode()),
                  item('c', c),
                ],
              ),
            ),
            item('outside', outside),
          ],
        ),
      ));
      a.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue,
          reason: 'leftEdge wraps back to the row end');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(outside.hasPrimaryFocus, isTrue,
          reason: 'right keeps the axis default (leave)');
    });

    testWidgets(
        'per-direction lineWrap: right steps lines while left exits to the rail',
        (tester) async {
      final rail = FocusNode();
      final List<FocusNode> nodes =
          List<FocusNode>.generate(6, (_) => FocusNode());
      final edges = <TraversalDirection>[];
      Widget row(int r) => Row(
            children: <Widget>[
              for (int c = 0; c < 3; c++)
                item('i${r * 3 + c}', nodes[r * 3 + c]),
            ],
          );

      await tester.pumpWidget(tvApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(child: item('rail', rail)),
            DpadRegion(
              // The issue #8 layout: line-wrap forward, reach the rail backward.
              rightEdge: DpadEdgeBehavior.lineWrap,
              onEdge: edges.add,
              child: Column(children: <Widget>[row(0), row(1)]),
            ),
          ],
        ),
      ));
      nodes[2].requestFocus(); // row 0, col 2 — end of the first row
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue,
          reason: 'rightEdge line wrap steps to the row below');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(rail.hasPrimaryFocus, isTrue,
          reason: 'left keeps the axis default and reaches the rail');

      nodes[5].requestFocus(); // row 1, col 2 — end of the last row
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[5].hasPrimaryFocus, isTrue,
          reason: 'no line below the last row: the key is consumed');
      expect(edges, [TraversalDirection.right]);
    });

    testWidgets('lineWrap on ragged grids reaches the shorter last row',
        (tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(8, (_) => FocusNode());
      final edges = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.lineWrap,
          onEdge: edges.add,
          child: Column(
            children: <Widget>[
              Row(children: <Widget>[
                item('0', nodes[0]),
                item('1', nodes[1]),
                item('2', nodes[2])
              ]),
              Row(children: <Widget>[
                item('3', nodes[3]),
                item('4', nodes[4]),
                item('5', nodes[5])
              ]),
              // A ragged final row with only two cells.
              Row(children: <Widget>[item('6', nodes[6]), item('7', nodes[7])]),
            ],
          ),
        ),
      ));
      nodes[2].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue);

      nodes[5].requestFocus(); // end of the second row
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[6].hasPrimaryFocus, isTrue,
          reason: 'the ragged last row is still reachable');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[7].hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[7].hasPrimaryFocus, isTrue,
          reason: 'past the ragged last row: the key is consumed');
      expect(edges, [TraversalDirection.right]);
    });

    testWidgets('lineWrap skips disabled cells when entering a line',
        (tester) async {
      final b = FocusNode();
      final d = FocusNode();

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.lineWrap,
          child: Column(
            children: <Widget>[
              Row(children: <Widget>[item('a', FocusNode()), item('b', b)]),
              Row(children: <Widget>[
                item('c', FocusNode(), enabled: false),
                item('d', d),
              ]),
            ],
          ),
        ),
      ));
      b.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(d.hasPrimaryFocus, isTrue,
          reason: 'the wrap target must be focusable');
    });

    testWidgets('lineWrap walks nested scrollables with lazy rows',
        (tester) async {
      final controller = ScrollController();
      final List<FocusNode> nodes =
          List<FocusNode>.generate(90, (_) => FocusNode());

      Widget row(int r) => SizedBox(
            height: 60,
            // An inner horizontal scrollable that cannot scroll: the
            // reveal search must skip it and scroll the outer vertical list.
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                for (int c = 0; c < 3; c++)
                  item('i${r * 3 + c}', nodes[r * 3 + c]),
              ],
            ),
          );

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          height: 180, // three rows visible; the rest is built lazily
          child: DpadRegion(
            horizontalEdge: DpadEdgeBehavior.lineWrap,
            child: ListView.builder(
              controller: controller,
              // scrollCacheExtent (the 3.41+ rename) does not exist on 3.19.
              // ignore: deprecated_member_use
              cacheExtent: 0,
              itemCount: 30,
              itemBuilder: (context, index) => row(index),
            ),
          ),
        ),
      ));
      nodes[2].requestFocus(); // row 0, col 2
      await tester.pump();

      for (int r = 1; r <= 5; r++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(nodes[r * 3].hasPrimaryFocus, isTrue,
            reason: 'right past row ${r - 1} must land on row $r, cell 0');
        // Advance to the row end so the next press wraps again.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(controller.offset, greaterThan(0),
          reason: 'rows beyond the viewport must have been revealed');
    });

    testWidgets('lineWrap handles uneven row heights', (tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(6, (_) => FocusNode());

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.lineWrap,
          child: Column(
            children: <Widget>[
              Row(children: <Widget>[
                item('0', nodes[0]),
                item('1', nodes[1]),
                item('2', nodes[2])
              ]),
              // A taller middle row must not confuse line membership.
              Row(children: <Widget>[
                item('3', nodes[3], size: 80),
                item('4', nodes[4], size: 80),
                item('5', nodes[5], size: 80),
              ]),
            ],
          ),
        ),
      ));
      nodes[2].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue,
          reason: 'uneven heights must still find the row below');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(nodes[2].hasPrimaryFocus, isTrue,
          reason: 'and step back onto the shorter row');
    });

    testWidgets('lineWrap combines with stop on the other axis',
        (tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(9, (_) => FocusNode());
      final edges = <TraversalDirection>[];
      Widget row(int r) => Row(
            children: <Widget>[
              for (int c = 0; c < 3; c++)
                item('i${r * 3 + c}', nodes[r * 3 + c]),
            ],
          );

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.lineWrap,
          verticalEdge: DpadEdgeBehavior.stop,
          onEdge: edges.add,
          child: Column(children: <Widget>[row(0), row(1), row(2)]),
        ),
      ));
      nodes[2].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue,
          reason: 'line wrap still steps rows on the horizontal axis');

      nodes[0].requestFocus(); // top-left corner
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(nodes[0].hasPrimaryFocus, isTrue,
          reason: 'the vertical axis stays sealed by stop');
      expect(edges, [TraversalDirection.up]);
    });

    testWidgets('lineWrap never scrolls content outside its region',
        (tester) async {
      final controller = ScrollController();
      final a = FocusNode();
      final b = FocusNode();
      final edges = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          height: 120,
          child: ListView(
            controller: controller,
            children: <Widget>[
              SizedBox(
                height: 120,
                child: DpadRegion(
                  horizontalEdge: DpadEdgeBehavior.lineWrap,
                  onEdge: edges.add,
                  child: Row(children: <Widget>[item('a', a), item('b', b)]),
                ),
              ),
              item('below', FocusNode()),
              item('further', FocusNode()),
            ],
          ),
        ),
      ));
      b.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(b.hasPrimaryFocus, isTrue,
          reason: 'a single-line region has nothing to line wrap to');
      expect(edges, [TraversalDirection.right]);
      expect(controller.offset, 0.0,
          reason: 'the reveal search must not leak past the region into '
              'the page scrollable');
    });

    testWidgets('lineWrap follows the reading order in RTL columns',
        (tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(6, (_) => FocusNode());
      Widget col(int c) => Column(
            children: <Widget>[
              for (int r = 0; r < 3; r++)
                item('i${r * 2 + c}', nodes[r * 2 + c]),
            ],
          );

      await tester.pumpWidget(tvApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: DpadRegion(
            verticalEdge: DpadEdgeBehavior.lineWrap,
            // In RTL, column 0 (the first child) is rightmost — the reading
            // start — so `down` must step to the column on the *left*.
            child: Row(children: <Widget>[col(0), col(1)]),
          ),
        ),
      ));
      nodes[4].requestFocus(); // column 0, bottom
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue,
          reason: 'down in RTL steps to the top of the left-hand column');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(nodes[4].hasPrimaryFocus, isTrue,
          reason:
              'up in RTL steps back to the bottom of the right-hand column');
    });

    testWidgets('wrap in RTL grids stays physical', (tester) async {
      final a = FocusNode();
      final c = FocusNode();

      await tester.pumpWidget(tvApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: DpadRegion(
            horizontalEdge: DpadEdgeBehavior.wrap,
            // In RTL the first child sits rightmost: the row reads c→a.
            child: Row(children: <Widget>[
              item('a', a),
              item('b', FocusNode()),
              item('c', c)
            ]),
          ),
        ),
      ));
      c.requestFocus(); // physically leftmost = reading end
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(a.hasPrimaryFocus, isTrue,
          reason: 'left wraps back to the physical row start (rightmost)');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(c.hasPrimaryFocus, isTrue,
          reason: 'right wraps back to the physical row end (leftmost)');
    });

    testWidgets('lineWrap walks deep into a lazy GridView', (tester) async {
      final controller = ScrollController();
      final List<FocusNode> nodes =
          List<FocusNode>.generate(90, (_) => FocusNode());

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          width: 180,
          height: 180, // three 60px rows visible
          child: DpadRegion(
            horizontalEdge: DpadEdgeBehavior.lineWrap,
            child: GridView.builder(
              controller: controller,
              // scrollCacheExtent (the 3.41+ rename) does not exist on 3.19.
              // ignore: deprecated_member_use
              cacheExtent: 0,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
              ),
              itemCount: 90,
              itemBuilder: (context, index) => DpadFocusable(
                focusNode: nodes[index],
                autofocus: index == 2,
                effects: const <DpadEffect>[],
                child: Text('item$index'),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(nodes[2].hasPrimaryFocus, isTrue);

      for (int r = 1; r <= 4; r++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(nodes[r * 3].hasPrimaryFocus, isTrue,
            reason: 'right must line wrap onto row $r, cell 0');
        // Advance to the row end so the next press wraps again.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(controller.offset, greaterThan(0));
    });

    testWidgets('diagonal candidates win when no line wrap is configured',
        (tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(6, (_) => FocusNode());

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          child: Column(
            children: <Widget>[
              Row(children: <Widget>[
                item('0', nodes[0]),
                item('1', nodes[1]),
                item('2', nodes[2])
              ]),
              // The last cell of the row below is shifted right, making it
              // an out-of-beam — but valid — right candidate for cell 2.
              Row(children: <Widget>[
                item('3', nodes[3]),
                item('4', nodes[4]),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: item('5', nodes[5]),
                ),
              ]),
            ],
          ),
        ),
      ));
      nodes[2].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[5].hasPrimaryFocus, isTrue,
          reason: 'without line wrap, the closest diagonal candidate wins '
              '(locks the baseline that lineWrap overrides)');
    });

    testWidgets('lineWrap prefers the line step over closer diagonals',
        (tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(6, (_) => FocusNode());

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.lineWrap,
          child: Column(
            children: <Widget>[
              Row(children: <Widget>[
                item('0', nodes[0]),
                item('1', nodes[1]),
                item('2', nodes[2])
              ]),
              Row(children: <Widget>[
                item('3', nodes[3]),
                item('4', nodes[4]),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: item('5', nodes[5]),
                ),
              ]),
            ],
          ),
        ),
      ));
      nodes[2].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue,
          reason: 'the typewriter contract: once the line runs out, the '
              'line step wins — never the closer diagonal cell 5');
    });

    testWidgets('wrap with nothing to wrap to reports onEdge', (tester) async {
      final only = FocusNode();
      final edges = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.wrap,
          onEdge: edges.add,
          child: item('only', only, autofocus: true),
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(only.hasPrimaryFocus, isTrue);
      expect(edges, [TraversalDirection.right]);
    });

    testWidgets('lineWrap with a single line reports onEdge', (tester) async {
      final only = FocusNode();
      final edges = <TraversalDirection>[];

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.lineWrap,
          onEdge: edges.add,
          child: item('only', only, autofocus: true),
        ),
      ));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(only.hasPrimaryFocus, isTrue);
      expect(edges, [TraversalDirection.right]);
    });

    testWidgets('lineWrap scrolls sideways to reveal the next unbuilt column',
        (tester) async {
      final controller = ScrollController();
      final List<FocusNode> nodes =
          List<FocusNode>.generate(18, (_) => FocusNode());

      Widget col(int c) => Column(
            children: <Widget>[
              for (int r = 0; r < 3; r++)
                item('i${c * 3 + r}', nodes[c * 3 + r]),
            ],
          );

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          width: 180, // three 60px columns; the rest is built lazily
          height: 180,
          child: DpadRegion(
            verticalEdge: DpadEdgeBehavior.lineWrap,
            child: ListView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              // scrollCacheExtent (the 3.41+ rename) does not exist on 3.19.
              // ignore: deprecated_member_use
              cacheExtent: 0,
              children: <Widget>[for (int c = 0; c < 6; c++) col(c)],
            ),
          ),
        ),
      ));
      nodes[8].requestFocus(); // column 2, bottom
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0),
          reason: 'the list must scroll right to build the next column');
      expect(nodes[9].hasPrimaryFocus, isTrue,
          reason: 'down past a column lands on the next column\'s top cell');
    });

    testWidgets(
        'lineWrap focuses an off-screen line the cache has already built',
        (tester) async {
      final controller = ScrollController();
      final List<FocusNode> nodes =
          List<FocusNode>.generate(30, (_) => FocusNode());

      Widget row(int r) => Row(
            children: <Widget>[
              for (int c = 0; c < 3; c++)
                item('i${r * 3 + c}', nodes[r * 3 + c]),
            ],
          );

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          height: 180, // rows below are off-screen but built by the cache
          child: DpadRegion(
            horizontalEdge: DpadEdgeBehavior.lineWrap,
            child: ListView.builder(
              controller: controller,
              itemCount: 10,
              itemBuilder: (context, index) => row(index),
            ),
          ),
        ),
      ));
      nodes[8].requestFocus(); // row 2, col 2 — last visible row
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0),
          reason: 'the cached-but-off-screen target must scroll into view');
      expect(nodes[9].hasPrimaryFocus, isTrue,
          reason: 'the wrap target is the cached row below the viewport');
    });

    testWidgets('nested sub-regions are skipped by an outer line wrap',
        (tester) async {
      final List<FocusNode> nodes =
          List<FocusNode>.generate(9, (_) => FocusNode());
      Widget row(int r) => Row(
            children: <Widget>[
              for (int c = 0; c < 3; c++)
                item('i${r * 3 + c}', nodes[r * 3 + c]),
            ],
          );

      await tester.pumpWidget(tvApp(
        home: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.lineWrap,
          child: Column(
            children: <Widget>[
              row(0),
              DpadRegion(child: row(1)), // its own navigation unit
              row(2),
            ],
          ),
        ),
      ));
      nodes[2].requestFocus(); // row 0, col 2
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[6].hasPrimaryFocus, isTrue,
          reason: 'the outer region line-steps over its nested sub-region '
              'to its own next row');
    });

    testWidgets('per-direction leave restores memory when returning',
        (tester) async {
      final rail = FocusNode();
      final List<FocusNode> nodes =
          List<FocusNode>.generate(6, (_) => FocusNode());
      Widget row(int r) => Row(
            children: <Widget>[
              for (int c = 0; c < 3; c++)
                item('i${r * 3 + c}', nodes[r * 3 + c]),
            ],
          );

      await tester.pumpWidget(tvApp(
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DpadRegion(child: item('rail', rail)),
            DpadRegion(
              horizontalEdge: DpadEdgeBehavior.stop,
              leftEdge: DpadEdgeBehavior.leave,
              child: Column(children: <Widget>[row(0), row(1)]),
            ),
          ],
        ),
      ));
      nodes[3].requestFocus(); // row 1, col 0 — at the left boundary
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(rail.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nodes[3].hasPrimaryFocus, isTrue,
          reason: 're-entering restores the remembered row-1 item, not the '
              'geometrically nearest row-0 item');
    });

    testWidgets('lineWrap region restores memory when re-entered vertically',
        (tester) async {
      final above = FocusNode();
      final List<FocusNode> nodes =
          List<FocusNode>.generate(6, (_) => FocusNode());
      Widget row(int r) => Row(
            children: <Widget>[
              for (int c = 0; c < 3; c++)
                item('i${r * 3 + c}', nodes[r * 3 + c]),
            ],
          );

      await tester.pumpWidget(tvApp(
        home: Column(
          children: <Widget>[
            item('above', above),
            DpadRegion(
              horizontalEdge: DpadEdgeBehavior.lineWrap,
              child: Column(children: <Widget>[row(0), row(1)]),
            ),
          ],
        ),
      ));
      nodes[1].requestFocus(); // row 0, col 1
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(above.hasPrimaryFocus, isTrue,
          reason: 'up leaves the grid (default vertical edge)');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue,
          reason: 're-entering restores the line-wrapped position');
    });

    testWidgets('region onFocusChange reports enter and leave', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      final log = <bool>[];

      await tester.pumpWidget(tvApp(
        home: Row(
          children: [
            DpadRegion(
              onFocusChange: log.add,
              child: item('a', a),
            ),
            item('b', b),
          ],
        ),
      ));
      a.requestFocus();
      await tester.pump();
      expect(log, [true]);

      b.requestFocus();
      await tester.pump();
      expect(log, [true, false]);
    });
  });

  group('auto scroll', () {
    testWidgets('focusing an off-screen item scrolls it into view',
        (tester) async {
      final controller = ScrollController();
      final nodes = List<FocusNode>.generate(10, (_) => FocusNode());

      await tester.pumpWidget(tvApp(
        home: SizedBox(
          height: 100,
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < 10; i++) item('$i', nodes[i], size: 100),
              ],
            ),
          ),
        ),
      ));

      nodes[9].requestFocus();
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));

      nodes[0].requestFocus();
      await tester.pumpAndSettle();
      expect(controller.offset, 0);
    });
  });
}
