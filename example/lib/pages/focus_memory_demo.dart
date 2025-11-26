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
/// - **Tabs → Content → Tabs navigation with memory strategy**
///
/// Expected behavior:
/// - Tabs → Content (↓): Always focus the first card (fixedEntry)
/// - Content → Tabs (↑): Return to previously focused Tab (memory)
class FocusMemoryDemo extends StatefulWidget {
  const FocusMemoryDemo({super.key});

  @override
  State<FocusMemoryDemo> createState() => _FocusMemoryDemoState();
}

class _FocusMemoryDemoState extends State<FocusMemoryDemo> {
  int _currentTabIndex = 0;
  String _focusInfo = 'No focus';
  List<String> _historyLog = [];

  // Tab labels
  static const List<String> _tabs = [
    'Tab 1',
    'Tab 2',
    'Tab 3',
    'Tab 4',
    'Tab 5',
    'Tab 6',
    'Tab 7',
    'Tab 8',
    'Tab 9',
    'Tab 10',
  ];

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
    // Wrap with DpadNavigator to configure region navigation rules
    return DpadNavigator(
      enabled: true,
      focusMemory: const FocusMemoryOptions(
        enabled: true,
        maxHistory: 50,
      ),
      regionNavigation: const RegionNavigationOptions(
        enabled: true,
        rules: [
          // Tabs → Content: always focus the first card (fixedEntry)
          RegionNavigationRule(
            fromRegion: 'tabs',
            toRegion: 'content',
            direction: TraversalDirection.down,
            strategy: RegionNavigationStrategy.fixedEntry,
          ),
          // Content → Tabs: return to previously focused Tab (memory)
          RegionNavigationRule(
            fromRegion: 'content',
            toRegion: 'tabs',
            direction: TraversalDirection.up,
            strategy: RegionNavigationStrategy.memory,
          ),
        ],
      ),
      onBackPressed: () => Navigator.of(context).pop(),
      child: DemoScaffold(
        title: 'Focus Memory',
        subtitle: 'History tracking and restoration (10 Tabs demo)',
        child: Row(
          children: [
            // Left: Tab navigation demo
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Tabs - scrollable row with 10 tabs
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < _tabs.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: DpadFocusable(
                                region: 'tabs',
                                debugLabel: _tabs[i],
                                isEntryPoint: i == 0,
                                autoScroll: true,
                                onFocus: () {
                                  _updateFocusInfo('Focused: ${_tabs[i]}');
                                  _logHistory('Focus ${_tabs[i]}');
                                },
                                onSelect: () {
                                  setState(() => _currentTabIndex = i);
                                  _logHistory('Select ${_tabs[i]}');
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
                                    color: _currentTabIndex == i
                                        ? Colors.blue
                                        : Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _tabs[i],
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
                  ),

                  // Content grid - unified 'content' region for proper region navigation
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
                          Row(
                            children: [
                              Text(
                                '${_tabs[_currentTabIndex]} Content',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Tabs↓Content: fixedEntry | Content↑Tabs: memory',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: GridView.builder(
                              // Ensure entry point card is built even if off-screen
                              cacheExtent: 500,
                              padding: const EdgeInsets.all(12.0),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.5,
                              ),
                              itemCount: 24,
                              itemBuilder: (context, index) {
                                final itemName = 'Card ${index + 1}';
                                return DpadFocusable(
                                  // Use unified 'content' region for proper region navigation
                                  region: 'content',
                                  debugLabel: itemName,
                                  isEntryPoint: index == 0,
                                  onFocus: () {
                                    _updateFocusInfo('Focused: $itemName');
                                    _logHistory('Focus $itemName');
                                  },
                                  onSelect: () =>
                                      _logHistory('Select $itemName'),
                                  builder: FocusEffects.glow(
                                    glowColor: Colors.blue,
                                    blurRadius: 12,
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(8),
                                      border: index == 0
                                          ? Border.all(
                                              color:
                                                  Colors.blue.withOpacity(0.5),
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          itemName,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        if (index == 0)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Entry',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                              ),
                                            ),
                                          ),
                                      ],
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
                      'Test: Focus Tab 9 → Press ↓ → Focus Card 4 → Press ↑\n'
                      'Expected: Returns to Tab 9 (memory strategy)',
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
