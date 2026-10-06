import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class SidebarDestination {
  const SidebarDestination(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// The classic TV navigation rail: a [DpadRegion] that expands while focus
/// is inside it, remembers the selected destination, and never lets focus
/// fall off the top or bottom of the screen.
class Sidebar extends StatefulWidget {
  const Sidebar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<SidebarDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _expanded = false;
  double _bump = 0;

  /// A little vertical "bump" when navigation hits a stop edge — the
  /// visual cue TV users expect instead of silence.
  Future<void> _onEdge(TraversalDirection direction) async {
    setState(() => _bump = direction == TraversalDirection.up ? -6 : 6);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (mounted) {
      setState(() => _bump = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DpadRegion(
      debugLabel: 'sidebar',
      // Up/down past the ends stays put: the remote never "falls off" the
      // menu. Left is the screen edge; right leaves into the content.
      verticalEdge: DpadEdgeBehavior.stop,
      onEdge: _onEdge,
      onFocusChange: (inside) => setState(() => _expanded = inside),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: _expanded ? 240 : 88,
        color: const Color(0xFF11141B),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _bump, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: _expanded ? 12 : 0, bottom: 28),
                child: Row(
                  // Collapsed: the logo centers in the rail like the icons.
                  mainAxisAlignment: _expanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill,
                        color: Theme.of(context).colorScheme.primary, size: 32),
                    if (_expanded) ...[
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          'DPAD TV',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              for (int i = 0; i < widget.destinations.length; i++)
                _SidebarItem(
                  destination: widget.destinations[i],
                  selected: i == widget.selectedIndex,
                  expanded: _expanded,
                  // The first destination is the region's landing item until
                  // the user builds up focus memory.
                  entry: i == 0,
                  onFocused: () => widget.onSelected(i),
                  onSelect: () {
                    widget.onSelected(i);
                    // Center press on a destination dives into the content —
                    // programmatic navigation via the controller. In RTL the
                    // rail sits on the right, so the content is to the left.
                    final controller = Dpad.of(context);
                    if (Directionality.of(context) == TextDirection.rtl) {
                      controller.moveLeft();
                    } else {
                      controller.moveRight();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.entry,
    required this.onFocused,
    required this.onSelect,
  });

  final SidebarDestination destination;
  final bool selected;
  final bool expanded;
  final bool entry;
  final VoidCallback onFocused;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DpadFocusable(
        entry: entry,
        debugLabel: 'sidebar:${destination.label}',
        onSelect: onSelect,
        // Browsing the menu switches the section immediately, like the
        // launcher on Android TV.
        onFocusChange: (focused) {
          if (focused) {
            onFocused();
          }
        },
        builder: (context, state, child) {
          final Color background = state.focused
              ? scheme.primary
              : selected
                  ? Colors.white.withAlpha(18)
                  : Colors.transparent;
          final Color foreground = state.focused
              ? scheme.onPrimary
              : selected
                  ? Colors.white
                  : Colors.white70;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 0),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              // Collapsed: a centered icon inside a symmetric highlight,
              // not a left-hugging one.
              mainAxisAlignment:
                  expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(destination.icon, size: 22, color: foreground),
                if (expanded) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}
