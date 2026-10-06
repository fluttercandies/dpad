import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../pages/detail_page.dart';
import '../widgets/poster_card.dart';
import '../widgets/tv_button.dart';

/// The landing section: a featured banner plus lazy poster rows.
///
/// Every row is its own [DpadRegion], so moving down and back up returns to
/// the poster you were on — the behavior people expect from every TV app.
class ForYouSection extends StatelessWidget {
  const ForYouSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: horizontal padding lives *inside* each row's ListView (not on
    // this page list), so scaled/glowing focus effects paint into the
    // padding instead of being clipped at the row edge — the standard way
    // to lay out TV shelves in Flutter.
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: _FeaturedBanner(movie: featured),
        ),
        const SizedBox(height: 24),
        for (final row in homeRows) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 0, 36, 0),
            child: Text(
              row.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _PosterRow(row: row, showProgress: row.title == 'Continue Watching'),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PosterRow extends StatelessWidget {
  const _PosterRow({required this.row, required this.showProgress});

  final MovieRow row;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return DpadRegion(
      debugLabel: 'row:${row.title}',
      // Survives section switches: come back to "For you" and every row
      // still remembers its poster.
      memoryKey: 'for-you/${row.title}',
      // Carousel forward, but the rail side stays reachable — a
      // per-direction override opens just one side of the axis, mirrored
      // when the RTL demo is on.
      horizontalEdge: DpadEdgeBehavior.wrap,
      leftEdge: rtl ? null : DpadEdgeBehavior.leave,
      rightEdge: rtl ? DpadEdgeBehavior.leave : null,
      child: SizedBox(
        // 124px cards + 16px of breathing room on each side, so the
        // focused card's scale and glow stay inside the clip bounds.
        height: 124 + 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          itemCount: row.movies.length,
          itemBuilder: (context, index) => PosterCard(
            movie: row.movies[index],
            margin: const EdgeInsetsDirectional.only(end: 16),
            showProgress: showProgress,
            // The first "Continue Watching" poster overrides the theme to
            // show per-item effects.
            effects: showProgress && index == 0
                ? const [
                    DpadScaleEffect(scale: 1.06),
                    DpadGlowEffect(color: Colors.white, opacity: 0.4),
                    DpadBorderEffect(color: Colors.white),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: movie.colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              movie.icon,
              size: 240,
              color: Colors.white.withAlpha(38),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 48),
              const Text(
                'FEATURED',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 520,
                child: Text(
                  movie.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
              const SizedBox(height: 20),
              // The banner buttons form their own region; `entry: true` on
              // Play makes it the landing target, and autofocus makes it
              // the very first focus of the whole app.
              DpadRegion(
                debugLabel: 'banner-actions',
                enter: DpadEnterBehavior.entry,
                child: Row(
                  children: [
                    TvButton(
                      label: 'Play',
                      icon: Icons.play_arrow_rounded,
                      autofocus: true,
                      entry: true,
                      onSelect: () => DetailPage.open(context, movie),
                    ),
                    const SizedBox(width: 12),
                    TvButton(
                      label: 'More info',
                      icon: Icons.info_outline_rounded,
                      onSelect: () => DetailPage.open(context, movie),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
