import 'package:flutter/foundation.dart';

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
