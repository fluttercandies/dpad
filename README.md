<h1 align="center">
  📺 Dpad
  <br>
  <span style="font-size: 0.6em; font-weight: normal;">D-pad navigation for Flutter TV apps</span>
</h1>

<p align="center">
  <a href="https://github.com/fluttercandies/dpad/blob/main/README_CN.md">
    <img src="https://img.shields.io/badge/📖-中文文档-red.svg" alt="中文文档">
  </a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/fluttercandies/dpad/main/dpad.png" alt="Dpad Logo" width="200">
</p>

<p align="center">
  <a href="https://pub.dev/packages/dpad">
    <img src="https://img.shields.io/pub/v/dpad.svg" alt="Pub Version">
  </a>
  <a href="https://github.com/fluttercandies/dpad">
    <img src="https://img.shields.io/badge/platform-android%20tv%20%7C%20fire%20tv%20%7C%20apple%20tv-blue.svg" alt="Platform">
  </a>
  <a href="https://github.com/fluttercandies/dpad/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  </a>
</p>

<div align="center">
  <strong>Focus that behaves the way TV users expect — regions with memory, beam-based directional traversal, press feedback, and a remote that never goes dead.</strong>
</div>

## Why Dpad?

Flutter's built-in directional focus picks the geometrically *closest* widget. On a real TV layout that means focus jumps lanes between the sidebar and the content, skips rows, escapes carousels, and forgets where you were. Dpad replaces that engine with the model TV platforms actually use (Android's `FocusFinder` / Leanback):

- **🗂 Regions with memory** — a sidebar, a poster row, a grid: each `DpadRegion` keeps focus inside itself first, and when you come back, you land on the item you left.
- **📐 Beam-based traversal** — candidates aligned with the focused item beat diagonal ones. Down means *down*, not "down-ish and slightly to the right".
- **🧲 Edge control per axis** — leave, stop, or wrap at every region boundary. Carousels wrap, panels stop, everything else flows.
- **🛟 Focus never dies** — app starts with focus, pushed pages get initial focus without `autofocus`, focus survives list refreshes, dialog dismissals and app resume. A remote with nothing focused is a dead remote; Dpad makes that state unrepresentable.
- **⏯ Real remote semantics** — select & long-select with pressed-state visuals, back/menu keys, app shortcuts, key repeat — all standing down automatically while a text field is being edited.
- **⌨️ Text fields done right** — mid-text, arrows move the caret; at the caret's edge (and vertically in single-line fields) they navigate away, so a remote-only user is never trapped in a search box. IME composition owns the keys while active.
- **📜 Lazy-list aware** — when the next item isn't built yet (`ListView.builder`), Dpad scrolls and continues instead of stopping at the cache boundary.
- **🖱 Hybrid input** — taps and mouse clicks work out of the box for touch TVs and desktop debugging.
- **🔍 Built-in focus inspector** — `debugOverlay: true` outlines the focused node with its label, region and size. Focus bugs on TV are invisible without it.

Everything is built on Flutter's own focus system (`FocusTraversalPolicy`, `Shortcuts`, `Actions`) — no key hijacking, full interop with plain `Focus` widgets, `TextField`s, and dialogs.

## Quick start

### 1. Add the dependency

```yaml
dependencies:
  dpad: ^3.0.0
```

### 2. Install the root (one line)

```dart
import 'package:dpad/dpad.dart';

MaterialApp(
  builder: Dpad.wrap(),   // covers every route, dialog and sheet
  home: const HomePage(),
)
```

### 3. Make things focusable

```dart
DpadFocusable(
  autofocus: true,
  onSelect: () => playMovie(movie),
  child: PosterCard(movie),
)
```

That's a working TV app: arrow keys / remote d-pad move focus with a scale-and-border effect (themable), center button calls `onSelect`, and the focused item auto-scrolls into view with padding for its glow.

## Regions: structure your screen like a TV app

```dart
Row(
  children: [
    // Sidebar: never lets focus fall off the top/bottom of the screen,
    // remembers the selected destination.
    DpadRegion(
      verticalEdge: DpadEdgeBehavior.stop,
      child: SidebarColumn(...),
    ),
    Expanded(
      child: ListView(
        children: [
          for (final row in rows)
            // Each poster row remembers its position. Down and back up
            // returns to the same poster — like every real TV app.
            DpadRegion(
              child: SizedBox(
                height: 200,
                child: ListView(scrollDirection: Axis.horizontal,
                    children: row.cards),
              ),
            ),
        ],
      ),
    ),
  ],
)
```

### Entering a region

`DpadRegion(enter: ...)` decides where focus lands when it crosses in:

| `DpadEnterBehavior` | Landing item |
|---|---|
| `restore` *(default)* | The last focused item; falls back to the position-nearest item, the `entry` item, then the geometric target |
| `entry` | The item marked `DpadFocusable(entry: true)` |
| `nearest` | The geometrically nearest item (plain Flutter behavior) |

