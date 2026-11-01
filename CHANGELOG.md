# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.3.0] - 2026-11-01

### Added

- **`Dpad.onBlockedMove`** — a root callback for directional presses that
  could not move focus: dead ends (the last item of a row), and boundaries a
  region consumed (`stop`, or a `wrap`/`lineWrap` with nowhere left to go).
  The natural home for the edge sound, haptics or a "no more items" toast.
  The flying highlight's edge bounce now fires for the same presses (see
  `DpadHighlight.nudgeOffset`), so every blocked press reads the same. One
  exception: a boundary discovered by a lazy-load scroll retry reports
  through `DpadRegion.onEdge` only. Manual users of the policy read the
  same signal from the new `DpadTraversalPolicy.lastBlockedEdge` getter
  and `consumeBlockedEdge()` (the flag the root's move action drains).
- **Semantics wiring** — every self-contained `DpadFocusable` (the default)
  announces as a button and serves assistive activation (TalkBack's
  double-tap, VoiceOver's default action): a tap fires `onSelect`, a
  long-press fires `onLongSelect`, with no double-firing against the tap
  gesture. An interactive child keeps its own semantics node and
  activation, so the reader reaches the child's callback first — wire it
  to the same behavior, or `ExcludeSemantics` it and use
  `DpadFocusable.semanticLabel`. New `DpadFocusable.semanticLabel` also
  gives image-only items a spoken name.
- **Reduced motion** — with the platform's "remove animations" setting on
  (`MediaQuery.disableAnimations`), highlight flights land instantly,
  appear/fade cuts are immediate, the edge bounce stands down and
  auto-scrolls jump instead of animating. Toggling the setting re-resolves
  live.
- **Centered reveals** — `DpadRevealAlignment { nearest, center }` picks how
  a newly focused item lands along each scrollable's axis: just enough to
  reveal it (the default), or centered theater-style. Plumbed through
  `DpadThemeData.scrollAlignment`, `DpadFocusable.scrollAlignment`,
  `DpadController.ensureVisible(alignment:)` and the low-level
  `DpadScroll.ensureVisible(alignment:)`.
- **`DpadController.select()` press pulse** — a programmatic select now
  pulses the focused item's pressed visual state first (the same squash a
  real key press produces, through `DpadFocusState.pressed` and the flying
  highlight); foreign targets (plain buttons) pulse the highlight directly.
  The beat is `DpadController.selectPulseDuration` (100ms by default).
- **`DpadController.ensureVisible` follows the theme** — parameters left
  `null` now take the closest `DpadThemeData`'s scroll padding, duration,
  curve and alignment (the shared defaults are exposed as
  `DpadScroll.defaultPadding`/`defaultDuration`/`defaultCurve`).
- README "Shipping checklist" (banner, leanback intent, overscan, real
  D-pad testing; EN + CN) and an "Accessibility" section.

### Changed

- **Engine bookkeeping is `@internal` now.** `DpadRegionState.noteFocus`,
  `forget`, `notifyEdge` and `resolveEnter`, and
  `DpadTraversalPolicy.invalidateRewinds`, are the wiring between the root,
  the policy and the focusables — they stay callable from inside the package
  but no longer present as public API. The pre-existing documented
  members (`lastFocused`, `focusNodes`, `edgeBehaviorFor`, `clearMemory`,
  `clearPersistentMemory`) are unaffected.
- **`Dpad.enabled` now freezes the whole remote surface.** Besides arrow
  keys and `move*()`, `next()`, `previous()` and `back()` stand down while
  frozen, so a scripted caller (voice remote, automated tests) cannot step
  focus around a playback overlay with the remote-equivalent actions;
  `requestFocus`/`clearFocus` stay available as explicit app actions, and
  `select()` keeps working — it is how a frozen UI unfreezes itself.
- **`DpadController.back` respects the text-field stand-down.** While a
  text field holds focus, `back()` does nothing and returns `false` — the
  IME owns the keys then, exactly like the back key itself. `move()` keeps
  acting (its docs now say so): the caret-editing gates belong to the key
  pipeline, not to a programmatic move.
- **Nested `Dpad` roots own their subtree's focus reporting.** Focus inside
  a nested root no longer fires the outer root's `onFocusChange` or feeds
  its restore memory — one root, one ownership (previously both reported).

### Fixed

- **A held select key no longer machine-guns the next focused item.** A
  key-down that moves focus (an `onSelect` pushing a route or opening a
  dialog, a plain button's `onPressed` calling `requestFocus`) handed the
  OS key repeats to an item that never saw the key-down; those repeats
  read as fresh presses and fired `onSelect` at repeat rate on whatever
  had focus. A `DpadFocusable` now swallows every select-key repeat — a
  select fires once per press, wherever the press began.
- **Down no longer moves sideways onto a taller neighbor.** The downward
  direction test accepted any item whose bottom edge sat lower than the
  source's, so a taller card in the same row (a two-line title) or a tile
  spanning the source vertically won the press over the row below — and
  `lineWrap` stepped back along the line instead of to the next one. Down
  now mirrors up (and Android's `FocusFinder`): candidates must lie below
  the source.
- **Rapid presses no longer snap the highlight onto the previous item.** A
  retarget mid-flight restarted from the old target's full rect, so every
  press that outran the flight first teleported the highlight onto the
  item it was still flying to. The new flight now takes off from the rect
  on screen and still follows its origin through scrolls.
- **The highlight follows a reflow while asleep.** Once landed, the
  tracker only woke for focus, scroll and window-metrics changes, so an
  item moved by a layout change (a row inserted above, a sibling resizing)
  left the ring painted at its old place. The sleeping highlight now checks
  its target after every frame the app renders — no extra frames when the
  app is idle.
- **The flying highlight works on Flutter 3.19–3.23 again.** Its
  measurement used sibling-to-sibling `getTransformTo`, which only exists
  on Flutter 3.24+; on older versions the first focus change crashed in
  debug and release. The transform now goes through the render root and
  works on the declared minimum again.
- **A wrap-rewind chain no longer crashes when its page dies mid-chain.**
  The next hop after the page hosting a wrapping carousel was popped read
  `ScrollableState.context` on a defunct state — the mounted-guard itself
  threw. The context is captured while alive and re-checked without
  touching the defunct state.
- **Freezing cancels a lazy-reveal retry in its completion window too.** A
  freeze landing in the frame between the reveal scroll completing and the
  post-frame retry running used to slip past the cancellation check and
  move focus while frozen.
- **A changed `memoryKey` starts fresh.** A region rebuilt under a
  different key (or none) used to keep the previous identity's in-state
  memory and restore an item of the old identity on re-entry.
- **Built-in `DpadEffect`s compare by value.** An inline
  `DpadThemeData(effects: [DpadScaleEffect()])` used to change identity on
  every root rebuild, invalidating the theme and rebuilding every item —
  the same fix 3.2.0 applied to highlight effects, now for item effects
  (`DpadCustomEffect` compares its builder by identity and documents it).
- **The example builds on Android again.** Its manifest had never been
  valid (no v2-embedding metadata, the launcher intent outside the
  activity, a missing TV banner and an AppCompat theme without the
  dependency); all fixed, the gamepad feature is optional now, and the
  Android toolchain (Gradle 8.14, AGP 8.11, Kotlin 2.2) meets current
  Flutter's minimums.
- **Flights take off from the from-item's own padding.** The flight
  origin used to be measured with the destination's configuration, so
  consecutive items with different `DpadHighlight.padding` took off from
  the wrong edge; the origin now resolves the source item's own config.
- **The highlight recovers after a slow route build.** A target that stayed
  unmeasurable past the give-up budget used to leave the highlight dark
  until the next focus change; a slow probe now revives it within half a
  second of the item finally laying out.

## [3.2.0] - 2026-11-01

### Added

- **Flying highlight** — the continuous focus indicator of mainstream TV and
  game interfaces: one highlight that slides from item A to item B as the
  d-pad moves, morphing between their sizes. Enable it app-wide with
  `Dpad(highlight: const DpadHighlight())`; restyle a page or section by
  nesting a `DpadHighlightTheme`, a single item with
  `DpadFocusable.highlight` (or opt it out with `DpadHighlight.none`). The
  style is resolved for wherever focus lands, nearest first.
  - The flight follows the focused item through scrolls, route transitions
    and focus-effect transforms, re-measuring both endpoints every frame (a
    scrolling list moves the takeoff item too); mid-flight retargeting
    chains smoothly when keys outrun the animation; the first appearance fades in place and lost
    focus fades out. `nudgeOffset` adds the directional edge bounce games
    use for blocked moves. Motion knobs (`duration`, `curve`, `padding`,
    `appearDuration`, `nudgeOffset`) live on `DpadHighlight`.
  - Looks are composable `DpadHighlightEffect`s, each with its own knobs:
    `DpadHighlightRingEffect` (the tvOS ring, and the default),
    `DpadHighlightGlowEffect`, `DpadHighlightSpotlightEffect`,
    `DpadHighlightBracketsEffect` (game HUD corners),
    `DpadHighlightVignetteEffect` (dims everything outside the item) and
    `DpadHighlightCustomEffect`. Subclassing `DpadHighlightEffect` or using
    the custom effect gives every-frame access to the live
    `DpadHighlightState` — the interpolating `rect` and `radius`, the
    tracked `node`, the flight timeline (`fromNode`, `t`) and
    `pressed`/`visible` — enough to interpolate values the engine does not
    (colors, shadows, private shape tables).
  - **Shape following** — the highlight reads each item's own silhouette
    (`ClipRRect`, a `BoxDecoration` or `ShapeDecoration` corner radius or
    circle, `ClipOval`, physical shape models — `Material(shape:)` and with
    it Material 3 cards; corners resolve in the app's text direction) and
    morphs its corner radius between shapes mid-flight:
    a rounded poster becomes a circular avatar's ring as the highlight flies
    there. The rounded effects (ring, spotlight, vignette, glow) follow the
    shape by default (`followShape: true`); an explicit `borderRadius` (a
    number) pins it; shape data from your own models mixes in through the public
    `DpadHighlight.radiusOf(node)`.
  - While the highlight is on, pair per-item effects with a simple lift —
    `DpadThemeData(effects: [DpadScaleEffect()])` — so the ring carries the
    outline (the example app demonstrates the pairing).

### Fixed

- **The flying highlight frames what the user actually sees.** A focused
  item's `DpadScaleEffect` lift grows it beyond its layout rect, but the
  highlight measured the un-scaled rect — the card poked out of the ring on
  every side. The steady-state focus scale is now recorded per item and the
  highlight inflates its target rect around the center to match (custom
  builders draw their own presentation and stay at 1.0; `DpadHighlight`
  `padding` covers anything else).
- **The highlight can no longer strand mid-route.** It used to stop
  following the focused item three frames after its flight ended — even if
  the route transition was still sliding the item into place, freezing the
  ring offset from the focused button. The tracker now only sleeps once the
  target itself has stopped moving.
- **Focus changes into a still-building route now fly instead of
  teleporting.** When the focus notification outran the new route's first
  frame, the highlight stayed at the old item and then snapped onto the new
  one; it now flies from wherever it sits as soon as the target's geometry
  exists.
- **Typing in a text field wrapped by a `DpadFocusable` is no longer
  hijacked.** With `excludeChildFocus: false` (the documented way to embed
  a field), the item's own select/direction handlers claimed
  `space`/`enter` and the arrows while the caret was inside: select fired
  mid-sentence and the keys never reached the field. Item handlers now
  stand down whenever a descendant holds primary focus — the root's
  text-field contract stays in charge of letting arrows escape at the
  caret edges.
- **Freezing navigation cancels a lazy-reveal retry in flight.** Setting
  `Dpad.enabled = false` during the 160ms reveal scroll toward a
  not-yet-built neighbor now stops the chained retry (like it already
  stopped wrap-rewind chains) instead of moving focus once more after the
  freeze.
- **A same-look rebuild no longer relaunches highlight flights.** The
  built-in effects compare structurally now, so a `MaterialApp.builder`
  rebuild carrying an inline-but-equal `DpadHighlight` (a theme or locale
  change) leaves a landed highlight landed instead of replaying a 220ms
  flight of rebuilds.
- **The edge bounce keeps its rhythm on key repeats.** Holding a direction
  against an edge used to restart the bounce from zero on every repeat —
  a stutter; the arc now finishes and the next repeat starts the next
  bounce.

### Performance

- **Flying-highlight frame costs cut.** The vignette wash paints with a
  single even-odd path instead of a full-screen offscreen layer per flight
  frame; silhouette detection is memoized per item instead of re-walking
  its render subtree every frame; rect measurement takes one transform
  walk instead of two global round-trips; scrolls that cannot move the
  focused item (a background carousel) no longer keep the tracker awake;
  and the fade-out stops the flight and bounce instead of letting them
  run out.

### Documented

- **Game controller support matrix** — Android controllers work out of the
  box (d-pad as arrows, `A`/`B` as select/back in the default key set); the
  README now covers remapping the remaining buttons and bridging analog
  sticks / web / desktop through a gamepad plugin into `DpadController`.

## [3.1.1] - 2026-10-07

### Fixed

- **Collapsed scrollables no longer swallow keys in a retry loop** —
  navigating away from a region whose matching-axis scrollable had a
  zero along-axis viewport (an animated collapse keeping the subtree
  mounted, or any layout glitch) consumed the key forever: the scroll
  step was `viewportDimension * 0.8 == 0`, the scroll animation
  completed instantly, and the retry re-entered the search every frame
  without ever moving. The move now bails out when a hop cannot make
  progress (the same `< 0.5px` guard `DpadScroll` applies to reveal
  scrolls), so the key falls through to the configured edge behavior.
- **App resume can no longer be downgraded by a queued restore** — a
  focus-to-null event right before backgrounding (frames suspended, so
  the restore was still queued) dropped the resume flag: the pending
  restore then ran as a plain one, treated the unfocus as deliberate,
  and skipped restoration, leaving the app without focus after resume.
  The queued restore now keeps the strongest flag.

## [3.1.0] - 2026-10-07

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
  Arrows are now consumed without moving (while a text field is focused
  they fall through to plain caret editing, which still never moves
  focus), back/menu and app shortcuts stand down, in-flight wrap
  rewinds stop scrolling and grabbing focus, and programmatic
  `DpadController.move` calls freeze too (returning `false`); select
  keys on the focused item keep working (the documented way for a
  frozen UI to switch navigation back on).
- **Programmatic focus outranks wrap rewinds** — `Dpad.requestFocus`,
  `Dpad.clearFocus` and Dpad's own focus recovery (list refresh, route
  pop, app resume) now invalidate any wrap-rewind chain still in
  flight, so a chain can no longer drag focus away from where the app
  deliberately put it.
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
