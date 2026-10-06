# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2026-10-06

Supports Flutter `>= 3.19` / Dart `>= 3.3` (was `>= 3.24` / `>= 3.5`).

### Added

- **Per-direction edge behaviors** — `DpadRegion` gains `leftEdge`,
  `rightEdge`, `upEdge` and `downEdge`, overriding `horizontalEdge` /
  `verticalEdge` for a single boundary. Express layouts an axis-wide
  behavior cannot: a carousel that wraps to the right while `left` still
  reaches the navigation rail, or a grid row that stops at its end without
  sealing off the sidebar.
- **`DpadEdgeBehavior.lineWrap`** — grid line wrap: right past the last
  cell of a row moves to the first cell of the row below, left past the
  first cell moves to the last cell of the row above (symmetrically for
  columns with up/down). Unlike `wrap` (same-row carousel), this is the
  typewriter behavior grids want: movement stays on the current line while
  it has cells ahead, then takes the line step — never a diagonal jump to
  another line. Ragged last rows are handled. At the grid's first/last
  line the key is consumed and `onEdge` fires; when the next line is not
  built yet (lazy grids), the engine scrolls and retries, like
  directional traversal.
- **RTL support** — line wrap follows the reading order (in RTL layouts,
  `left` steps to the line below and `right` back up), and initial focus
  lands on the top-*right* item instead of the top-left one. Text-field
  caret exit rules and scroll-reveal already behaved correctly under RTL
  (Flutter's caret movement is logical, and scrollables report their
  directionality-adjusted axis).

### Changed

- Lowered the SDK floor to Flutter `>= 3.19` / Dart `>= 3.3`. The only
  code change: `DpadElevationEffect` passes an explicit
  `BoxShape.rectangle` to `AnimatedPhysicalModel`, which Flutter 3.19
  requires.

### Fixed

- **`Dpad.enabled` now truly freezes** — previously only Dpad's own
  shortcuts stood down, but the framework's built-in arrow shortcuts
  still navigated with the very same TV policy, so focus kept moving.
  Arrows are now consumed without moving, back/menu and app shortcuts
  stand down, and programmatic `DpadController.move` calls freeze too
  (returning `false`); select keys on the focused item keep working (the
  documented way for a frozen UI to switch navigation back on).
- **Remapped movement keys no longer hijack typing** — with a custom
  `DpadKeySet` (WASD), pressing a remapped key while a text field was
  focused moved focus out and swallowed the character. Only the four
  physical arrow keys keep the caret-edge escape contract inside text
  fields; every other movement key falls through and types.
- **Multiline text fields escape vertically at the text bounds** —
  previously a multiline field trapped focus forever: up/down never
  left it, stranding remote-only users. Up from the caret at the text's
  very start (first line) and down from the very end (last line) now
  move focus out, while inner-line arrows keep editing the caret.
- Hardened two crash paths found in review: a focus node detached from
  the focus tree (element reuse after dispose) no longer falls into the
  framework's `nearestScope!` assert, and a wrap rewind that outlives
  its scrollable (page popped mid-hop) stops instead of touching a
  disposed position.
- **Lazy `lineWrap` to unbuilt lines** — a wrap move whose destination
  line is not built yet (long lazy grids, destination far off-screen)
  now scrolls the region's scrollable toward that line in bounded
  viewport hops and retries, instead of silently consuming the key at
  the first built line. The rewind resolves the extreme node
  geometrically, so wrap works no matter how far the destination sits
  from the viewport.

## [3.0.0] - 2026-06-13

A ground-up rewrite. 3.0 replaces the 2.x key interception and rule tables
with a TV-correct traversal engine built on Flutter's own focus primitives
(`FocusTraversalPolicy`, `Shortcuts`, `Actions`). The API is smaller,
declarative, and tuned for how TV interfaces actually behave.

Requires Flutter `>= 3.24` / Dart `>= 3.5`.

### Added

- **`DpadTraversalPolicy`** — directional navigation modeled on Android's
  `FocusFinder`/Leanback: edge-based direction tests, beam preference
  (aligned candidates beat diagonal ones) and weighted distances.
- **`DpadRegion`** — declarative navigation areas:
  - region-first traversal: focus moves within the region before
    considering outside targets;
  - per-region focus memory with `DpadEnterBehavior.restore` (default),
    `entry` and `nearest`;
  - per-axis edge control with `DpadEdgeBehavior.leave`, `stop` and `wrap`
    (carousel wrap-around);
  - `onEdge` and `onFocusChange` callbacks; nesting supported.
- **Lazy-list awareness** — when no focus candidate exists but a scrollable
  can still scroll in that direction (e.g. unbuilt `ListView.builder`
  items), the engine scrolls and retries instead of stopping.
- **Focus resilience** — guaranteed startup focus (with `autofocus` taking
  precedence), initial focus for routes pushed without `autofocus`,
  restoration when the focused widget is disposed, and restoration on app
  resume. The remote can never end up with nothing focused.
- **`DpadRegion.memoryKey`** — focus memory that persists across full
  subtree rebuilds (section/tab switchers), with position-aware
  restoration when the original items were recreated.
- **TV-correct text fields** — arrows move the caret mid-text but navigate
  away at the caret's edge (and vertically in single-line fields), so a
  remote-only user is never trapped in a search box; IME composition owns
  all keys while active.
- **`Dpad.debugOverlay`** — an on-screen focus inspector outlining the
  focused node with its label, region and geometry.
