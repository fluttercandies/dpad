import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DPad Navigation Example'),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 4,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero Section
              _buildHeroSection(),
              const SizedBox(height: 48.0),
              
              // Action Buttons Section
              _buildActionButtons(context),
              const SizedBox(height: 48.0),
              
              // Features Section
              _buildFeaturesSection(),
              const SizedBox(height: 48.0),
              
              // Demo Cards Section
              _buildDemoCards(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1976D2).withValues(alpha: 0.1),
            const Color(0xFF1976D2).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFF1976D2).withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Icon(
              Icons.tv,
              size: 48,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 16.0),
          const Text(
            '🎮 TV Navigation Experience',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Use arrow keys or game controller to navigate',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          'Start Navigation',
          const Color(0xFFFF9800),
          Icons.play_arrow,
          () => _showMessage(context, 'Navigation Started!'),
        ),
        const SizedBox(width: 24.0),
        _buildActionButton(
          'Settings',
          const Color(0xFF2196F3),
          Icons.settings,
          () => _showMessage(context, 'Settings Opened!'),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    Color backgroundColor,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12.0),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.keyboard,
                  color: Color(0xFF1976D2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12.0),
              const Text(
                'Custom Shortcuts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          _buildShortcutRow('R', 'Refresh', Icons.refresh),
          const SizedBox(height: 12.0),
          _buildShortcutRow('S', 'Search', Icons.search),
          const SizedBox(height: 12.0),
          _buildShortcutRow('G', 'Games', Icons.sports_esports),
          const SizedBox(height: 12.0),
          _buildShortcutRow('V', 'Videos', Icons.smart_display),
          const SizedBox(height: 12.0),
          _buildShortcutRow('Menu', 'Context Menu', Icons.menu),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String key, String description, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1976D2),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.6),
          size: 18,
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Text(
            description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoCards(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Demo Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Demo Cards Row
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: [
              _buildDemoCard(
                'Grid View',
                Icons.grid_view,
                const Color(0xFF4CAF50),
              ),
              _buildDemoCard(
                'List View',
                Icons.list,
                const Color(0xFF2196F3),
              ),
              _buildDemoCard(
                'Settings',
                Icons.settings,
                const Color(0xFFFF5722),
              ),
              _buildDemoCard(
                'Effects',
                Icons.brush,
                const Color(0xFF9C27B0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCard(
    String title,
    IconData icon,
    Color color,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton(
        onPressed: () {
          debugPrint('Opening $title...');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 2.0),
        ),
        child: SizedBox(
          width: 160,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8.0),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1976D2),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
