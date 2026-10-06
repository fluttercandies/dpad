import 'package:dpad/dpad.dart';
import 'package:dpad_example/app_state.dart';
import 'package:dpad_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;

/// The rect of whatever currently holds primary focus, in logical pixels.
Rect focusedRect() {
  final FocusNode node = WidgetsBinding.instance.focusManager.primaryFocus!;
  final RenderObject? renderObject = node.context?.findRenderObject();
  expect(renderObject, isA<RenderBox>(),
      reason: 'a focusable must be laid out');
  final RenderBox box = renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// The [Switch] value of the [DpadFocusable] toggle row titled [title].
bool switchValueFor(WidgetTester tester, String title) {
  Element? row;
  tester.element(find.text(title)).visitAncestorElements((Element ancestor) {
    if (ancestor.widget is DpadFocusable) {
      row = ancestor;
      return false;
    }
    return true;
  });
  expect(row, isNotNull, reason: 'no toggle row for "$title"');
  bool? value;
  void visit(Element element) {
    if (element.widget is Switch) {
      value = (element.widget as Switch).value;
    }
    element.visitChildren(visit);
  }

  row!.visitChildren(visit);
  expect(value, isNotNull, reason: '"$title" row has no switch');
  return value!;
}

void main() {
  setUp(() {
    activeSection.value = 0;
    showFocusInspector.value = false;
    rtlLayout.value = false;
    wasdKeys.value = false;
    dpadEnabled.value = true;
    // Region memory is static and would otherwise leak between tests.
    DpadRegionState.clearPersistentMemory();
  });

  testWidgets('the demo app is fully drivable with a remote', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DpadTvApp());
    await tester.pumpAndSettle();

    // The featured Play button owns the initial focus, so the sidebar is
    // collapsed (its wordmark only shows while focus is inside it).
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('DPAD TV'), findsNothing);

    // Down into the first poster row, right along it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    // Select opens the detail page.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Episodes'), findsOneWidget);

    // Back pops it and focus returns to the poster row.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Episodes'), findsNothing);
    expect(find.text('FEATURED'), findsOneWidget);

    // Two lefts: back to the first poster, then out into the sidebar,
    // which expands the rail. Down switches the section on focus alone.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('DPAD TV'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('DPAD TV'), findsOneWidget);

    // Back on the home screen opens the exit dialog, which traps focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Leave Dpad TV?'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Leave Dpad TV?'), findsNothing);
  });

  testWidgets('settings: disabled rows skip, slider consumes left/right',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DpadTvApp());
    await tester.pumpAndSettle();

    activeSection.value = 3;
    await tester.pumpAndSettle();
    expect(find.text('Playback'), findsOneWidget);

    // Autoplay autofocuses; two downs reach Volume because the disabled
    // "Parental controls" row is skipped.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);

    // Right adjusts the volume instead of moving focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);

    // Bump the volume so we can prove state survives the overlay toggle.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);

    // The focus inspector toggle paints the overlay without resetting any
    // app state (then settles after we switch it back off).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(showFocusInspector.value, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('13'), findsOneWidget,
        reason: 'toggling the inspector must not reset section state');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(showFocusInspector.value, isFalse);
    await tester.pumpAndSettle();
  });

  testWidgets('library: grid line wrap steps rows, rail stays reachable',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DpadTvApp());
    await tester.pumpAndSettle();
    activeSection.value = 1;
    await tester.pumpAndSettle();

    // Focus restoration lands on the grid's first tile (top-left in LTR).
    final Rect start = focusedRect();
    expect(start.top, lessThan(400));

    // Walk right across the whole first row; the press past its end must
    // step to the first tile of the row below (line wrap).
    Rect current = start;
    int presses = 0;
    while (current.top < start.top + 80 && presses < 12) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      current = focusedRect();
      presses++;
    }
    expect(presses, greaterThanOrEqualTo(2), reason: 'a row must be wide');
    expect(current.top, greaterThan(start.top + 80),
        reason: 'the press past the row end steps to the row below');
    expect(current.left, lessThan(200),
        reason: 'the step lands on the first tile of the next row');

    // The per-direction override in action: left at the start of a line
    // exits into the rail instead of wrapping back up.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('DPAD TV'), findsOneWidget,
        reason: 'leftEdge: leave keeps the rail reachable');
  });

  testWidgets('for you: rows wrap at the end, left exits to the rail',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DpadTvApp());
    await tester.pumpAndSettle();

    // Down into "Continue Watching": four posters, all built, no scrolling.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final Rect start = focusedRect();

    // Three rights walk to the row's end; the fourth wraps to the start.
    double furthestLeft = 0;
    for (int i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      furthestLeft = math.max(furthestLeft, focusedRect().left);
    }
    expect(furthestLeft, greaterThan(600),
        reason: 'the walk must have reached the row end');
    expect(focusedRect().left, lessThan(200),
        reason: 'right past the last poster wraps to the first');
    expect(focusedRect().top, start.top,
        reason: 'the wrap stays on the same row');

    // Left from the first poster exits into the rail (per-direction edge).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('DPAD TV'), findsOneWidget);
  });

  testWidgets('RTL: the app mirrors and navigation follows the reading order',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DpadTvApp());
    await tester.pumpAndSettle();

    // Five downs reach the RTL toggle (the disabled parental row is
    // skipped): subtitles, volume, sounds, inspector, RTL.
    activeSection.value = 3;
    await tester.pumpAndSettle();
    for (int i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(rtlLayout.value, isTrue);

    // The rail now sits on the right, so RIGHT crosses into it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('DPAD TV'), findsOneWidget);

    // Back into the content (left, in RTL), then into the mirrored grid:
    // initial focus lands on the top-RIGHT tile, and the rail side of a
    // row is now the RIGHT side.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    DpadRegionState.clearPersistentMemory('library');
    activeSection.value = 1;
    await tester.pumpAndSettle();
    final Rect start = focusedRect();
    expect(start.left, greaterThan(900),
        reason: 'RTL initial focus is the top-right tile');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('DPAD TV'), findsOneWidget,
        reason: 'the mirrored rail is reachable via the right key');
  });

  testWidgets(
      'settings: freezing Dpad.enabled locks navigation until toggled back',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DpadTvApp());
    await tester.pumpAndSettle();
    activeSection.value = 3;
    await tester.pumpAndSettle();

    // Autoplay autofocuses and the disabled parental row is skipped: seven
    // downs reach the last toggle row.
    for (int i = 0; i < 7; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(switchValueFor(tester, 'D-pad enabled (Dpad.enabled)'), isTrue);
    final Rect frozen = focusedRect();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(dpadEnabled.value, isFalse);

    // Frozen: arrows move nothing (the framework's own arrow shortcuts must
    // not leak through either).
    for (final LogicalKeyboardKey key in const [
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowLeft,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(focusedRect().top, frozen.top, reason: '$key must be frozen out');
    }

    // Select still fires on the focused row — the only way back out of a
    // frozen UI.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(dpadEnabled.value, isTrue);

    // Navigation is restored: up reaches the WASD row above.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(focusedRect().top, lessThan(frozen.top));
  });

  testWidgets('settings: WASD movement adds W/A/S/D to the arrows',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DpadTvApp());
    await tester.pumpAndSettle();
    activeSection.value = 3;
    await tester.pumpAndSettle();

    // Six downs reach the WASD row.
    for (int i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(
        switchValueFor(tester, 'WASD movement (custom DpadKeySet)'), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(wasdKeys.value, isTrue);
    final Rect wasdRow = focusedRect();

    // While the remap is live, the physical W key belongs to the d-pad.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pumpAndSettle();
    expect(focusedRect().top, lessThan(wasdRow.top - 10),
        reason: 'W must move focus up');

    // And S moves back down to the toggle row (its section shortcut stands
    // down for the remap's lifetime).
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pumpAndSettle();
    expect((focusedRect().top - wasdRow.top).abs(), lessThan(2),
        reason: 'S must move focus back down');
    expect(activeSection.value, 3, reason: 'S is movement now, not a shortcut');
  });
}
