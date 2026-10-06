import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets/poster_card.dart';

/// A line-wrapping grid: right past the last tile of a row steps to the
/// first tile of the row below (and left back up), typewriter-style — the
/// issue #8 flagship. The rail side stays reachable via a per-direction
/// edge override, mirrored when the RTL demo is on. Focus memory and
/// auto-scroll behave as everywhere else.
class LibrarySection extends StatelessWidget {
  const LibrarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return DpadRegion(
      debugLabel: 'library',
      memoryKey: 'library',
      // Grid line wrap along rows; only the rail side may exit the axis.
      horizontalEdge: DpadEdgeBehavior.lineWrap,
      leftEdge: rtl ? null : DpadEdgeBehavior.leave,
      rightEdge: rtl ? DpadEdgeBehavior.leave : null,
      child: GridView.builder(
        // Padding sits inside the scrollable, so edge cards can scale and
        // glow into it without being clipped.
        padding: const EdgeInsets.all(36),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisSpacing: 24,
          crossAxisSpacing: 16,
          childAspectRatio: 240 / 124,
        ),
        itemCount: library.length,
        itemBuilder: (context, index) => PosterCard(
          movie: library[index],
          width: double.infinity,
        ),
      ),
    );
  }
}