### Leaving a region

Each direction independently chooses what happens at the boundary — set the
axis-wide `horizontalEdge` / `verticalEdge`, then override any single side
with `leftEdge` / `rightEdge` / `upEdge` / `downEdge`:

| `DpadEdgeBehavior` | Effect |
|---|---|
| `leave` *(default)* | Focus continues to the best target outside |
| `stop` | Key is consumed, focus stays, `onEdge` fires (bump animations, sounds) |
| `wrap` | Focus wraps to the opposite side — carousels |
| `lineWrap` | Focus steps to the next grid line: right past a row ends on the first cell of the row below (and back); at the grid's first/last line `onEdge` fires. Lazy grids scroll to reveal the next line. |

```dart
DpadRegion(
  horizontalEdge: DpadEdgeBehavior.wrap,   // an endless episode carousel
  onEdge: (direction) => playBumpSound(),
  onFocusChange: (inside) => setState(() => highlighted = inside),
  child: episodeRow,
)

// A grid: line-wrap rows, and never escape sideways.
DpadRegion(
  horizontalEdge: DpadEdgeBehavior.lineWrap,
  child: settingsGrid,
)

// A row that stops at its end but still lets users reach the nav rail.
DpadRegion(
  horizontalEdge: DpadEdgeBehavior.stop,
  leftEdge: DpadEdgeBehavior.leave,        // only the rail stays reachable
  child: row,
)
```

Direction names are *physical* — they name the remote's keys — so they mean
the same thing in RTL layouts. Reading-order-aware behavior (grid line wrap,
initial focus placement) resolves RTL automatically.

### Memory that survives rebuilds

State-based memory dies when a section switcher rebuilds its subtree — the
classic "tabs forget where I was" TV pitfall. Give the region a stable key
and the memory persists, position-aware, across any rebuild:

```dart
DpadRegion(
  memoryKey: 'home/trending-row',
  child: trendingRow,
)
```

## Focus effects

Effects are immutable, const-able, and composable — first effect in the list is the outermost wrapper:

```dart
DpadFocusable(
  effects: const [
    DpadScaleEffect(scale: 1.1),                // lift…
    DpadGlowEffect(color: Colors.amber),        // …and glow
  ],
  child: card,
)
```

Built-ins: `DpadScaleEffect` (with pressed-state push-down), `DpadBorderEffect` (layout-shift-free), `DpadGlowEffect`, `DpadElevationEffect`, `DpadOpacityEffect` (dim the rest), `DpadTintEffect`, `DpadCustomEffect`.

Set app-wide defaults once:

```dart
MaterialApp(
  builder: Dpad.wrap(
    theme: const DpadThemeData(
      effects: [DpadGlowEffect()],
      scrollPadding: 64,
    ),
  ),
)
```

Or take full control — including the **pressed** state of the select key:

```dart
DpadFocusable(
  onSelect: play,
  builder: (context, state, child) => AnimatedScale(
    scale: state.pressed ? 0.97 : (state.focused ? 1.06 : 1.0),
    duration: const Duration(milliseconds: 120),
    child: child,
  ),
  child: card,
)
```

## Remote interactions

```dart
DpadFocusable(
  onSelect: () => play(),                 // center button (or tap)
  onLongSelect: () => showOptionsSheet(), // held center button
  onFocusChange: (focused) => setState(() => hovered = focused),
  onDirection: (direction) {              // sliders: consume left/right
    if (direction == TraversalDirection.right) { volumeUp(); return true; }
    if (direction == TraversalDirection.left)  { volumeDown(); return true; }
    return false;                         // up/down keep navigating
  },
  child: volumeRow,
)
```

Back, menu, app-level shortcuts, sound feedback and the focus inspector
live on the root:

```dart
Dpad.wrap(
  onBack: () {                  // back key: pop, or confirm exit at home
    if (navigator.canPop()) { navigator.pop(); return true; }
    showExitDialog(); return true;
  },
  onMenu: () => showAboutDialog(),
  onFocusChange: (node) {       // the app-wide focus "tick" sound
    if (node != null) audio.playTick();
  },
  shortcuts: {
    LogicalKeyboardKey.keyS: () => openSearch(),
  },
  debugOverlay: kDebugMode,     // on-screen focus inspector
)
```

All of these — and directional navigation itself — automatically stand down while a `TextField` is focused, so typing is never hijacked.

Unusual remote? Remap any key group:

```dart
Dpad.wrap(
  keySet: const DpadKeySet().copyWith(
    select: [LogicalKeyboardKey.f1, ...DpadKeySet.defaultSelect],
  ),
)
```

## Programmatic control

