import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../data.dart';

/// A line-wrapping grid: right past the last tile of a row steps to
/// the first tile of the row below (and left back up), typewriter-style —
/// the issue #8 flagship. The rail side stays reachable via a per-direction
/// edge override, mirrored when the RTL demo is on. Focus memory and
/// auto-scroll behave as everywhere else.
///
/// The grid also demos two scoped capabilities at once: a
/// [DpadHighlightTheme] (a warm spotlight fill under the ring, resolved for
/// wherever focus lands) and **shape following** — the tiles are circular
/// avatars, so the flying ring lands as a circle here and morphs back into
/// the 12-pixel poster rounding when focus leaves the section.
class LibrarySection extends StatelessWidget {
  const LibrarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return DpadHighlightTheme(
      data: const DpadHighlight(
        nudgeOffset: 8,
        effects: <DpadHighlightEffect>[
          DpadHighlightSpotlightEffect(opacity: 0.18),
          DpadHighlightRingEffect(),
        ],
      ),
      child: DpadRegion(
        debugLabel: 'library',
        memoryKey: 'library',
        // Grid line wrap along rows; only the rail side may exit the axis.
        horizontalEdge: DpadEdgeBehavior.lineWrap,
        leftEdge: rtl ? null : DpadEdgeBehavior.leave,
        rightEdge: rtl ? DpadEdgeBehavior.leave : null,
        child: GridView.builder(
          // Padding sits inside the scrollable, so the ring and spotlight
          // paint into it without being clipped.
          padding: const EdgeInsets.all(36),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: 24,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: library.length,
          itemBuilder: (context, index) => _AvatarTile(
            movie: library[index],
          ),
        ),
      ),
    );
  }
}

/// A circular profile tile — the shape the flying highlight morphs to.
class _AvatarTile extends StatelessWidget {
  const _AvatarTile({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      debugLabel: 'avatar:${movie.title}',
      semanticLabel: movie.title,
      onSelect: () {},
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: movie.colors,
          ),
        ),
        child: Center(
          child: Icon(
            movie.icon,
            size: 44,
            color: Colors.white.withAlpha(215),
          ),
        ),
      ),
    );
  }
}
