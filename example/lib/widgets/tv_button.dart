import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

/// A remote-friendly button built on [DpadFocusable.builder], showing how to
/// take full control of the focus presentation (including the pressed
/// state of the select key).
class TvButton extends StatelessWidget {
  const TvButton({
    super.key,
    required this.label,
    required this.onSelect,
    this.icon,
    this.autofocus = false,
    this.entry = false,
    this.quiet = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback onSelect;
  final IconData? icon;
  final bool autofocus;
  final bool entry;

  /// Secondary styling: outlined while idle, inverts to a white fill when
  /// focused. Dialogs pair one filled action with quiet ones.
  final bool quiet;

  /// Dialog sizing: equal-width, taller buttons with centered content.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DpadFocusable(
      autofocus: autofocus,
      entry: entry,
      onSelect: onSelect,
      builder: (context, state, child) {
        final Color background;
        final Color foreground;
        if (state.focused) {
          if (quiet) {
            background = Colors.white;
            foreground = const Color(0xFF161A22);
          } else {
            background =
                state.pressed ? scheme.primary.withAlpha(204) : scheme.primary;
            foreground = scheme.onPrimary;
          }
        } else {
          background = Colors.white.withAlpha(20);
          foreground = Colors.white;
        }
        return AnimatedScale(
          scale: state.pressed
              ? 0.97
              : state.focused
                  ? 1.02
                  : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: expanded ? double.infinity : null,
            constraints: expanded ? const BoxConstraints(minHeight: 50) : null,
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 20 : 24,
              vertical: expanded ? 14 : 12,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(expanded ? 14 : 12),
              border: quiet
                  ? Border.all(
                      color: state.focused
                          ? Colors.white
                          : Colors.white.withAlpha(56),
                    )
                  : null,
              boxShadow: state.focused
                  ? <BoxShadow>[
                      BoxShadow(
                        color: scheme.primary.withAlpha(77),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment:
                  expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
