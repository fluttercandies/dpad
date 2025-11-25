import 'dart:ui';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/focus_effects_demo.dart';
import 'pages/focus_memory_demo.dart';
import 'pages/programmatic_navigation_demo.dart';
import 'pages/region_navigation_demo.dart';
import 'pages/tv_interface_demo.dart';

/// Dpad Example App - Comprehensive API Demo
///
/// This example demonstrates all features of the dpad package:
///
/// 1. **DpadNavigator** - Root navigation container
///    - `enabled` - Enable/disable navigation
///    - `customShortcuts` - Custom keyboard bindings
///    - `focusMemory` - Focus history management
///    - `regionNavigation` - Region-based navigation
///    - `onNavigateBack` - Custom back navigation
///    - `onMenuPressed` / `onBackPressed` - Platform callbacks
///
/// 2. **DpadFocusable** - Focus wrapper widget
///    - `autofocus` - Initial focus
///    - `onFocus` / `onBlur` / `onSelect` - Focus callbacks
///    - `builder` - Custom focus effects
///    - `region` - Region identifier
///    - `isEntryPoint` / `entryPriority` - Region entry points
///    - `autoScroll` / `scrollPadding` - Auto-scroll behavior
///
/// 3. **FocusEffects** - Built-in focus effects
///    - `border()` / `glow()` / `scale()` / `gradient()`
///    - `elevation()` / `scaleWithBorder()` / `opacity()` / `colorTint()`
///    - `combine()` - Combine multiple effects
///
/// 4. **RegionNavigation** - Cross-region navigation
///    - `RegionNavigationStrategy` - geometric/fixedEntry/memory/custom
///    - `RegionNavigationRule` - Navigation rules
///    - `RegionAwareFocusTraversalPolicy` - Flutter system API
///
/// 5. **Dpad** - Utility class
///    - `navigateUp/Down/Left/Right()` - Directional navigation
///    - `navigateNext/Previous()` - Sequential navigation
///    - `requestFocus()` / `clearFocus()` - Focus management
///    - `scrollToFocus()` - Scroll control
void main() {
  runApp(const DpadExampleApp());
}

class DpadExampleApp extends StatefulWidget {
  const DpadExampleApp({super.key});

  @override
  State<DpadExampleApp> createState() => _DpadExampleAppState();
}

class _DpadExampleAppState extends State<DpadExampleApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return DpadNavigator(
      enabled: true,
      focusMemory: const FocusMemoryOptions(
        enabled: true,
        maxHistory: 50,
      ),
      onNavigateBack: (context, previousEntry, history) {
        // Try to restore previous focus
        if (previousEntry != null && previousEntry.requestFocusSafely()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (previousEntry.isValid) {
              Dpad.scrollToFocus(previousEntry.focusNode);
            }
          });
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onBackPressed: () {
        // Handle system back
        if (_navigatorKey.currentState?.canPop() == true) {
          _navigatorKey.currentState?.pop();
        }
      },
      onMenuPressed: () {
        debugPrint('Menu pressed - show app menu');
      },
      customShortcuts: {
        LogicalKeyboardKey.keyH: () {
          _navigatorKey.currentState?.pushReplacementNamed('/');
        },
        LogicalKeyboardKey.digit1: () {
          _navigatorKey.currentState?.pushNamed('/effects');
        },
        LogicalKeyboardKey.digit2: () {
          _navigatorKey.currentState?.pushNamed('/memory');
        },
        LogicalKeyboardKey.digit3: () {
          _navigatorKey.currentState?.pushNamed('/region');
        },
        LogicalKeyboardKey.digit4: () {
          _navigatorKey.currentState?.pushNamed('/programmatic');
        },
        LogicalKeyboardKey.digit5: () {
          _navigatorKey.currentState?.pushNamed('/tv');
        },
      },
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Dpad Example',
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          primaryColor: const Color(0xFF007BFF),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF007BFF),
            secondary: Color(0xFF6C757D),
          ),
        ),
        scrollBehavior: const ScrollBehavior().copyWith(
          dragDevices: PointerDeviceKind.values.toSet(),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/effects': (context) => const FocusEffectsDemo(),
          '/memory': (context) => const FocusMemoryDemo(),
          '/region': (context) => const RegionNavigationDemo(),
          '/programmatic': (context) => const ProgrammaticNavigationDemo(),
          '/tv': (context) => const TVInterfaceDemo(),
        },
      ),
    );
  }
}

/// Home page with navigation to all demo pages
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Text(
              '📺 Dpad Example',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Flutter TV Navigation System',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 48),

            // Navigation buttons
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                _MenuButton(
                  title: '1. Focus Effects',
                  subtitle: 'Built-in & custom effects',
                  icon: Icons.auto_awesome,
                  color: Colors.purple,
                  autofocus: true,
                  onSelect: () => Navigator.pushNamed(context, '/effects'),
                ),
                _MenuButton(
                  title: '2. Focus Memory',
                  subtitle: 'History & restoration',
                  icon: Icons.history,
                  color: Colors.orange,
                  onSelect: () => Navigator.pushNamed(context, '/memory'),
                ),
                _MenuButton(
                  title: '3. Region Navigation',
                  subtitle: 'Cross-region rules',
                  icon: Icons.grid_view,
                  color: Colors.green,
                  onSelect: () => Navigator.pushNamed(context, '/region'),
                ),
                _MenuButton(
                  title: '4. Programmatic',
                  subtitle: 'API navigation',
                  icon: Icons.code,
                  color: Colors.blue,
                  onSelect: () => Navigator.pushNamed(context, '/programmatic'),
                ),
                _MenuButton(
                  title: '5. TV Interface',
                  subtitle: 'Full demo',
                  icon: Icons.tv,
                  color: Colors.red,
                  onSelect: () => Navigator.pushNamed(context, '/tv'),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Keyboard hints
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    'Keyboard Shortcuts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '↑↓←→ Navigate  •  Enter Select  •  Esc Back  •  H Home  •  1-5 Quick Jump',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onSelect;
  final bool autofocus;

  const _MenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onSelect,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      onSelect: onSelect,
      builder: (context, isFocused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          height: 160,
          transform: Matrix4.identity()..scale(isFocused ? 1.05 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFocused ? color : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: isFocused ? Colors.white : color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isFocused ? Colors.white : Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isFocused ? Colors.white70 : Colors.white38,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
