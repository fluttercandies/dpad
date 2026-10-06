// End-to-end integration tests for the dpad example app, driven through
// Cockpit's in-app executor (`flutter_cockpit_test`) on a real device.
//
// Run (device id from `cockpit target discover`):
//
//     flutter test integration_test/dpad_integration_test.dart -d <deviceId>
//
// The suite walks the real app — no fakes, no golden files. Focus state is
// asserted through FocusManager (debug labels and subtree text), which is
// exactly what the dpad package manipulates.
import 'package:dpad/dpad.dart';
import 'package:dpad_example/app_state.dart';
import 'package:dpad_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cockpit_test/flutter_cockpit_test.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> _railLabels = <String>[
  'For you',
  'Library',
  'Search',
  'Settings'
];
const List<String> _continueWatching = <String>[
  'Neon Tide',
  'Greenline',
  'Half Past Twelve',
  'North of Nowhere',
];

/// Resets every cross-test global (app notifiers, dpad persistent region
/// memory) and returns the real app root. `cockpitTestWidgets` remounts the
/// app for each test; this callback is the whole isolation story.
Widget freshApp() {
  activeSection.value = 0;
  showFocusInspector.value = false;
  clickSounds.value = false;
  rtlLayout.value = false;
  wasdKeys.value = false;
  dpadEnabled.value = true;
  DpadRegionState.clearPersistentMemory();
  return const DpadTvApp();
}

const CockpitTestOptions _options = CockpitTestOptions(
  initialPump: Duration(milliseconds: 400),
);

// ---------------------------------------------------------------------------
// Remote-key and focus helpers
// ---------------------------------------------------------------------------

/// Presses and releases a remote key.
///
/// Dpad handles directional keys through Shortcuts on key-down only, and a
/// `leave` edge with nothing beyond it lets the event go unhandled by
/// design — so both halves allow that instead of failing the command.
Future<void> tapKey(CockpitTester cockpit, String logicalKey) async {
  await cockpit.keyDown(logicalKey, allowUnhandled: true);
  await cockpit.keyUp(logicalKey, allowUnhandled: true);
  await cockpit.waitForUi();
}

/// Same as [tapKey] without the idle wait — for use under the focus
/// inspector, whose repaint ticker keeps a frame permanently scheduled.
Future<void> tapKeyRaw(CockpitTester cockpit, String logicalKey) async {
  await cockpit.keyDown(logicalKey, allowUnhandled: true);
  await cockpit.keyUp(logicalKey, allowUnhandled: true);
  await cockpit.flutter.pump();
}

String? get focusedDebugLabel => FocusManager.instance.primaryFocus?.debugLabel;

