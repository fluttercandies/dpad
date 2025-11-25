import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

/// Demo page for Programmatic Navigation API
///
/// Demonstrates:
/// - Dpad.navigateUp/Down/Left/Right()
/// - Dpad.navigateNext/Previous()
/// - Dpad.requestFocus()
/// - Dpad.clearFocus()
/// - Dpad.currentFocus
/// - Dpad.scrollToFocus()
/// - DpadNavigator.historyOf()
/// - DpadNavigator.regionManagerOf()
class ProgrammaticNavigationDemo extends StatefulWidget {
  const ProgrammaticNavigationDemo({super.key});

  @override
  State<ProgrammaticNavigationDemo> createState() =>
      _ProgrammaticNavigationDemoState();
}

class _ProgrammaticNavigationDemoState
    extends State<ProgrammaticNavigationDemo> {
  final List<FocusNode> _focusNodes = [];
  String _currentFocusLabel = 'None';
  final List<String> _actionLog = [];

  @override
  void initState() {
    super.initState();
    // Create focus nodes for the grid
    for (int i = 0; i < 9; i++) {
      _focusNodes.add(FocusNode(debugLabel: 'Grid ${i + 1}'));
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _log(String action) {
    setState(() {
      _actionLog.insert(0, action);
      if (_actionLog.length > 10) _actionLog.removeLast();
    });
  }

  void _updateCurrentFocus() {
    final current = Dpad.currentFocus;
    setState(() {
      _currentFocusLabel = current?.debugLabel ?? 'None';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Programmatic Navigation',
      subtitle: 'Dpad utility class API',
      child: Row(
        children: [
          // Left: Control panel
          Container(
            width: 280,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Directional Navigation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDirectionalPad(),

                const SizedBox(height: 24),

                const Text(
                  'Sequential Navigation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ApiButton(
                        label: '← Previous',
                        onPressed: () {
                          Dpad.navigatePrevious(context);
                          _log('navigatePrevious()');
                          _updateCurrentFocus();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ApiButton(
                        label: 'Next →',
                        onPressed: () {
                          Dpad.navigateNext(context);
                          _log('navigateNext()');
                          _updateCurrentFocus();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Focus Management',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _ApiButton(
                  label: 'Focus Grid 5 (center)',
                  onPressed: () {
                    if (_focusNodes.length > 4) {
                      Dpad.requestFocus(_focusNodes[4]);
                      _log('requestFocus(Grid 5)');
                      _updateCurrentFocus();
                    }
                  },
                ),
                const SizedBox(height: 8),
                _ApiButton(
                  label: 'Clear Focus',
                  onPressed: () {
                    Dpad.clearFocus();
                    _log('clearFocus()');
                    _updateCurrentFocus();
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Scroll Control',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _ApiButton(
                  label: 'Scroll to Current Focus',
                  onPressed: () {
                    final current = Dpad.currentFocus;
                    if (current != null) {
                      Dpad.scrollToFocus(current, padding: 50);
                      _log('scrollToFocus(padding: 50)');
                    }
                  },
                ),

                const Spacer(),

                // Current focus display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dpad.currentFocus:',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _currentFocusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Center: Focus grid
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
                  const Text(
                    'Focus Grid',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use API buttons to navigate programmatically',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        return Focus(
                          focusNode: _focusNodes[index],
                          onFocusChange: (hasFocus) {
                            if (hasFocus) {
                              _updateCurrentFocus();
                            }
                          },
                          child: Builder(
                            builder: (context) {
                              final hasFocus = Focus.of(context).hasFocus;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..scale(hasFocus ? 1.05 : 1.0),
                                transformAlignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: hasFocus
                                      ? Colors.blue
                                      : Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(16),
                                  border: hasFocus
                                      ? Border.all(
                                          color: Colors.white, width: 3)
                                      : null,
                                  boxShadow: hasFocus
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.blue.withOpacity(0.5),
                                            blurRadius: 20,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: hasFocus
                                            ? Colors.white
                                            : Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Grid ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: hasFocus
                                            ? Colors.white70
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Action log
          Container(
            width: 280,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Action Log',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: _actionLog.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '> ${_actionLog[index]}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Navigator info
                const Text(
                  'Navigator APIs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _ApiButton(
                  label: 'Get History Manager',
                  onPressed: () {
                    final history = DpadNavigator.historyOf(context);
                    if (history != null) {
                      final count = history.getHistory().length;
                      _log('historyOf() → $count entries');
                    } else {
                      _log('historyOf() → null');
                    }
                  },
                ),
                const SizedBox(height: 8),
                _ApiButton(
                  label: 'Get Region Manager',
                  onPressed: () {
                    final manager = DpadNavigator.regionManagerOf(context);
                    if (manager != null) {
                      _log('regionManagerOf() → found');
                    } else {
                      _log('regionManagerOf() → null');
                    }
                  },
                ),
                const SizedBox(height: 8),
                _ApiButton(
                  label: 'Get Focus Memory',
                  onPressed: () {
                    final memory = DpadNavigator.focusMemoryOf(context);
                    if (memory != null) {
                      _log('focusMemoryOf() → enabled: ${memory.enabled}');
                    } else {
                      _log('focusMemoryOf() → null');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionalPad() {
    return Column(
      children: [
        _ApiButton(
          label: '↑ Up',
          onPressed: () {
            Dpad.navigateUp(context);
            _log('navigateUp()');
            _updateCurrentFocus();
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ApiButton(
                label: '← Left',
                onPressed: () {
                  Dpad.navigateLeft(context);
                  _log('navigateLeft()');
                  _updateCurrentFocus();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ApiButton(
                label: 'Right →',
                onPressed: () {
                  Dpad.navigateRight(context);
                  _log('navigateRight()');
                  _updateCurrentFocus();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ApiButton(
          label: '↓ Down',
          onPressed: () {
            Dpad.navigateDown(context);
            _log('navigateDown()');
            _updateCurrentFocus();
          },
        ),
      ],
    );
  }
}

class _ApiButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ApiButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      onSelect: onPressed,
      builder: FocusEffects.border(
        focusColor: Colors.cyan,
        width: 2,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
