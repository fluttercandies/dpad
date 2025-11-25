# Dpad Example

Comprehensive example app demonstrating all features of the dpad package.

## Demo Pages

### 1. Focus Effects Demo (`/effects`)
- All built-in `FocusEffects` builders: border, glow, scale, gradient, elevation, opacity, colorTint
- Combined effects using `FocusEffects.combine()`
- Custom focus effect builders
- Focus callbacks: onFocus, onBlur, onSelect

### 2. Focus Memory Demo (`/memory`)
- `FocusMemoryOptions` configuration
- Focus history tracking
- Region-based history
- History restoration with Esc/Back

### 3. Region Navigation Demo (`/region`)
- `RegionNavigationOptions` and `RegionNavigationRule`
- Navigation strategies: geometric, fixedEntry, memory, custom
- Entry points with `isEntryPoint` and `entryPriority`
- Cross-region navigation rules

### 4. Programmatic Navigation Demo (`/programmatic`)
- `Dpad.navigateUp/Down/Left/Right()` - Directional navigation
- `Dpad.navigateNext/Previous()` - Sequential navigation  
- `Dpad.requestFocus()` / `Dpad.clearFocus()` - Focus management
- `Dpad.scrollToFocus()` - Scroll control
- `DpadNavigator.historyOf()` / `focusMemoryOf()` / `regionManagerOf()`

### 5. TV Interface Demo (`/tv`)
- Complete TV streaming app interface
- Multiple regions: sidebar, hero, content sections
- Focus memory with tab/content restoration
- Auto-scroll behavior
- Real-world layout patterns

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| ↑↓←→ | Navigate between focusable items |
| Enter/Space | Select current item |
| Esc | Go back / Restore previous focus |
| H | Home (main menu) |
| 1-5 | Quick jump to demo pages |

## Running

```bash
cd example
flutter run -d macos  # or linux, windows, chrome
```

For TV devices:
```bash
flutter run -d <device-id>  # Android TV, Fire TV, etc.
```
