import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

/// Demo page for Focus Memory API
///
/// Demonstrates:
/// - FocusMemoryOptions configuration
/// - FocusHistoryEntry usage
/// - Region-based history
/// - History restoration
/// - DpadNavigator.historyOf() / focusMemoryOf()
class FocusMemoryDemo extends StatefulWidget {
  const FocusMemoryDemo({super.key});

  @override
  State<FocusMemoryDemo> createState() => _FocusMemoryDemoState();
}

class _FocusMemoryDemoState extends State<FocusMemoryDemo> {
  String _currentTab = 'Tab 1';
  String _focusInfo = 'No focus';
  List<String> _historyLog = [];

  void _updateFocusInfo(String info) {
    setState(() {
      _focusInfo = info;
    });
  }

  void _logHistory(String action) {
    final history = DpadNavigator.historyOf(context);
    if (history != null) {
      final count = history.getHistory().length;
      setState(() {
        _historyLog.insert(0, '$action (History: $count items)');
        if (_historyLog.length > 8) _historyLog.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Focus Memory',
      subtitle: 'History tracking and restoration',
      child: Row(
        children: [
          // Left: Tab navigation demo
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Tabs
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      for (final tab in ['Tab 1', 'Tab 2', 'Tab 3'])
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: DpadFocusable(
                            autofocus: tab == 'Tab 1',
                            region: 'tabs',
                            debugLabel: tab,
                            onFocus: () {
                              _updateFocusInfo('Focused: $tab');
                              _logHistory('Focus $tab');
                            },
                            onSelect: () {
                              setState(() => _currentTab = tab);
                              _logHistory('Select $tab');
                            },
                            builder: FocusEffects.scaleWithBorder(
                              scale: 1.05,
                              borderColor: Colors.blue,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _currentTab == tab
                                    ? Colors.blue
                                    : Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tab,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Content grid
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_currentTab Content',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: 8,
                            itemBuilder: (context, index) {
                              final itemName =
                                  '$_currentTab Item ${index + 1}';
                              return DpadFocusable(
                                region: 'content-$_currentTab',
                                debugLabel: itemName,
                                isEntryPoint: index == 0,
                                onFocus: () {
                                  _updateFocusInfo('Focused: $itemName');
                                  _logHistory('Focus $itemName');
                                },
                                onSelect: () => _logHistory('Select $itemName'),
                                builder: FocusEffects.glow(
                                  glowColor: Colors.blue,
                                  blurRadius: 12,
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Item ${index + 1}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: Info panel
          Container(
            width: 300,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current focus
                const Text(
                  'Current Focus',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    _focusInfo,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                const SizedBox(height: 24),

                // History info
                const Text(
                  'Focus Memory Info',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Enabled', 'true'),
                _buildInfoRow('Max History', '50'),
                Builder(builder: (context) {
                  final history = DpadNavigator.historyOf(context);
                  final count = history?.getHistory().length ?? 0;
                  return _buildInfoRow('Current Count', '$count');
                }),

                const SizedBox(height: 24),

                // History log
                const Text(
                  'Event Log',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: _historyLog.length,
                      itemBuilder: (context, index) {
                        return Text(
                          _historyLog[index],
                          style: const TextStyle(
                            color: Colors.green,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Press Esc/Back to restore previous focus. '
                    'Navigate between tabs and items to build history.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
