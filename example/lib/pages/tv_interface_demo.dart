import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

/// Full TV Interface Demo
///
/// A complete TV streaming app interface demonstrating all dpad features:
/// - Region-based navigation (sidebar, hero, content sections)
/// - Focus memory (tab/content restoration)
/// - Auto-scroll
/// - Focus effects
/// - Entry points
class TVInterfaceDemo extends StatefulWidget {
  const TVInterfaceDemo({super.key});

  @override
  State<TVInterfaceDemo> createState() => _TVInterfaceDemoState();
}

class _TVInterfaceDemoState extends State<TVInterfaceDemo> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DpadNavigator(
      enabled: true,
      focusMemory: const FocusMemoryOptions(
        enabled: true,
        maxHistory: 20,
      ),
      regionNavigation: const RegionNavigationOptions(
        enabled: true,
        rules: [
          // Sidebar → Hero
          RegionNavigationRule(
            fromRegion: 'sidebar',
            toRegion: 'hero',
            direction: TraversalDirection.right,
            strategy: RegionNavigationStrategy.fixedEntry,
          ),
          // Hero → Sidebar
          RegionNavigationRule(
            fromRegion: 'hero',
            toRegion: 'sidebar',
            direction: TraversalDirection.left,
            strategy: RegionNavigationStrategy.memory,
          ),
          // Hero → Continue
          RegionNavigationRule(
            fromRegion: 'hero',
            toRegion: 'continue',
            direction: TraversalDirection.down,
            strategy: RegionNavigationStrategy.fixedEntry,
          ),
          // Continue → Hero
          RegionNavigationRule(
            fromRegion: 'continue',
            toRegion: 'hero',
            direction: TraversalDirection.up,
            strategy: RegionNavigationStrategy.memory,
          ),
          // Continue → Recommended
          RegionNavigationRule(
            fromRegion: 'continue',
            toRegion: 'recommended',
            direction: TraversalDirection.down,
            strategy: RegionNavigationStrategy.fixedEntry,
          ),
          // Recommended → Continue
          RegionNavigationRule(
            fromRegion: 'recommended',
            toRegion: 'continue',
            direction: TraversalDirection.up,
            strategy: RegionNavigationStrategy.memory,
          ),
          // Content → Sidebar
          RegionNavigationRule(
            fromRegion: 'continue',
            toRegion: 'sidebar',
            direction: TraversalDirection.left,
            strategy: RegionNavigationStrategy.memory,
          ),
          RegionNavigationRule(
            fromRegion: 'recommended',
            toRegion: 'sidebar',
            direction: TraversalDirection.left,
            strategy: RegionNavigationStrategy.memory,
          ),
        ],
      ),
      onBackPressed: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: const Color(0xFF090909),
        body: Row(
          children: [
            // Sidebar
            _buildSidebar(),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroBanner(),
                    const SizedBox(height: 32),
                    _buildSection('Continue Watching', 'continue', _continueItems),
                    const SizedBox(height: 32),
                    _buildSection('Recommended', 'recommended', _recommendedItems),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final items = [
      ('Home', Icons.home),
      ('Movies', Icons.movie),
      ('Shows', Icons.tv),
      ('Music', Icons.music_note),
      ('Settings', Icons.settings),
    ];

    return Container(
      width: 100,
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Logo
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_circle, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 32),
          // Nav items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DpadFocusable(
                region: 'sidebar',
                debugLabel: 'Nav ${item.$1}',
                isEntryPoint: index == 0,
                onSelect: () => setState(() => _selectedNavIndex = index),
                builder: (context, isFocused, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _selectedNavIndex == index || isFocused
                          ? Colors.blue
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.$2,
                          color: _selectedNavIndex == index || isFocused
                              ? Colors.white
                              : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$1,
                          style: TextStyle(
                            fontSize: 10,
                            color: _selectedNavIndex == index || isFocused
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 350,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Featured Title',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'An epic adventure awaits. Experience the journey of a lifetime.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                DpadFocusable(
                  autofocus: true,
                  region: 'hero',
                  debugLabel: 'Play Button',
                  isEntryPoint: true,
                  builder: FocusEffects.scaleWithBorder(
                    scale: 1.05,
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Play Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildSection(String title, String region, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildCard(
                items[index]['title']!,
                items[index]['subtitle']!,
                region,
                index == 0,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String subtitle, String region, bool isEntry) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: DpadFocusable(
        region: region,
        debugLabel: '$region: $title',
        isEntryPoint: isEntry,
        autoScroll: true,
        scrollPadding: 32,
        builder: (context, isFocused, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 280,
            transform: Matrix4.identity()..scale(isFocused ? 1.05 : 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade900,
              border: isFocused
                  ? Border.all(color: Colors.blue, width: 3)
                  : null,
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade900,
                          Colors.purple.shade900,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.movie,
                        size: 48,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  final _continueItems = [
    {'title': 'The Adventure', 'subtitle': '45 min left'},
    {'title': 'Mystery Island', 'subtitle': '20 min left'},
    {'title': 'Space Journey', 'subtitle': '1h 15m left'},
    {'title': 'Lost Kingdom', 'subtitle': '30 min left'},
    {'title': 'Ocean Depths', 'subtitle': '55 min left'},
  ];

  final _recommendedItems = [
    {'title': 'Epic Tales', 'subtitle': 'Action • 2024'},
    {'title': 'Night Watch', 'subtitle': 'Thriller • 2024'},
    {'title': 'Sky High', 'subtitle': 'Adventure • 2023'},
    {'title': 'Dark Forest', 'subtitle': 'Horror • 2024'},
    {'title': 'City Lights', 'subtitle': 'Drama • 2024'},
    {'title': 'Wild Run', 'subtitle': 'Action • 2023'},
  ];
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    for (var i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
    for (var i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
