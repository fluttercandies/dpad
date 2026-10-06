import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../pages/detail_page.dart';
import '../styles.dart';

/// A poster tile driven entirely by [DpadFocusable].
///
/// * select  → opens the detail page
/// * long-select → opens a context sheet (a very TV pattern)
/// * effects come from the app-wide [DpadTheme] unless [effects] overrides
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.movie,
    this.width = 220,
    this.height = 124,
    this.margin = EdgeInsets.zero,
    this.effects,
    this.showProgress = false,
  });

  final Movie movie;
  final double width;
  final double height;
  final EdgeInsetsGeometry margin;
  final List<DpadEffect>? effects;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DpadFocusable(
        effects: effects,
        debugLabel: 'poster:${movie.title}',
        onSelect: () => DetailPage.open(context, movie),
        onLongSelect: () => _showOptions(context),
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: movie.colors,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -12,
                    bottom: -12,
                    child: Icon(
                      movie.icon,
                      size: height * 0.85,
                      color: Colors.white.withAlpha(46),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                  if (showProgress && movie.progress != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: movie.progress,
                        minHeight: 4,
                        backgroundColor: Colors.black.withAlpha(102),
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(190),
      elevation: 0,
      // Content-sized sheet: the default 9/16 height cap clamps this
      // content and eats the bottom padding.
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            gradient: kSurfaceGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(
              top: BorderSide(color: Color(0x24FFFFFF)),
            ),
          ),
          child: SafeArea(
            top: false,
            // heightFactor 1 keeps the sheet content-sized (anchored at the
            // screen bottom by the modal) instead of stretching to full
            // height; alignment still centers the 460-wide column.
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(77),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Container(
                                width: 48,
                                height: 66,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: movie.colors,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    movie.icon,
                                    color: Colors.white.withAlpha(120),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${movie.year} · ${movie.rating} · ${movie.duration}',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(158),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SheetAction(
                          icon: Icons.play_arrow_rounded,
                          label: 'Play from beginning',
                          autofocus: true,
                          onSelect: () => Navigator.pop(sheetContext),
                        ),
                        const SizedBox(height: 10),
                        _SheetAction(
                          icon: Icons.add_rounded,
                          label: 'Add to my list',
                          onSelect: () => Navigator.pop(sheetContext),
                        ),
                        const SizedBox(height: 10),
                        _SheetAction(
                          icon: Icons.thumb_up_alt_outlined,
                          label: 'Rate this title',
                          onSelect: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A full-width sheet row: icon chip + label, driven through the builder
/// API so the focused and pressed states are fully hand-drawn.
class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onSelect,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DpadFocusable(
      autofocus: autofocus,
      onSelect: onSelect,
      builder: (context, state, child) {
        final Color foreground =
            state.focused ? scheme.onPrimary : Colors.white;
        return AnimatedScale(
          scale: state.pressed
              ? 0.98
              : state.focused
                  ? 1.02
                  : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:
                  state.focused ? scheme.primary : Colors.white.withAlpha(23),
              borderRadius: BorderRadius.circular(14),
              border: state.focused
                  ? Border.all(color: scheme.primary.withAlpha(160))
                  : Border.all(color: Colors.white.withAlpha(36)),
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
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: state.focused
                        ? Colors.white.withAlpha(46)
                        : Colors.white.withAlpha(18),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 21, color: foreground),
                ),
                const SizedBox(width: 14),
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
