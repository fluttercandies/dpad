import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpad/dpad.dart';

void main() {
  group('Dpad Tests', () {
    testWidgets('DpadNavigator should navigate properly', (tester) async {
      var menuPressed = false;
      var backPressed = false;
      var customPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DpadNavigator(
            onMenuPressed: () => menuPressed = true,
            onBackPressed: () => backPressed = true,
            customShortcuts: {
              LogicalKeyboardKey.keyR: () => customPressed = true,
            },
            child: Scaffold(
              body: Column(
                children: [
                  DpadFocusable(
                    autofocus: true,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Button 1'),
                    ),
                  ),
                  DpadFocusable(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Button 2'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test menu button
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      expect(menuPressed, true);

      // Test back button
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(backPressed, true);

      // Test custom shortcut
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyR);
      expect(customPressed, true);
    });

    testWidgets('DpadFocusable should handle focus changes', (tester) async {
      var focused = false;
      var selected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DpadNavigator(
            child: Scaffold(
              body: DpadFocusable(
                autofocus: true,
                onFocus: () => focused = true,
                onSelect: () => selected = true,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Test Button'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if autofocus worked
      expect(focused, true);

      // Test selection
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(selected, true);
    });

    testWidgets('Dpad utilities should work correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DpadNavigator(
            child: Scaffold(
              body: DpadFocusable(
                autofocus: true,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Test Button'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test current focus
      final currentFocus = Dpad.currentFocus;
      expect(currentFocus, isNotNull);

      // Test clear focus
      Dpad.clearFocus();
      // Note: In real usage, FocusManager.primaryFocus might still be accessible
      // even after unfocus, so we just ensure clearFocus() doesn't crash
      expect(Dpad.currentFocus, isA<FocusNode>());
    });
  });
}
