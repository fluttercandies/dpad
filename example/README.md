# Dpad TV — example app

A complete, remote-drivable TV streaming UI built with the
[`dpad`](https://pub.dev/packages/dpad) package.

## What it demonstrates

| Feature | Where |
|---|---|
| Root install through `MaterialApp.builder` (explicit `Dpad`; `Dpad.wrap()` is the 1-line variant) | `lib/main.dart` |
| App-wide `DpadThemeData` defaults | `lib/main.dart` |
| Back key flow (pop → exit confirmation dialog) | `lib/main.dart` |
| Menu key / F1 → help dialog | `lib/main.dart` |
| App shortcuts `H` / `L` / `S` (suspended while typing) | `lib/main.dart` |
| Focus "tick" sound via `Dpad.onFocusChange` | `lib/main.dart` |
| Focus inspector (`Dpad.debugOverlay`), toggled live from Settings | `lib/main.dart` + settings |
| Expanding navigation rail (`DpadRegion.onFocusChange`, `verticalEdge: stop`) | `lib/widgets/sidebar.dart` |
| Edge "bump" feedback (`DpadRegion.onEdge`) | `lib/widgets/sidebar.dart` |
| Section switching on focus + dive-in via `Dpad.of(context).moveRight()` | `lib/widgets/sidebar.dart` |
| Poster rows with focus memory that survives section switches (`memoryKey`) | `lib/sections/for_you_section.dart` |
| Clip-safe shelf layout (padding inside the row's `ListView`) | `lib/sections/for_you_section.dart` |
| Region entry items (`entry: true`) and `DpadEnterBehavior.entry` | `lib/sections/for_you_section.dart` |
| Per-item effect overrides | `lib/sections/for_you_section.dart` |
| Grid navigation with auto-scroll | `lib/sections/library_section.dart` |
| Text input coexistence (caret vs. navigation, never trapped) | `lib/sections/search_section.dart` |
| `DpadTheme` subtree override (one style for all rows) | `lib/sections/settings_section.dart` |
| Disabled items skipped by navigation (`enabled: false`) | `lib/sections/settings_section.dart` |
| `onDirection` volume slider (consumes left/right) | `lib/sections/settings_section.dart` |
| Programmatic focus (`Dpad.of(context).requestFocus` + external `focusNode`) | `lib/sections/settings_section.dart` |
| Live focus-effect gallery incl. `DpadCustomEffect`, wrap + `enter: nearest` chips | `lib/sections/settings_section.dart` |
| Flying highlight — 15-look catalog cycled from Settings, scoped styles per section (`DpadHighlightTheme`) | `lib/highlight_styles.dart` + settings |
| Blocked-move readout (`Dpad.onBlockedMove`) | `lib/sections/settings_section.dart` |
| Centered reveal toggle (`scrollAlignment: DpadRevealAlignment.center`) | `lib/sections/settings_section.dart` |
| Freezing navigation (`Dpad.enabled`, the playback-overlay pattern) | `lib/sections/settings_section.dart` |
| Right-to-left mirroring (RTL traversal + layout) | `lib/sections/settings_section.dart` |
| WASD movement via `DpadKeySet` remap | `lib/sections/settings_section.dart` |
| Long-select context sheet (`onLongSelect`) | `lib/widgets/poster_card.dart` |
| Fully custom presentation with pressed state (`builder`) | `lib/widgets/tv_button.dart` |
| Wrap-around episode carousel (`horizontalEdge: wrap`) | `lib/pages/detail_page.dart` |
| Focus restoration after popping a route | select any poster, press back |

## Controls

| Key | Action |
|-----|--------|
| ↑ ↓ ← → / d-pad | Move focus |
| Enter / Select / Space | Select |
| Hold select on a poster | Context menu |
| Esc / Back | Back (exit dialog on the home screen) |
| Menu / F1 | Help dialog |
| H / L / S | Jump to For you / Library / Search |
| I | Toggle the focus inspector |

Note: with WASD movement enabled, the `S` jump-to-Search shortcut stands
down (see `main.dart`) so the key can move focus down.

## Running

Building in this repository needs Flutter 3.32+ (the dev tooling only
resolves there — the package itself supports 3.19+).

```bash
cd example
flutter run -d macos     # or windows, linux, chrome
flutter run -d <tv-id>   # Android TV / Fire TV device or emulator
```
