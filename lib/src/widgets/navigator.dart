import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Root container providing global D-pad navigation support for Flutter TV apps.
///
/// This widget captures D-pad events and translates them into focus movements,
/// making your Flutter app navigable with D-pad controllers on TV platforms.
class DpadNavigator extends StatelessWidget {
  /// The child widget that will have D-pad navigation support.
  final Widget child;

  /// Map of custom keyboard shortcuts and their corresponding actions.
  final Map<LogicalKeyboardKey, VoidCallback>? customShortcuts;

  /// Whether D-pad navigation is enabled.
  final bool enabled;

  /// Callback function triggered when the menu key is pressed.
  final VoidCallback? onMenuPressed;

  /// Callback function triggered when the back key is pressed.
  final VoidCallback? onBackPressed;

  const DpadNavigator({
    super.key,
    required this.child,
    this.customShortcuts,
    this.enabled = true,
    this.onMenuPressed,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Handle special keys
          if (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.goBack) {
            onBackPressed?.call();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.contextMenu) {
            onMenuPressed?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: CallbackShortcuts(
        bindings: _buildBindings(),
        child: child,
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _buildBindings() {
    final bindings = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
          _navigate(TraversalDirection.up),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
          _navigate(TraversalDirection.down),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
          _navigate(TraversalDirection.left),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
          _navigate(TraversalDirection.right),
      const SingleActivator(LogicalKeyboardKey.enter): () => _selectCurrent(),
      const SingleActivator(LogicalKeyboardKey.select): () => _selectCurrent(),
      const SingleActivator(LogicalKeyboardKey.space): () => _selectCurrent(),
    };

    // Add custom shortcuts
    if (customShortcuts != null) {
      for (final entry in customShortcuts!.entries) {
        bindings[SingleActivator(entry.key)] = entry.value;
      }
    }

    return bindings;
  }

  void _navigate(TraversalDirection direction) {
    // Use Flutter's native focus navigation
    final currentContext = FocusManager.instance.primaryFocus?.context;
    if (currentContext != null) {
      FocusScope.of(currentContext).focusInDirection(direction);
    }
  }

  void _selectCurrent() {
    final currentFocus = FocusManager.instance.primaryFocus;
    currentFocus?.consumeKeyboardToken();
  }
}