```dart
final dpad = Dpad.of(context);

dpad.moveDown();                 // exactly like a remote key press
dpad.move(TraversalDirection.left);
dpad.select();                   // press the focused item
dpad.requestFocus(searchNode);   // jump focus (updates region memory)
dpad.ensureVisible();            // padded scroll-into-view
dpad.focused;                    // the currently focused node
```

## Best practices for TV

Distilled from the example app — follow these and a complex TV app stays
predictable:

1. **One `autofocus` per screen.** Give the primary action (`Play`, first
   card) `autofocus: true`. Everything else is handled: pushed routes,
   removed items and app resume keep focus alive automatically.
2. **One `DpadRegion` per visual section.** Sidebar, each shelf row, each
   grid. Region-first traversal and focus memory are what make navigation
   feel native.
3. **Use `memoryKey` on regions inside section switchers.** Plain state
   dies with the subtree; keyed memory survives any rebuild.
4. **Lay out shelves with the padding *inside* the scroll view.**

   ```dart
   SizedBox(
     height: cardHeight + 32,                    // headroom for effects
     child: ListView.builder(
       scrollDirection: Axis.horizontal,
       padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
       ...
     ),
   )
   ```

   Scaled and glowing focus effects paint into the padding instead of
   being clipped at the row edge.
5. **`stop` the edges of anchored panels, `wrap` carousels.** A sidebar
   should never let focus fall off the screen; an episode strip can loop.
6. **Wire actions through `onSelect`, not the child's `onPressed`.**
   `DpadFocusable` is the single focus stop; a wrapped Material button is
   just visuals.
7. **Don't fight text fields.** Leave `TextField`s bare (not wrapped in
   `DpadFocusable`); arrows edit text mid-string and navigate away at the
   edges automatically.
8. **Debug with `debugOverlay: true`.** Focus bugs are invisible on a TV
   across the room; the inspector shows the focused node, its region and
   geometry live.

## How it plays with Flutter

- `DpadTraversalPolicy` is a `FocusTraversalPolicy` — plain `Focus`/`ElevatedButton` widgets participate in navigation, dialogs trap focus through their own `FocusScope`, and popping a route restores focus to the item that opened it, all natively.
- `DpadFocusable` excludes its child's focus by default (`excludeChildFocus: true`) so wrapping a button never creates two d-pad stops. Set it to `false` when the child must own focus (e.g. a `TextField`).
- Tab order falls back to reading order.

## Example

The [example](https://github.com/fluttercandies/dpad/tree/main/example) is a complete TV streaming UI — expanding sidebar, poster rows with memory, wrap-around episode carousel, search with text input, settings with an `onDirection` volume slider, long-select context sheets, and an exit-confirmation back flow. Run it on a TV emulator or any desktop:

```bash
cd example
flutter run -d macos   # or windows, linux, an Android TV emulator…
```

## Platform support

| Platform | Input |
|---|---|
| Android TV / Google TV | Remote d-pad, game controllers |
| Amazon Fire TV | Fire TV remotes |
| Apple TV (via web/custom embedder) | Siri Remote arrows |
| Desktop (macOS/Windows/Linux) | Arrow keys — ideal for development |
| Web | Arrow keys (Dpad maps them even where Flutter doesn't) |

Requires Flutter `>= 3.24`.

## Migrating from 2.x

3.0 is a ground-up rewrite with a smaller, TV-first API. The old global history stack, rule tables and registration flags are replaced by declarative widgets:

| 2.x | 3.0 |
|---|---|
| `DpadNavigator(child: app)` | `MaterialApp(builder: Dpad.wrap())` |
| `Dpad.navigateUp(context)` | `Dpad.of(context).moveUp()` |
| `DpadFocusable(builder: (c, focused, child) ...)` | `builder: (c, state, child)` with `state.focused` / `state.pressed` |
| `FocusEffects.glow()` (closures) | `effects: const [DpadGlowEffect()]` (const classes) |
| `FocusMemoryOptions` + history stack | per-`DpadRegion` memory (`enter: DpadEnterBehavior.restore`, the default) |
| `RegionNavigationOptions` + `RegionNavigationRule` tables | `DpadRegion(enter: ..., horizontalEdge: ..., verticalEdge: ...)` |
| `DpadFocusable(region: 'tabs', isEntryPoint: true)` | wrap the tabs in a `DpadRegion`, mark one item `entry: true` |
| `customShortcuts:` | `shortcuts:` (now suspended during text editing) |
| `onBackPressed` / `onMenuPressed` | `onBack` (returns `bool`) / `onMenu` |

See the [CHANGELOG](https://github.com/fluttercandies/dpad/blob/main/CHANGELOG.md) for the full list.

## ❤️ Support

- 🌟 [Star on GitHub](https://github.com/fluttercandies/dpad)
- 👍 [Like on pub.dev](https://pub.dev/packages/dpad)
- 🐛 [Report issues](https://github.com/fluttercandies/dpad/issues)

---

**Make Flutter shine on the big screen!** 🚀📺✨