Rect focusedRect() {
  final BuildContext? context = FocusManager.instance.primaryFocus?.context;
  expect(context, isNotNull, reason: 'nothing is focused');
  final RenderBox box = context!.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// The non-empty [Text] strings inside the focused widget's subtree — how a
/// test says "focus is on the row that says Volume".
List<String> focusedTexts() {
  final BuildContext? context = FocusManager.instance.primaryFocus?.context;
  if (context == null) {
    return const <String>[];
  }
  final List<String> texts = <String>[];
  void visit(Element element) {
    final Widget widget = element.widget;
    if (widget is Text && widget.data?.isNotEmpty == true) {
      texts.add(widget.data!);
    }
    element.visitChildren(visit);
  }

  visit(context as Element);
  return texts;
}

void expectFocusedText(String text) {
  expect(
    focusedTexts(),
    contains(text),
    reason: 'focus was on ${focusedDebugLabel ?? 'nothing'} '
        '(${focusedTexts().join(' | ')})',
  );
}

bool get focusInsideEditable {
  final BuildContext? context = FocusManager.instance.primaryFocus?.context;
  if (context == null) {
    return false;
  }
  return context.widget is EditableText ||
      context.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// The [Switch] value of the [DpadFocusable] toggle row titled [title].
bool toggleValue(CockpitTester cockpit, String title) {
  Element? row;
  cockpit.flutter
      .element(find.text(title))
      .visitAncestorElements((Element ancestor) {
    if (ancestor.widget is DpadFocusable) {
      row = ancestor;
      return false;
    }
    return true;
  });
  expect(row, isNotNull, reason: 'no toggle row for "$title"');
  final Element toggleRow = row!;
  bool? value;
  void visit(Element element) {
    if (element.widget is Switch) {
      value = (element.widget as Switch).value;
    }
    element.visitChildren(visit);
  }

  toggleRow.visitChildren(visit);
  expect(value, isNotNull, reason: '"$title" row has no switch');
  return value!;
}

/// Presses [logicalKey] until [done] holds after a press (or [maxPresses] is
/// hit). Returns the number of presses used; callers assert on `done()`.
Future<int> walkUntil(
  CockpitTester cockpit,
  String logicalKey,
  bool Function() done, {
  int maxPresses = 12,
}) async {
  int used = 0;
  while (!done() && used < maxPresses) {
    await tapKey(cockpit, logicalKey);
    used++;
  }
  return used;
}

/// Walks the navigation rail down/up to [label], assuming rail focus.
Future<void> focusRailItem(CockpitTester cockpit, String label) async {
  final String want = 'sidebar:$label';
  final int? current = indexOfLabel(focusedDebugLabel);
  final bool downward = current == null || current < _railLabels.indexOf(label);
  final String key = downward ? 'ArrowDown' : 'ArrowUp';
  for (int i = 0; i < _railLabels.length && focusedDebugLabel != want; i++) {
    await tapKey(cockpit, key);
  }
  expect(focusedDebugLabel, want);
}

int? indexOfLabel(String? debugLabel) {
  if (debugLabel == null || !debugLabel.startsWith('sidebar:')) {
    return null;
  }
  return _railLabels.indexOf(debugLabel.substring(8));
}

/// Enters the content area from the rail: RIGHT in LTR, LEFT in RTL.
Future<void> enterContent(CockpitTester cockpit) =>
    tapKey(cockpit, rtlLayout.value ? 'ArrowLeft' : 'ArrowRight');

/// Leaves the content area to the rail.
Future<void> leaveToRail(CockpitTester cockpit) =>
    tapKey(cockpit, rtlLayout.value ? 'ArrowRight' : 'ArrowLeft');

// ---------------------------------------------------------------------------
// Boot and the navigation rail
// ---------------------------------------------------------------------------

void main() {
  cockpitTestWidgets(
    'boots onto the autofocus + entry banner action with the rail collapsed',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await cockpit.expectVisible('FEATURED');
      expectFocusedText('Play');
      expect(
        focusedTexts(),
        isNot(contains('More info')),
        reason: 'entry mark should win over plain geometry',
      );
      // The rail only expands while focus is inside it.
      expect(cockpit.flutter.widgetList(find.text('DPAD TV')), isEmpty);
    },
  );

  cockpitTestWidgets(
    'rail: stop edges, live section switching, expansion, leave into content',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await tapKey(cockpit, 'ArrowLeft');
      expect(focusedDebugLabel, 'sidebar:For you');
      // onFocusChange expanded the rail: the wordmark is painted.
      expect(cockpit.flutter.widgetList(find.text('DPAD TV')), isNotEmpty);

      // Browsing the rail switches sections live.
      await focusRailItem(cockpit, 'Settings');
      await cockpit.expectVisible('Playback');

      // verticalEdge: stop — down at the bottom stays put.
      await tapKey(cockpit, 'ArrowDown');
      expect(focusedDebugLabel, 'sidebar:Settings');

      await focusRailItem(cockpit, 'For you');
      await cockpit.expectVisible('FEATURED');

      // ...and up at the top stays put too.
      await tapKey(cockpit, 'ArrowUp');
      expect(focusedDebugLabel, 'sidebar:For you');

      // Right leaves the rail; the banner region remembers Play.
      await tapKey(cockpit, 'ArrowRight');
      expectFocusedText('Play');
      expect(cockpit.flutter.widgetList(find.text('DPAD TV')), isEmpty);
    },
  );

  // -------------------------------------------------------------------------
  // For you: poster rows
  // -------------------------------------------------------------------------

  cockpitTestWidgets(
    'poster row: right wraps, left leaves (per-direction), memory restores',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await tapKey(cockpit, 'ArrowDown');
      expect(focusedDebugLabel, 'poster:Neon Tide');

      // Continue Watching renders playback progress on its posters.
      expect(
        cockpit.flutter.widgetList(find.byType(LinearProgressIndicator)),
        isNotEmpty,
        reason: 'progress bars should be painted on the row',
      );

      // Lazy horizontal reveal: walk to the last of the four posters.
      final int steps = await walkUntil(
        cockpit,
        'ArrowRight',
        () => focusedDebugLabel == 'poster:North of Nowhere',
        maxPresses: 8,
      );
      expect(steps, greaterThan(0), reason: 'never reached the row end');

      // horizontalEdge: wrap — right at the end comes back to the start.
      await tapKey(cockpit, 'ArrowRight');
      expect(focusedDebugLabel, 'poster:Neon Tide');

      // leftEdge: leave — the per-direction override opens the rail side.
      await tapKey(cockpit, 'ArrowLeft');
      expect(focusedDebugLabel, 'sidebar:For you');

      // Re-entering from the rail's top item lands on the nearest thing —
      // the banner Play button, not the poster row.
      await tapKey(cockpit, 'ArrowRight');
      expectFocusedText('Play');

      // Down from the banner re-enters the poster row, whose memoryKey
      // still remembers the wrapped-around poster.
      await tapKey(cockpit, 'ArrowDown');
      expect(focusedDebugLabel, 'poster:Neon Tide');

      // Row-to-row memory: down to Trending, up returns to the same poster.
      await tapKey(cockpit, 'ArrowDown');
      expect(focusedDebugLabel, 'poster:Ash & Ember');
      await tapKey(cockpit, 'ArrowUp');
      expect(focusedDebugLabel, 'poster:Neon Tide');
    },
  );

  // -------------------------------------------------------------------------
  // Library: the lineWrap grid
  // -------------------------------------------------------------------------

  cockpitTestWidgets(
    'library grid: typewriter line wrap, leave side, deep lazy scroll',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await tapKey(cockpit, 'ArrowLeft');
      await focusRailItem(cockpit, 'Library');
      await enterContent(cockpit);

      // Entry lands on the geometrically nearest cell — capture it rather
      // than assume the top-left corner.
      final Rect first = focusedRect();
      expect(focusedDebugLabel, startsWith('poster:'));

      // lineWrap: right past the row end steps DOWN to the first cell of
      // the next line — the typewriter contract, proven by geometry.
      final int steps = await walkUntil(
        cockpit,
        'ArrowRight',
        () => focusedRect().top > first.top + 20,
        maxPresses: 10,
      );
      expect(steps, greaterThan(0), reason: 'never stepped to the next line');
      final Rect second = focusedRect();
      expect(
        second.left,
        lessThanOrEqualTo(first.left + 2),
        reason: 'wrap must land on the FIRST cell of the next line',
      );

      // The proof that we really sit on the line's first cell: only there
      // does the per-direction leftEdge: leave open the rail side.
      await tapKey(cockpit, 'ArrowLeft');
      expect(focusedDebugLabel, 'sidebar:Library');

      // Re-entry restores the remembered cell, wherever the grid scrolled.
      await enterContent(cockpit);
      expect((focusedRect().left - second.left).abs(), lessThan(2));
      expect((focusedRect().top - second.top).abs(), lessThan(2));

      // Vertical lazy reveal: walk to the bottom of the 24-tile grid; focus
      // must stay on screen the whole way down.
      for (int i = 0; i < 16; i++) {
        await tapKey(cockpit, 'ArrowDown');
      }
      final double windowHeight = cockpit.flutter.view.physicalSize.height /
          cockpit.flutter.view.devicePixelRatio;
      expect(focusedRect().bottom, lessThanOrEqualTo(windowHeight));
      expect(focusedRect().top, greaterThanOrEqualTo(0));
      expect(
        focusedRect().top,
        greaterThan(first.top),
        reason: 'should have descended into the grid',
      );
    },
  );

  // -------------------------------------------------------------------------
  // Search: text input coexistence
  // -------------------------------------------------------------------------

  cockpitTestWidgets(
    'search: field entry, suspended shortcuts, live filtering, exit into '
    'results',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await tapKey(cockpit, 'ArrowLeft');
      await focusRailItem(cockpit, 'Search');
      await enterContent(cockpit);

      // Entry lands on the nearest grid card; walk up into the field.
      await walkUntil(
        cockpit,
        'ArrowUp',
        () => focusInsideEditable,
        maxPresses: 3,
      );
      expect(focusInsideEditable, isTrue);

      await cockpit.type('neon', into: 'Search titles…');
      await cockpit.waitForUi();
      await cockpit.expectVisible('1 title');
      await cockpit.expectVisible('Neon Tide');

      // App shortcuts stand down while editing: 'L' neither jumps to the
      // Library section nor disturbs the query.
      await tapKey(cockpit, 'KeyL');
      await cockpit.expectVisible('Search titles…');
      await cockpit.expectVisible('1 title');

      // Down leaves the field into the results — a remote user is never
      // trapped in an editable. (Caret-precision keys belong to the
      // platform IME on desktop and cannot be synthesized in this
      // harness; the caret-boundary exit contract is unit-tested in the
      // dpad package instead.)
      await tapKey(cockpit, 'ArrowDown');
      expect(focusedDebugLabel, 'poster:Neon Tide');

      // Up returns to the field, query intact.
      await tapKey(cockpit, 'ArrowUp');
      expect(focusInsideEditable, isTrue);

      // A fresh query rebuilds the grid through the text-input channel:
      // empty lists every title, 'the' narrows to eleven.
      await cockpit.flutter.enterText(find.byType(TextField), '');
      await cockpit.waitForUi();
      await cockpit.expectVisible('40 titles');
      await cockpit.flutter.enterText(find.byType(TextField), 'the');
      await cockpit.waitForUi();
      await cockpit.expectVisible('11 titles');
      await tapKey(cockpit, 'ArrowDown');
      expect(focusedDebugLabel, 'poster:The Long Orbit');
    },
  );

  // -------------------------------------------------------------------------
  // Select / long-select / route round-trip
  // -------------------------------------------------------------------------

  cockpitTestWidgets(
    'select pushes the detail page; back pops and restores focus',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await tapKey(cockpit, 'ArrowDown');
      expect(focusedDebugLabel, 'poster:Neon Tide');

      await tapKey(cockpit, 'Enter');
      await cockpit.expectVisible('Episodes');
      expectFocusedText('Play'); // entry + autofocus on the action row

      // Select on the detail action shows a snackbar toast.
      await tapKey(cockpit, 'Enter');
      await cockpit.expectVisible('Playing Neon Tide');

      await tapKey(cockpit, 'Escape');
      await cockpit.waitFor('FEATURED');
      expect(
        focusedDebugLabel,
        'poster:Neon Tide',
        reason: 'focus must return to the poster that opened the route',
      );
    },
  );

  cockpitTestWidgets(
    'holding select opens the context sheet and returns focus on close',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await tapKey(cockpit, 'ArrowDown');
      expect(focusedDebugLabel, 'poster:Neon Tide');

      // Hold the select key past the 500ms long-select threshold.
      await cockpit.keyDown('Enter', allowUnhandled: true);
      await cockpit.flutter.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 900)),
      );
      await cockpit.keyUp('Enter', allowUnhandled: true);
      await cockpit.waitForUi();

      await cockpit.expectVisible('Play from beginning');
      expectFocusedText('Play from beginning'); // sheet traps focus

      await tapKey(cockpit, 'Escape');
      await cockpit.waitFor('Play from beginning', absent: true);
      expect(focusedDebugLabel, 'poster:Neon Tide');
    },
  );

  cockpitTestWidgets(
    'detail page: episodes rail wraps around after a full lap',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await tapKey(cockpit, 'ArrowDown');
      await tapKey(cockpit, 'Enter');
      await cockpit.expectVisible('Episodes');

      await tapKey(cockpit, 'ArrowDown');
      expectFocusedText('Episode 1');

      // Eight cards in a wrapping lazy rail: a full lap lands back on 1.
      for (int i = 0; i < 8; i++) {
        await tapKey(cockpit, 'ArrowRight');
        expect(
          focusedTexts().any((t) => t.startsWith('Episode ')),
          isTrue,
          reason: 'press ${i + 1} left the episode rail',
        );
      }
      expectFocusedText('Episode 1');

      await tapKey(cockpit, 'Escape');
      expect(focusedDebugLabel, 'poster:Neon Tide');
    },
  );

  // -------------------------------------------------------------------------
  // Dialogs
  // -------------------------------------------------------------------------

  cockpitTestWidgets(
    'dialogs trap focus: exit confirmation and the help dialog',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      // Back on the home route asks before leaving.
      await tapKey(cockpit, 'Escape');
      await cockpit.expectVisible('Leave Dpad TV?');
      expectFocusedText('Stay');

      await tapKey(cockpit, 'ArrowRight');
      expectFocusedText('Exit');

      // Nothing above or below a dialog action row: arrows stay put.
      await tapKey(cockpit, 'ArrowUp');
      expectFocusedText('Exit');
      await tapKey(cockpit, 'ArrowDown');
      expectFocusedText('Exit');

      await tapKey(cockpit, 'ArrowLeft');
      expectFocusedText('Stay');

      // Back pops the dialog itself and focus returns home.
      await tapKey(cockpit, 'Escape');
      await cockpit.waitFor('Leave Dpad TV?', absent: true);
      expectFocusedText('Play');

      // F1 is an app shortcut wired to onMenu.
      await tapKey(cockpit, 'F1');
      await cockpit.expectVisible('Dpad TV demo');
      expectFocusedText('Close');
      await tapKey(cockpit, 'Enter');
      await cockpit.waitFor('Dpad TV demo', absent: true);
      expectFocusedText('Play');
    },
  );

  // -------------------------------------------------------------------------
  // Settings
  // -------------------------------------------------------------------------

  cockpitTestWidgets(
    'settings: toggles, disabled skip, onDirection slider, programmatic focus',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await tapKey(cockpit, 'ArrowLeft');
      await focusRailItem(cockpit, 'Settings');
      await enterContent(cockpit);

      // Entry lands on the row nearest the rail item; the topmost
      // focusable — the programmatic jump button — sits a few rows up.
      await walkUntil(
        cockpit,
        'ArrowUp',
        () => focusedTexts().contains('Jump to volume ↓'),
        maxPresses: 4,
      );
      expectFocusedText('Jump to volume ↓');

      await tapKey(cockpit, 'ArrowDown');
      expectFocusedText('Autoplay next episode');

      // Select toggles the switch.
      expect(toggleValue(cockpit, 'Autoplay next episode'), isTrue);
      await tapKey(cockpit, 'Enter');
      expect(toggleValue(cockpit, 'Autoplay next episode'), isFalse);

      await tapKey(cockpit, 'ArrowDown');
      expectFocusedText('Subtitles');
      await tapKey(cockpit, 'Enter');
      expect(toggleValue(cockpit, 'Subtitles'), isTrue);

      // The disabled parental row is skipped entirely.
      await tapKey(cockpit, 'ArrowDown');
      expectFocusedText('Volume  (← → to adjust)');

      // onDirection: left/right adjust the value, focus never moves.
      final double volumeTop = focusedRect().top;
      await tapKey(cockpit, 'ArrowRight');
      await tapKey(cockpit, 'ArrowRight');
      expectFocusedText('14');
      await tapKey(cockpit, 'ArrowLeft');
      expectFocusedText('13');
      expect(focusedRect().top, closeTo(volumeTop, 1));

      // Up/down still navigate away from the slider.
      await tapKey(cockpit, 'ArrowUp');
      expectFocusedText('Subtitles');

      // The click-sounds toggle drives Dpad.onFocusChange wiring.
      await tapKey(cockpit, 'ArrowDown');
      expectFocusedText('Volume  (← → to adjust)');
      await tapKey(cockpit, 'ArrowDown');
      expectFocusedText('Focus click sounds (Dpad.onFocusChange)');
      expect(clickSounds.value, isFalse, reason: 'freshApp starts silent');
      await tapKey(cockpit, 'Enter');
      expect(clickSounds.value, isTrue);

      // Programmatic focus through Dpad.of(context).requestFocus.
      await walkUntil(
        cockpit,
        'ArrowUp',
        () => focusedTexts().contains('Jump to volume ↓'),
        maxPresses: 5,
      );
      await tapKey(cockpit, 'Enter');
      expectFocusedText('Volume  (← → to adjust)');
    },
  );

  // The effect chips, in row order.
  const List<String> chipNames = <String>[
    'Scale + border',
    'Glow',
    'Elevation',
    'Spotlight',
    'Tint',
    'Custom',
  ];

  cockpitTestWidgets(
    'settings: the effect chip row wraps around',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await tapKey(cockpit, 'ArrowLeft');
      await focusRailItem(cockpit, 'Settings');
      await enterContent(cockpit);

      // Walk down through the toggle rows into the chip row — nearest
      // semantics land on the best chip of the nearest line, not the
      // first — then walk left to the row's first chip.
      await walkUntil(
        cockpit,
        'ArrowDown',
        () => focusedTexts().any(chipNames.contains),
        maxPresses: 9,
      );
      await walkUntil(
        cockpit,
        'ArrowLeft',
        () => focusedTexts().contains(chipNames.first),
        maxPresses: chipNames.length,
      );
      expectFocusedText(chipNames.first);

      // Six chips in a wrapping row: a full lap returns to the first.
      for (int i = 0; i < chipNames.length; i++) {
        await tapKey(cockpit, 'ArrowRight');
        expect(
          focusedTexts().any(chipNames.contains),
          isTrue,
          reason: 'press ${i + 1} left the chip row '
              '(on ${focusedTexts().join(' | ')})',
        );
      }
      expectFocusedText(chipNames.first);

      // Selecting the custom-effect chip re-styles the preview card below;
      // it stays focusable and shows its new underline treatment.
      await walkUntil(
        cockpit,
        'ArrowRight',
        () => focusedTexts().contains('Custom'),
        maxPresses: 6,
      );
      await tapKey(cockpit, 'Enter');
      await tapKey(cockpit, 'ArrowDown');
      expectFocusedText('Preview');
    },
  );

  cockpitTestWidgets(
    'settings round-trip: freeze navigation, restore it, remap WASD',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await tapKey(cockpit, 'ArrowLeft');
      await focusRailItem(cockpit, 'Settings');
      await enterContent(cockpit);

      // Walk down to the freeze toggle (the disabled parental row is
      // skipped on the way).
      final int steps = await walkUntil(
        cockpit,
        'ArrowDown',
        () => focusedTexts().contains('D-pad enabled (Dpad.enabled)'),
        maxPresses: 12,
      );
      expect(steps, greaterThan(0), reason: 'never reached the freeze toggle');
      expect(toggleValue(cockpit, 'D-pad enabled (Dpad.enabled)'), isTrue);

      // Off: navigation freezes wherever focus is — the playback-overlay
      // pattern. Arrows must move nothing.
      await tapKey(cockpit, 'Enter');
      expect(dpadEnabled.value, isFalse);
      final Rect frozen = focusedRect();
      await tapKey(cockpit, 'ArrowDown');
      await tapKey(cockpit, 'ArrowUp');
      expect(
        (focusedRect().top - frozen.top).abs(),
        lessThan(1),
        reason: 'navigation must be frozen while Dpad.enabled is false',
      );

      // Select still fires on the focused row — the only way back out.
      await tapKey(cockpit, 'Enter');
      expect(dpadEnabled.value, isTrue);

      // Restored: walk up to the WASD toggle and flip it on.
      await walkUntil(
        cockpit,
        'ArrowUp',
        () => focusedTexts().contains('WASD movement (custom DpadKeySet)'),
        maxPresses: 12,
      );
      await tapKey(cockpit, 'Enter');
      expect(wasdKeys.value, isTrue);

      // The remap is live: W moves focus up, S moves it back down.
      final Rect wasdRow = focusedRect();
      await tapKey(cockpit, 'KeyW');
      expect(
        focusedRect().top,
        lessThan(wasdRow.top - 10),
        reason: 'W must join the up key while the remap is on',
      );
      await tapKey(cockpit, 'KeyS');
      expect(
        (focusedRect().top - wasdRow.top).abs(),
        lessThan(2),
        reason: 'S must move back down to the toggle row',
      );
    },
  );

  // -------------------------------------------------------------------------
  // Focus inspector and app shortcuts
  // -------------------------------------------------------------------------

  cockpitTestWidgets(
    'focus inspector overlay paints and stays out of the way; H/L/S jump',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await cockpit.expectVisible('FEATURED');

      // 'I' toggles the inspector overlay.
      await tapKeyRaw(cockpit, 'KeyI');
      expect(showFocusInspector.value, isTrue);
      expect(
        cockpit.flutter.widgetList(
          find.byWidgetPredicate(
            (Widget w) =>
                w is Text && w.style?.color == const Color(0xFFFF8A80),
          ),
        ),
        isNotEmpty,
        reason: 'inspector label not painted',
      );

      // The overlay is ignore-pointer: navigation still works under it.
      await tapKeyRaw(cockpit, 'ArrowDown');
      expect(focusedDebugLabel, 'poster:Neon Tide');

      // Toggle back off; now the UI can go quiet again.
      await tapKeyRaw(cockpit, 'KeyI');
      expect(showFocusInspector.value, isFalse);
      await cockpit.waitForUi();

      // H / L / S are app-level shortcuts suspended only while typing.
      await tapKey(cockpit, 'KeyL');
      await cockpit.expectVisible('Afterglow');
      await tapKey(cockpit, 'KeyS');
      await cockpit.expectVisible('Search titles…');
      await tapKey(cockpit, 'KeyH');
      await cockpit.expectVisible('FEATURED');
    },
  );

  // -------------------------------------------------------------------------
  // RTL
  // ---------------------------------------------------------------------------

  cockpitTestWidgets(
    'RTL demo: mirrored rail side, per-direction edges, reading order',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      // Flip the RTL toggle in Settings.
      await tapKey(cockpit, 'ArrowLeft');
      await focusRailItem(cockpit, 'Settings');
      await enterContent(cockpit);
      await walkUntil(
        cockpit,
        'ArrowDown',
        () => focusedTexts().contains('Right-to-left layout (RTL demo)'),
        maxPresses: 9,
      );
      await tapKey(cockpit, 'Enter');

      // The rail now sits on the physical right: RIGHT leaves content to it.
      await leaveToRail(cockpit);
      expect(focusedDebugLabel, 'sidebar:Settings');

      // Entering content is a LEFT press now.
      await focusRailItem(cockpit, 'For you');
      await enterContent(cockpit);
      expectFocusedText('Play');

      // The banner row mirrors: Play is at the right end, LEFT moves in.
      await tapKey(cockpit, 'ArrowLeft');
      expectFocusedText('More info');
      await tapKey(cockpit, 'ArrowRight');
      expectFocusedText('Play');
      // The banner's right edge still leaves to the (mirrored) rail.
      await leaveToRail(cockpit);
      expect(focusedDebugLabel, 'sidebar:For you');

      // Poster rows mirror their per-direction edges: LEFT advances and
      // wraps, RIGHT leaves to the rail.
      await enterContent(cockpit);
      expectFocusedText('Play');
      await tapKey(cockpit, 'ArrowDown');
      expect(
        _continueWatching.contains(focusedDebugLabel?.substring(7)),
        isTrue,
        reason: 'should land on the Continue Watching row, '
            'not ${focusedDebugLabel ?? 'nothing'}',
      );
      await walkUntil(
        cockpit,
        'ArrowLeft',
        () => focusedDebugLabel == 'poster:North of Nowhere',
        maxPresses: 8,
      );
      await tapKey(cockpit, 'ArrowLeft');
      expect(
        focusedDebugLabel,
        'poster:Neon Tide',
        reason: 'RTL wrap must return to the reading start (rightmost)',
      );
      await leaveToRail(cockpit);
      expect(focusedDebugLabel, 'sidebar:For you');

      // The grid line wrap follows the reading order too: LEFT walks a line
      // and steps DOWN lines; the first cell of a line is the RIGHTMOST.
      await focusRailItem(cockpit, 'Library');
      await enterContent(cockpit);
      final Rect first = focusedRect();
      final int steps = await walkUntil(
        cockpit,
        'ArrowLeft',
        () => focusedRect().top > first.top + 20,
        maxPresses: 10,
      );
      expect(steps, greaterThan(0), reason: 'never stepped to the next line');
      // Only the reading-start cell of a line has nothing to its physical
      // right — proof that the step landed on the line's first cell.
      await tapKey(cockpit, 'ArrowRight');
      expect(
        focusedDebugLabel,
        'sidebar:Library',
        reason: 'RTL line wrap must land on the rightmost cell of the line',
      );
    },
  );

  // -------------------------------------------------------------------------
  // Focus resilience
  // -------------------------------------------------------------------------

  cockpitTestWidgets(
    'focus survives its host being disposed wholesale',
    app: freshApp,
    options: _options,
    body: (cockpit) async {
      await tapKey(cockpit, 'ArrowLeft');
      await focusRailItem(cockpit, 'Search');
      await enterContent(cockpit);
      await walkUntil(
        cockpit,
        'ArrowUp',
        () => focusInsideEditable,
        maxPresses: 3,
      );
      expect(focusInsideEditable, isTrue,
          reason: 'never reached the search field');

      await cockpit.type('the', into: 'Search titles…');
      await cockpit.waitForUi();
      await cockpit.expectVisible('The Long Orbit'); // first match is mounted

      // Focus a result card...
      await tapKey(cockpit, 'ArrowDown');
      expect(focusedDebugLabel, 'poster:The Long Orbit');

      // ...then a section shortcut disposes the entire grid under it.
      // The remote must never go dead: focus lands on a real survivor.
      await tapKey(cockpit, 'KeyL');
      // Focus restoration lands a frame or two after the dispose; drive a
      // few short frames for it instead of sampling once, so a busy frame
      // can't flake the run (bounded: ~2s of frames, no idle waits).
      for (int i = 0; i < 20 && focusedDebugLabel == null; i++) {
        await cockpit.flutter.pump(const Duration(milliseconds: 100));
      }
      final String? label = focusedDebugLabel;
      expect(label, isNotNull, reason: 'focus was lost with its host');
      expect(
        label!.startsWith('poster:') || label.startsWith('sidebar:'),
        isTrue,
        reason: 'restored focus should land on a real item, got "$label"',
      );
    },
  );
}
