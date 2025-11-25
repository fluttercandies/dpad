import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

/// Common scaffold for demo pages
class DemoScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const DemoScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade800,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Back button
                DpadFocusable(
                  autofocus: true,
                  debugLabel: 'Back Button',
                  onSelect: () => Navigator.of(context).pop(),
                  builder: FocusEffects.border(
                    focusColor: Colors.blue,
                    width: 2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Home button
                DpadFocusable(
                  debugLabel: 'Home Button',
                  onSelect: () =>
                      Navigator.of(context).pushReplacementNamed('/'),
                  builder: FocusEffects.border(
                    focusColor: Colors.green,
                    width: 2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Home',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}
