import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

/// Demo page for Region Navigation API
///
/// Demonstrates:
/// - RegionNavigationOptions
/// - RegionNavigationRule
/// - RegionNavigationStrategy (geometric, fixedEntry, memory, custom)
/// - isEntryPoint / entryPriority
/// - Bidirectional rules
class RegionNavigationDemo extends StatelessWidget {
  const RegionNavigationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // This demo uses its own DpadNavigator with region rules
    return DpadNavigator(
      enabled: true,
      focusMemory: const FocusMemoryOptions(enabled: true),
      regionNavigation: RegionNavigationOptions(
        enabled: true,
        rules: [
          // Sidebar → Content: fixedEntry (always first card)
          const RegionNavigationRule(
            fromRegion: 'sidebar',
            toRegion: 'content',
            direction: TraversalDirection.right,
            strategy: RegionNavigationStrategy.fixedEntry,
          ),
          // Content → Sidebar: memory (restore last)
          const RegionNavigationRule(
            fromRegion: 'content',
            toRegion: 'sidebar',
            direction: TraversalDirection.left,
            strategy: RegionNavigationStrategy.memory,
          ),
          // Tabs → Content: fixedEntry
          const RegionNavigationRule(
            fromRegion: 'tabs',
            toRegion: 'content',
            direction: TraversalDirection.down,
            strategy: RegionNavigationStrategy.fixedEntry,
          ),
          // Content → Tabs: memory
          const RegionNavigationRule(
            fromRegion: 'content',
            toRegion: 'tabs',
            direction: TraversalDirection.up,
            strategy: RegionNavigationStrategy.memory,
          ),
          // Sidebar → Tabs: geometric (default)
          const RegionNavigationRule(
            fromRegion: 'sidebar',
            toRegion: 'tabs',
            direction: TraversalDirection.up,
            strategy: RegionNavigationStrategy.geometric,
          ),
          // Custom strategy example
          RegionNavigationRule(
            fromRegion: 'content',
            toRegion: 'footer',
            direction: TraversalDirection.down,
            strategy: RegionNavigationStrategy.custom,
            resolver: (fromNode, toRegion, direction, candidates) {
              // Custom: always pick the middle button
              if (candidates.isEmpty) return null;
              return candidates[candidates.length ~/ 2];
            },
          ),
        ],
      ),
      onBackPressed: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade900,
              child: Row(
                children: [
                  DpadFocusable(
                    autofocus: true,
                    onSelect: () => Navigator.of(context).pop(),
                    builder: FocusEffects.border(focusColor: Colors.blue),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Region Navigation Demo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Region rules enabled',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs region - 10 tabs to demonstrate memory strategy
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildLabel('Tabs Region', Colors.purple),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 1; i <= 10; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _TabButton(index: i),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const _StrategyInfo(
                    from: 'Tabs',
                    to: 'Content',
                    strategy: 'fixedEntry',
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Row(
                children: [
                  // Sidebar region
                  Container(
                    width: 200,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Sidebar Region', Colors.orange),
                        const SizedBox(height: 16),
                        for (int i = 1; i <= 5; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SidebarItem(index: i),
                          ),
                        const Spacer(),
                        const _StrategyInfo(
                          from: 'Sidebar',
                          to: 'Content',
                          strategy: 'fixedEntry',
                        ),
                      ],
                    ),
                  ),

                  // Content region
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
                              _buildLabel('Content Region', Colors.blue),
                              const Spacer(),
                              const _StrategyInfo(
                                from: 'Content',
                                to: 'Sidebar',
                                strategy: 'memory',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: FocusTraversalGroup(
                              child: GridView.builder(
                                // Ensure entry point card is built even if off-screen
                                cacheExtent: 500,
                                padding: const EdgeInsets.all(8),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 200,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                                itemCount: 24,
                                itemBuilder: (context, index) {
                                  return _ContentCard(
                                    index: index,
                                    isEntryPoint: index == 0,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer region
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
              ),
              child: Row(
                children: [
                  _buildLabel('Footer Region', Colors.teal),
                  const SizedBox(width: 16),
                  for (int i = 1; i <= 5; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _FooterButton(index: i),
                    ),
                  const Spacer(),
                  const _StrategyInfo(
                    from: 'Content',
                    to: 'Footer',
                    strategy: 'custom (middle)',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final int index;

  const _TabButton({required this.index});

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      region: 'tabs',
      debugLabel: 'Tab $index',
      isEntryPoint: index == 1,
      autoScroll: true,
      builder: FocusEffects.scaleWithBorder(
        scale: 1.05,
        borderColor: Colors.purple,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Tab $index',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final int index;

  const _SidebarItem({required this.index});

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      region: 'sidebar',
      debugLabel: 'Sidebar $index',
      isEntryPoint: index == 1,
      builder: FocusEffects.border(focusColor: Colors.orange),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Menu $index',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final int index;
  final bool isEntryPoint;

  const _ContentCard({
    required this.index,
    required this.isEntryPoint,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      region: 'content',
      debugLabel: 'Content ${index + 1}',
      isEntryPoint: isEntryPoint,
      entryPriority: isEntryPoint ? 10 : 0,
      builder: FocusEffects.glow(
        glowColor: Colors.blue,
        blurRadius: 15,
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          border: isEntryPoint
              ? Border.all(color: Colors.blue.withOpacity(0.5), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Card ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isEntryPoint)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Entry Point',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final int index;

  const _FooterButton({required this.index});

  @override
  Widget build(BuildContext context) {
    final isMiddle = index == 3; // Middle button for custom strategy

    return DpadFocusable(
      region: 'footer',
      debugLabel: 'Footer $index',
      builder: FocusEffects.border(focusColor: Colors.teal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isMiddle ? Colors.teal.withOpacity(0.3) : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
          border: isMiddle ? Border.all(color: Colors.teal) : null,
        ),
        child: Text(
          isMiddle ? 'Target' : 'Button $index',
          style: TextStyle(
            color: isMiddle ? Colors.teal : Colors.white,
            fontWeight: isMiddle ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _StrategyInfo extends StatelessWidget {
  final String from;
  final String to;
  final String strategy;

  const _StrategyInfo({
    required this.from,
    required this.to,
    required this.strategy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$from → $to: $strategy',
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
