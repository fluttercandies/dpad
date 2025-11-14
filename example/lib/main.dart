import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dpad/dpad.dart';

void main() {
  runApp(
    DpadNavigator(
      enabled: true,
      customShortcuts: {
        // Add custom shortcuts for sequential navigation demo
        LogicalKeyboardKey.keyN: () => debugPrint('Next button pressed'),
        LogicalKeyboardKey.keyP: () => debugPrint('Previous button pressed'),
      },
      child: MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const SimpleDpad(),
      ),
    ),
  );
}

class SimpleDpad extends StatelessWidget {
  const SimpleDpad({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text(
              'DPad Navigation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.0,
                children: [
                  _buildItem('Grid', Icons.grid_view, Colors.blue),
                  _buildItem('List', Icons.list, Colors.green),
                  _buildItem('Settings', Icons.settings, Colors.orange),
                  _buildItem('Profile', Icons.person, Colors.purple),
                  _buildItem('Games', Icons.sports_esports, Colors.red),
                  _buildItem('More', Icons.more_horiz, Colors.cyan),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Dpad.navigatePrevious(context);
                  },
                  child: const Text('Previous\n(Tab+Shift)'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Dpad.navigateNext(context);
                  },
                  child: const Text('Next\n(Tab)'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Use arrow keys to navigate, Enter to select\nTab/Shift+Tab for sequential navigation',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String title, IconData icon, Color color) {
    return DpadFocusable(
      debugLabel: title,
      autofocus: title == 'Grid',
      onFocus: () => debugPrint('$title focused'),
      onSelect: () => debugPrint('$title selected'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          border: Border.all(
            color: Colors.grey[600]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      builder: (context, isFocused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isFocused ? color : Colors.grey[800],
            border: Border.all(
              color: isFocused ? color : Colors.grey[600]!,
              width: isFocused ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        );
      },
    );
  }
}