- **`Dpad.onFocusChange`** — a global hook on every focus move, for click
  sounds, haptics or analytics.
- **`DpadFocusable` interactions** — `onLongSelect` (held center button)
  with select/long-select disambiguation, pressed-state visuals,
  `onDirection` for slider-style consumption of arrows, tap/click support
  for hybrid devices, and `excludeChildFocus` (default `true`) so wrapped
  buttons never become double focus stops.
- **Class-based focus effects** — `DpadScaleEffect` (pressed push-down),
  `DpadBorderEffect` (layout-shift-free foreground border),
  `DpadGlowEffect`, `DpadElevationEffect`, `DpadOpacityEffect`,
  `DpadTintEffect`, `DpadCustomEffect`; composable via `effects:` lists.
- **`DpadTheme` / `DpadThemeData`** — app-wide defaults for effects,
  auto-scroll padding/duration/curve and long-select duration.
- **`DpadController`** (`Dpad.of(context)`) — `move*()`, `next()`,
  `previous()`, `select()`, `back()`, `requestFocus()`, `clearFocus()`,
  `ensureVisible()`, `focused`.
- **`DpadKeySet`** — semantic key mapping (up/down/left/right, select,
  back, menu) with TV-wide defaults and `copyWith` remapping.
- **Text-input safety** — directional keys, back/menu and app shortcuts
  automatically stand down while an `EditableText` is focused.
- **`Dpad.wrap()`** — one-line installation through `MaterialApp.builder`
  covering every route, dialog and overlay.
- **`DpadScroll.ensureVisible`** — padded reveal that walks all scrollable
  ancestors, honors reversed axes and centers oversized items.

### Changed

- **BREAKING** `DpadNavigator` → `Dpad` (recommended placement:
  `MaterialApp(builder: Dpad.wrap())`).
- **BREAKING** `Dpad` static helpers → instance methods on
  `Dpad.of(context)` (`navigateUp` → `moveUp`, `navigateNext` → `next`,
  `requestFocusSafely` → `requestFocus`, `scrollToFocus` →
  `ensureVisible`).
- **BREAKING** `DpadFocusable.builder` signature is now
  `(context, DpadFocusState state, child)`; `state.focused` replaces the
  `isFocused` boolean and `state.pressed` is new. `child` is required.
- **BREAKING** `onFocus`/`onBlur` merged into `onFocusChange(bool)`.
- **BREAKING** selection is delivered through Flutter's `Actions` system
  and raw key tracking instead of `consumeKeyboardToken()`; select fires
  once per press with correct repeat suppression.
- **BREAKING** `onBackPressed` → `onBack` (returns `bool`: `true`
  consumes, `false` lets the framework handle it); `onMenuPressed` →
  `onMenu`; `customShortcuts` → `shortcuts`.
- Auto-scroll defaults now come from the theme (`scrollPadding: 48`).

### Removed

- **BREAKING** `FocusEffects` closure factories — use the `DpadEffect`
  classes.
- **BREAKING** `FocusMemoryOptions`, `FocusHistoryManager`,
  `FocusHistoryEntry`, `onNavigateBack` and the global focus-history stack
  — per-region memory (`DpadRegion`) replaces them.
- **BREAKING** `RegionNavigationOptions`, `RegionNavigationRule`,
  `RegionNavigationStrategy`, `RegionNavigationManager`,
  `RegionAwareFocusTraversalPolicy`, `RegionTraversalGroup`,
  `RegionTraversalGroupScope` and the imperative node registration —
  `DpadRegion` + `DpadTraversalPolicy` replace the entire rule system.
- **BREAKING** `DpadFocusable.region` / `isEntryPoint` / `entryPriority` —
  membership now comes from the widget tree (nearest `DpadRegion`); mark
  one item per region with `entry: true`.

### Fixed

- Wrapping a focusable Material button in `DpadFocusable` no longer
  creates two d-pad stops.
- Space/Enter and arrow keys are no longer hijacked while typing in a
  `TextField`.
- Holding the select key no longer fires `onSelect` repeatedly.
- Auto-scroll now works correctly inside reversed scrollables and centers
  items larger than the viewport.
- Focus no longer dies when the focused item is removed from a refreshing
  list.
- The [Dpad] root keeps an identical widget structure for every
  configuration, so flipping `enabled` or `debugOverlay` at runtime never
  resets the application subtree.

## [2.0.2] - 2025-11-26

### Fixed
- Region navigation policy detection via `FocusTraversalGroup.maybeOf()`.

### Improved
- Streamlined navigation flow in `_navigate()`.

## [2.0.1] - 2025-11-25

### Added
- Window focus restoration on app resume.

### Improved
- Within-region navigation priority and focus history safety.

### Fixed
- Navigation after window focus loss; sidebar jump issues; focus memory
  restoration timing.

## [2.0.0] - 2025-11-25

### Added
- Region-based navigation system (`RegionNavigationOptions`,
  `RegionNavigationRule`, strategies, `RegionAwareFocusTraversalPolicy`).

## [1.2.2] - 2025-11-20

### Added
- Auto-scroll for focused widgets (`autoScroll`, `scrollPadding`,
  `Dpad.scrollToFocus`).

## [1.1.0] - 2025-11-15

### Added
- Sequential navigation (`navigateNext` / `navigatePrevious`), media key
  support, focus memory with history stack.

## [1.0.0] - 2025-11-10

- Initial release: `DpadNavigator`, `DpadFocusable`, `FocusEffects`,
  programmatic `Dpad` utilities.
