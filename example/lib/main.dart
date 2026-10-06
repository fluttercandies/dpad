import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'pages/home_page.dart';
import 'styles.dart';
import 'widgets/tv_button.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() => runApp(const DpadTvApp());

class DpadTvApp extends StatelessWidget {
  const DpadTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dpad TV',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: kPageBackground,
        useMaterial3: true,
      ),
      // One builder installs TV navigation for every route, dialog and
      // sheet. (`Dpad.wrap()` does the same in one line — the explicit
      // widget is used here so the live settings toggles can reconfigure
      // the root without remounting the app.)
      builder: (context, child) {
        return AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            showFocusInspector,
            rtlLayout,
            dpadEnabled,
            wasdKeys,
          ]),
          builder: (context, _) {
            final rtl = rtlLayout.value;
            final wasd = wasdKeys.value;
            return Directionality(
              // The RTL demo: every route mirrors under the same direction
              // and the traversal engine adapts (initial focus, line wrap,
              // per-direction edges) — see Settings to toggle it live.
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Dpad(
                // Focus keys can be remapped wholesale: with WASD on,
                // W/A/S/D join the arrows as movement keys. While an
                // editable is being edited the remap stands down with
                // everything else, so typing stays safe.
                keySet: wasd
                    ? const DpadKeySet().copyWith(
                        up: <LogicalKeyboardKey>[
                          LogicalKeyboardKey.keyW,
                          ...DpadKeySet.defaultUp,
                        ],
                        left: <LogicalKeyboardKey>[
                          LogicalKeyboardKey.keyA,
                          ...DpadKeySet.defaultLeft,
                        ],
                        down: <LogicalKeyboardKey>[
                          LogicalKeyboardKey.keyS,
                          ...DpadKeySet.defaultDown,
                        ],
                        right: <LogicalKeyboardKey>[
                          LogicalKeyboardKey.keyD,
                          ...DpadKeySet.defaultRight,
                        ],
                      )
                    : const DpadKeySet(),
                // While off, focus freezes wherever it is (the playback
                // overlay pattern) — select keys still fire, so the
                // Settings toggle can switch it back on.
                enabled: dpadEnabled.value,
                // App-wide styling and timing defaults for every
                // DpadFocusable. The hold length of a long-select is
                // a theme knob too.
                theme: const DpadThemeData(
                  scrollPadding: 56,
                  longSelectDuration: Duration(milliseconds: 650),
                ),
                // Back behaves like a TV remote: pop whatever is open,
                // confirm before leaving the app from the home screen.
                onBack: _handleBack,
                // The menu key opens the help dialog.
                onMenu: _showAbout,
                // The classic focus "tick" on every move.
                onFocusChange: (node) {
                  if (node != null && clickSounds.value) {
                    SystemSound.play(SystemSoundType.click);
                  }
                },
                // App-level shortcuts (autosuspended while typing in
                // Search, and while a dialog or sheet is open). With WASD
                // movement on, S belongs to the d-pad, so its shortcut
                // stands down for the toggle's lifetime.
                shortcuts: <LogicalKeyboardKey, VoidCallback>{
                  LogicalKeyboardKey.keyH: () => _jumpToSection(0),
                  LogicalKeyboardKey.keyL: () => _jumpToSection(1),
                  if (!wasd) LogicalKeyboardKey.keyS: () => _jumpToSection(2),
                  LogicalKeyboardKey.keyI: () {
                    if (!_overlayOpen) {
                      showFocusInspector.value = !showFocusInspector.value;
                    }
                  },
                  LogicalKeyboardKey.f1: _showAbout,
                },
                // The built-in focus inspector, toggled from Settings.
                debugOverlay: showFocusInspector.value,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
      home: const HomePage(),
    );
  }

  /// True while a route (dialog, sheet or detail page) is stacked: app
  /// shortcuts stand down so overlays keep the remote to themselves.
  static bool get _overlayOpen => _navigatorKey.currentState?.canPop() ?? false;

  static void _jumpToSection(int index) {
    if (!_overlayOpen) {
      activeSection.value = index;
    }
  }

  static bool _handleBack() {
    final NavigatorState navigator = _navigatorKey.currentState!;
    if (navigator.canPop()) {
      navigator.pop();
      return true;
    }
    showDialog<void>(
      context: navigator.context,
      barrierColor: const Color(0xA6000000),
      builder: (context) => _TvDialog(
        icon: Icons.logout_rounded,
        title: 'Leave Dpad TV?',
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: const Text(
              'Dialogs trap d-pad focus automatically — try navigating outside.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xB3B4BBC2),
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ),
        actions: [
          Expanded(
            child: TvButton(
              label: 'Stay',
              autofocus: true,
              expanded: true,
              onSelect: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TvButton(
              label: 'Exit',
              quiet: true,
              expanded: true,
              onSelect: () {
                Navigator.pop(context);
                SystemNavigator.pop();
              },
            ),
          ),
        ],
      ),
    );
    return true;
  }

  static void _showAbout() {
    if (_overlayOpen) {
      return;
    }
    final BuildContext? context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xA6000000),
      builder: (context) => _TvDialog(
        icon: Icons.gamepad_rounded,
        title: 'Dpad TV demo',
        body: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const <int, TableColumnWidth>{
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(1.5),
            2: IntrinsicColumnWidth(),
            3: FlexColumnWidth(),
          },
          children: const <TableRow>[
            TableRow(
              children: <Widget>[
                _PaddedCell.bottom(child: _KeyHintCap('↑ ↓ ← →')),
                _PaddedCell.bottom(child: _KeyHintText('Move focus')),
                _PaddedCell.bottom(child: _KeyHintCap('Enter')),
                _PaddedCell.bottom(child: _KeyHintText('Select')),
              ],
            ),
            TableRow(
              children: <Widget>[
                _PaddedCell.bottom(child: _KeyHintCap('hold ⏎')),
                _PaddedCell.bottom(child: _KeyHintText('Options sheet')),
                _PaddedCell.bottom(child: _KeyHintCap('Esc')),
                _PaddedCell.bottom(child: _KeyHintText('Back')),
              ],
            ),
            TableRow(
              children: <Widget>[
                _KeyHintCap('H · L · S · I'),
                _KeyHintText('Sections · inspector'),
                _KeyHintCap('F1 · Menu'),
                _KeyHintText('This help'),
              ],
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 140,
            child: TvButton(
              label: 'Close',
              autofocus: true,
              expanded: true,
              onSelect: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// A dark, gradient-surfaced dialog in the app's TV style: icon badge,
/// centered title, body, one row of [TvButton] actions.
class _TvDialog extends StatelessWidget {
  const _TvDialog({
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 540,
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
        decoration: BoxDecoration(
          gradient: kSurfaceGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withAlpha(18)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x73000000),
              blurRadius: 48,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(46),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: scheme.primary.withAlpha(56)),
                ),
                child: Icon(icon, color: scheme.primary, size: 27),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 24),
            body,
            const SizedBox(height: 30),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

/// A keycap for the help grid: gradient surface, white stroke, centered.
class _KeyHintCap extends StatelessWidget {
  const _KeyHintCap(this.keys);

  final String keys;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A3140), Color(0xFF20262F)],
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withAlpha(28)),
      ),
      child: Text(
        keys,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// The description next to a help-grid keycap, single-line and readable at
/// TV distance.
class _KeyHintText extends StatelessWidget {
  const _KeyHintText(this.description);

  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 20),
      child: Text(
        description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white.withAlpha(158), fontSize: 13.5),
      ),
    );
  }
}

/// Vertical rhythm between help-grid rows.
class _PaddedCell extends StatelessWidget {
  const _PaddedCell.bottom({required this.child})
      : padding = const EdgeInsets.only(bottom: 12);

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}
