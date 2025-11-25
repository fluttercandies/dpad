import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_scaffold.dart';

/// Demo page for FocusEffects API
///
/// Demonstrates all built-in focus effects:
/// - FocusEffects.border()
/// - FocusEffects.glow()
/// - FocusEffects.scale()
/// - FocusEffects.gradient()
/// - FocusEffects.elevation()
/// - FocusEffects.scaleWithBorder()
/// - FocusEffects.opacity()
/// - FocusEffects.colorTint()
/// - FocusEffects.combine()
/// - Custom builder
class FocusEffectsDemo extends StatelessWidget {
  const FocusEffectsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Focus Effects',
      subtitle: 'Built-in and custom focus effects',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Built-in Effects
            _buildSectionTitle('Built-in Effects'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _EffectCard(
                  title: 'Border',
                  autofocus: true,
                  builder: FocusEffects.border(
                    focusColor: Colors.blue,
                    width: 3,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                _EffectCard(
                  title: 'Glow',
                  builder: FocusEffects.glow(
                    glowColor: Colors.purple,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ),
                _EffectCard(
                  title: 'Scale',
                  builder: FocusEffects.scale(
                    scale: 1.1,
                    duration: const Duration(milliseconds: 200),
                  ),
                ),
                _EffectCard(
                  title: 'Gradient',
                  builder: FocusEffects.gradient(
                    focusedColors: [Colors.orange, Colors.red],
                    unfocusedColors: [Colors.grey.shade800, Colors.grey.shade900],
                  ),
                ),
                _EffectCard(
                  title: 'Elevation',
                  builder: FocusEffects.elevation(
                    focusedElevation: 12,
                    unfocusedElevation: 2,
                    shadowColor: Colors.black54,
                  ),
                ),
                _EffectCard(
                  title: 'Scale + Border',
                  builder: FocusEffects.scaleWithBorder(
                    scale: 1.05,
                    borderColor: Colors.green,
                    borderWidth: 2,
                  ),
                ),
                _EffectCard(
                  title: 'Opacity',
                  builder: FocusEffects.opacity(
                    focusedOpacity: 1.0,
                    unfocusedOpacity: 0.5,
                  ),
                ),
                _EffectCard(
                  title: 'Color Tint',
                  builder: FocusEffects.colorTint(
                    focusedTint: Colors.cyan.withOpacity(0.3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Section: Combined Effects
            _buildSectionTitle('Combined Effects'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _EffectCard(
                  title: 'Scale + Glow',
                  builder: FocusEffects.combine([
                    FocusEffects.scale(scale: 1.08),
                    FocusEffects.glow(glowColor: Colors.blue, blurRadius: 15),
                  ]),
                ),
                _EffectCard(
                  title: 'Border + Elevation',
                  builder: FocusEffects.combine([
                    FocusEffects.border(focusColor: Colors.amber, width: 2),
                    FocusEffects.elevation(focusedElevation: 8),
                  ]),
                ),
                _EffectCard(
                  title: 'Triple Effect',
                  builder: FocusEffects.combine([
                    FocusEffects.scale(scale: 1.05),
                    FocusEffects.border(focusColor: Colors.pink),
                    FocusEffects.glow(glowColor: Colors.pink, blurRadius: 10),
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Section: Custom Effects
            _buildSectionTitle('Custom Effects'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                // Custom rotation effect
                _EffectCard(
                  title: 'Rotation',
                  builder: (context, isFocused, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.identity()
                        ..rotateZ(isFocused ? 0.05 : 0),
                      transformAlignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFocused ? Colors.teal : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: child,
                    );
                  },
                ),
                // Custom pulse effect
                _EffectCard(
                  title: 'Neon',
                  builder: (context, isFocused, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFocused ? Colors.greenAccent : Colors.grey,
                          width: isFocused ? 3 : 1,
                        ),
                        boxShadow: isFocused
                            ? [
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.8),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.4),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: child,
                    );
                  },
                ),
                // Custom underline effect
                _EffectCard(
                  title: 'Underline',
                  builder: (context, isFocused, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        child ?? const SizedBox(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 4,
                          width: isFocused ? 120 : 0,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Section: DpadFocusable Callbacks
            _buildSectionTitle('Focus Callbacks'),
            const SizedBox(height: 16),
            const _CallbackDemo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class _EffectCard extends StatelessWidget {
  final String title;
  final FocusEffectBuilder builder;
  final bool autofocus;

  const _EffectCard({
    required this.title,
    required this.builder,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      debugLabel: 'Effect: $title',
      builder: builder,
      child: Container(
        width: 140,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CallbackDemo extends StatefulWidget {
  const _CallbackDemo();

  @override
  State<_CallbackDemo> createState() => _CallbackDemoState();
}

class _CallbackDemoState extends State<_CallbackDemo> {
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)} $message');
      if (_logs.length > 10) _logs.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buttons
        Column(
          children: [
            for (int i = 1; i <= 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DpadFocusable(
                  debugLabel: 'Callback Button $i',
                  onFocus: () => _addLog('Button $i: onFocus'),
                  onBlur: () => _addLog('Button $i: onBlur'),
                  onSelect: () => _addLog('Button $i: onSelect'),
                  builder: FocusEffects.scaleWithBorder(
                    scale: 1.05,
                    borderColor: Colors.blue,
                  ),
                  child: Container(
                    width: 160,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Button $i',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 32),
        // Log output
        Expanded(
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event Log:',
                  style: TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Text(
                        _logs[index],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          fontSize: 12,
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
    );
  }
}
