import 'package:flutter/foundation.dart';

/// The demo's focus presentation, cycled from the Settings section — an
/// index into [highlightChoices] (see highlight_styles.dart for the
/// catalog and its [Dpad.highlight] configurations). 0 = classic per-item
/// effects; anything else is a flying-highlight look, and the value also
/// picks the per-item effects that pair with it.
final ValueNotifier<int> highlightStyle = ValueNotifier<int>(1);

/// The active sidebar section (0 = For you, 1 = Library, 2 = Search,
/// 3 = Settings). Lifted to a notifier so app-level key shortcuts can
/// switch sections too.
final ValueNotifier<int> activeSection = ValueNotifier<int>(0);

/// Runtime toggle for the built-in focus inspector
/// ([Dpad.debugOverlay]) — flip it from the Settings section.
final ValueNotifier<bool> showFocusInspector = ValueNotifier<bool>(false);

/// Runtime toggle for the focus "tick" sound played through
/// [Dpad.onFocusChange].
final ValueNotifier<bool> clickSounds = ValueNotifier<bool>(true);

/// Runtime toggle for a right-to-left layout — the app mirrors and the
/// d-pad keeps working: initial focus lands top-right, grid line wrap
/// follows the reading order, and the rail stays the only way out of a
/// row. Flip it from the Settings section.
final ValueNotifier<bool> rtlLayout = ValueNotifier<bool>(false);

/// Runtime toggle for a custom [DpadKeySet]: WASD joins the arrows as
/// movement keys (a classic remap scenario for keyboard-first users).
final ValueNotifier<bool> wasdKeys = ValueNotifier<bool>(false);

/// Runtime toggle for [Dpad.enabled] — while off, focus freezes wherever
/// it is (the pattern for playback overlays). Select keys still work, so
/// the toggle can flip back.
final ValueNotifier<bool> dpadEnabled = ValueNotifier<bool>(true);

/// Runtime toggle for centered reveals ([DpadThemeData.scrollAlignment]) —
/// when on, every focused item lands mid-viewport instead of just peeking
/// in (the Netflix-style row theater).
final ValueNotifier<bool> centeredReveal = ValueNotifier<bool>(false);

/// How many directional moves have been blocked so far
/// ([Dpad.onBlockedMove]) — the Settings section displays it live.
final ValueNotifier<int> blockedMoveCount = ValueNotifier<int>(0);

/// The direction of the most recent blocked move ([Dpad.onBlockedMove]),
/// or `null` before the first one.
final ValueNotifier<String?> lastBlockedMove = ValueNotifier<String?>(null);

/// Restores every notifier to its launch default — the isolation story for
/// both the widget tests and the integration harness.
void resetAppState() {
  highlightStyle.value = 1;
  activeSection.value = 0;
  showFocusInspector.value = false;
  clickSounds.value = true;
  rtlLayout.value = false;
  wasdKeys.value = false;
  dpadEnabled.value = true;
  centeredReveal.value = false;
  blockedMoveCount.value = 0;
  lastBlockedMove.value = null;
}
