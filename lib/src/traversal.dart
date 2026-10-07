import 'package:flutter/widgets.dart';

import 'marks.dart';
import 'region.dart';
import 'scroll.dart';
import 'theme.dart';

/// A [FocusTraversalPolicy] that navigates the way TV platforms do.
///
/// Flutter's stock directional policy picks the geometrically closest node,
/// which breaks down in real TV layouts (focus "jumping lanes" between a
/// sidebar and content, skipping rows, escaping carousels). This policy
/// implements the model used by Android's `FocusFinder` and Leanback:
///
/// 1. **Region first** — candidates inside the current [DpadRegion] always
///    win over outside candidates, regardless of raw distance.
/// 2. **Beam preference** — candidates that overlap the focused item on the
///    cross axis ("in the beam") beat diagonal candidates.
/// 3. **Edge behaviors** — at a region boundary, focus leaves, stops or
///    wraps according to the region's [DpadEdgeBehavior].
/// 4. **Enter behaviors** — when focus crosses into a region, the region
///    decides the landing item (restore memory / entry item / nearest).
/// 5. **Lazy-list awareness** — when no candidate exists but a scrollable
///    can still scroll in that direction, the policy scrolls and retries,
///    so `ListView.builder` rows beyond the cache are reachable.
///
/// [Dpad] and [DpadRegion] install this policy automatically; you rarely
/// construct it yourself. To use it manually:
///
/// ```dart
/// FocusTraversalGroup(
///   policy: DpadTraversalPolicy(),
///   child: ...,
/// )
/// ```
///
/// Tab / readers order falls back to [ReadingOrderTraversalPolicy].
// Non-final by design: the policy instance is a long-lived State field, and
// its rewind generation counter must mutate as navigation happens.
// ignore: must_be_immutable
class DpadTraversalPolicy extends ReadingOrderTraversalPolicy {
  /// Creates a TV traversal policy.
  DpadTraversalPolicy();

  static const double _kAxisEpsilon = 0.01;

  // Bumped whenever navigation moves focus synchronously or a fresh wrap
  // rewind starts. A rewind chain captures the value at launch and yields as
  // soon as it changes, so a later key press in the *same* region (which the
  // cross-region `interrupted()` check cannot see) still wins over the chain.
  int _rewindGeneration = 0;

  // App-wide epoch for rewind chains: bumped when navigation freezes or
  // unfreezes, and on dpad-owned programmatic focus moves. A chain captures
  // it at launch and yields once it moves — a freeze must stop chains from
  // scrolling and grabbing focus, and a programmatic requestFocus must not
  // be dragged back by a chain still in flight.
  static int _rewindEpoch = 0;

  /// Invalidates every in-flight rewind chain, app-wide.
  static void invalidateRewinds() => _rewindEpoch++;

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    // No real focus yet: land on a sensible initial item.
    if (currentNode is FocusScopeNode) {
      final FocusNode? inner = currentNode.focusedChild;
      if (inner != null) {
        return inDirection(inner, direction);
      }
      return _focusInitial(currentNode, direction);
    }

    final FocusScopeNode? scope = currentNode.nearestScope;
    final BuildContext? context = currentNode.context;
    final Rect? currentRect = DpadMarks.rectOf(currentNode);
    if (scope == null) {
      // Detached from the focus tree (its context can still be mounted
      // through element reuse); the framework's own inDirection would
      // crash on nearestScope! here, and there is nowhere to go anyway.
      return false;
    }
    if (context == null || currentRect == null) {
      return super.inDirection(currentNode, direction);
    }
    // Reading order matters for line wrap: in RTL layouts the reading
    // direction — and with it the "next line" — runs the other way.
    final bool rtl = Directionality.maybeOf(context) == TextDirection.rtl;

    final DpadRegionState? region = DpadRegion.ofNode(currentNode);

    // One pass, one region lookup per node: everything else downstream
    // (edge handling, cross-region search) works off these two buckets.
    final List<FocusNode> inRegion = <FocusNode>[];
    final List<FocusNode> outside = <FocusNode>[];
    for (final FocusNode node in scope.traversalDescendants) {
      if (identical(node, currentNode)) {
        continue;
      }
      if (region != null && identical(DpadRegion.ofNode(node), region)) {
        inRegion.add(node);
      } else {
        outside.add(node);
      }
    }

    if (region != null) {
      final DpadEdgeBehavior edge = region.edgeBehaviorFor(direction);
      // Line wrap promises typewriter semantics: while the current line has
      // an in-beam candidate ahead, move along the line; once it runs out,
      // take the line step — never a diagonal jump to another line.
      final FocusNode? within = _bestCandidate(
        currentRect,
        inRegion,
        direction,
        beamOnly: edge == DpadEdgeBehavior.lineWrap,
      );
      if (within != null) {
        return _focusNode(within);
      }

      // The region might have more content that simply is not built yet.
      if (_scrollForMore(currentNode, direction, boundary: region.context)) {
        return true;
      }

      switch (edge) {
        case DpadEdgeBehavior.stop:
          region.notifyEdge(direction);
          return true;
        case DpadEdgeBehavior.wrap:
          // The far end of the line may have been evicted from a lazy
          // list's cache — wrapping now would land mid-line. When the axis
          // still has scroll room behind the source, rewind there first so
          // the wrap lands on the true first item.
          if (_scrollToWrapExtreme(currentNode, direction, region: region)) {
            return true;
          }
          final FocusNode? wrapped =
              _wrapCandidate(currentRect, inRegion, direction);
          if (wrapped != null) {
            return _focusNode(wrapped);
          }
          region.notifyEdge(direction);
          return true;
        case DpadEdgeBehavior.lineWrap:
          final FocusNode? nextLine = _lineWrapCandidate(
            currentRect,
            inRegion,
            direction,
            rtl: rtl,
          );
          if (nextLine != null) {
            return _focusNode(nextLine);
          }
          // The next line may simply not be built yet. It lives one
          // cross-axis step away, so reveal it by scrolling in that
          // direction, then retry with the original key.
          if (_scrollForMore(
            currentNode,
            direction,
            boundary: region.context,
            scrollDirection: _crossStepOf(direction, rtl: rtl),
          )) {
            return true;
          }
          region.notifyEdge(direction);
          return true;
        case DpadEdgeBehavior.leave:
          break;
      }
    }

    // Cross-region / global search.
    final FocusNode? nearest = _bestCandidate(currentRect, outside, direction);
    if (nearest == null) {
      // Nothing anywhere — maybe an enclosing page scrollable can reveal
      // more content (lazily built rows, grids, etc.).
      return _scrollForMore(currentNode, direction);
    }

    FocusNode target = nearest;
    final DpadRegionState? targetRegion = DpadRegion.ofNode(nearest);
    if (targetRegion != null && !identical(targetRegion, region)) {
      final List<FocusNode> targetCandidates = outside
          .where((FocusNode node) =>
              identical(DpadRegion.ofNode(node), targetRegion))
          .toList();
      target = targetRegion.resolveEnter(nearest, targetCandidates);
    }
    return _focusNode(target);
  }

  // ---------------------------------------------------------------------
  // Focus + initial placement
  // ---------------------------------------------------------------------

  bool _focusNode(FocusNode node) {
    // This is a fresh navigation decision; any wrap rewind still in flight
    // must not steal focus back from it.
    _rewindGeneration++;
    return _requestFocus(node);
  }

  /// Moves focus to [node] without invalidating in-flight rewind chains;
  /// only user-driven moves (via [_focusNode]) do that.
  bool _requestFocus(FocusNode node) {
    DpadRegion.ofNode(node)?.noteFocus(node);
    node.requestFocus();
    // DpadFocusable nodes run their own padded auto-scroll on focus; plain
    // Focus nodes still get a basic reveal so they never stay clipped.
    if (DpadMarks.managed[node] != true) {
      final BuildContext? context = node.context;
      DpadScroll.ensureVisible(
        node,
        padding: context == null
            ? 48.0
            : DpadTheme.maybeOf(context)?.scrollPadding ?? 48.0,
      );
    }
    return true;
  }

  bool _focusInitial(FocusScopeNode scope, TraversalDirection direction) {
    final FocusNode? target =
        DpadMarks.initialCandidate(scope.traversalDescendants);
    if (target == null) {
      return false;
    }
    return _focusNode(target);
  }

  // ---------------------------------------------------------------------
  // Geometry — modeled on Android FocusFinder
  // ---------------------------------------------------------------------

  /// Whether [candidate] counts as "in [direction]" from [source].
  ///
  /// Edge-based, so candidates that partially overlap the source (large
  /// tiles, banners) are still considered.
  static bool _isCandidate(
    Rect source,
    Rect candidate,
    TraversalDirection direction,
  ) {
    switch (direction) {
      case TraversalDirection.left:
        return (source.right > candidate.right ||
                source.left >= candidate.right) &&
            source.left > candidate.left;
      case TraversalDirection.right:
        return (source.left < candidate.left ||
                source.right <= candidate.left) &&
            source.right < candidate.right;
      case TraversalDirection.up:
        return (source.bottom > candidate.bottom ||
                source.top >= candidate.bottom) &&
            source.top > candidate.top;
      case TraversalDirection.down:
        return (source.top < candidate.top ||
                source.bottom <= candidate.bottom) &&
            source.bottom < candidate.bottom;
    }
  }

  /// Distance from the source's leading edge to the candidate's trailing
  /// edge along the navigation axis, clamped at zero for overlaps.
  static double _majorDistance(
    Rect source,
    Rect candidate,
    TraversalDirection direction,
  ) {
    final double distance;
    switch (direction) {
      case TraversalDirection.left:
        distance = source.left - candidate.right;
      case TraversalDirection.right:
        distance = candidate.left - source.right;
      case TraversalDirection.up:
        distance = source.top - candidate.bottom;
      case TraversalDirection.down:
        distance = candidate.top - source.bottom;
    }
    return distance < 0 ? 0 : distance;
  }

  /// Distance between centers on the cross axis.
  static double _minorDistance(
    Rect source,
    Rect candidate,
    TraversalDirection direction,
  ) {
    switch (direction) {
      case TraversalDirection.left:
      case TraversalDirection.right:
        return (candidate.center.dy - source.center.dy).abs();
      case TraversalDirection.up:
      case TraversalDirection.down:
        return (candidate.center.dx - source.center.dx).abs();
    }
  }

  /// Whether [candidate] overlaps [source] on the cross axis.
  static bool _inBeam(
    Rect source,
    Rect candidate,
    TraversalDirection direction,
  ) {
    switch (direction) {
      case TraversalDirection.left:
      case TraversalDirection.right:
        return candidate.bottom > source.top && candidate.top < source.bottom;
      case TraversalDirection.up:
      case TraversalDirection.down:
        return candidate.right > source.left && candidate.left < source.right;
    }
  }

  /// Android's weighted distance: progress along the major axis dominates,
  /// but cross-axis drift still discriminates.
  static double _weightedDistance(double major, double minor) {
    return 13 * major * major + minor * minor;
  }

  /// Picks the best node to move to. In-beam candidates categorically beat
  /// out-of-beam ones; with [beamOnly], out-of-beam candidates are ignored
  /// entirely (used by [DpadEdgeBehavior.lineWrap]).
  FocusNode? _bestCandidate(
    Rect source,
    List<FocusNode> candidates,
    TraversalDirection direction, {
    bool beamOnly = false,
  }) {
    FocusNode? best;
    bool bestInBeam = false;
    double bestScore = double.infinity;

    for (final FocusNode node in candidates) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null || rect == source) {
        continue;
      }
      if (!_isCandidate(source, rect, direction)) {
        continue;
      }
      final bool inBeam = _inBeam(source, rect, direction);
      if (beamOnly && !inBeam) {
        continue;
      }
      final double score = _weightedDistance(
        _majorDistance(source, rect, direction),
        _minorDistance(source, rect, direction),
      );
      // In-beam candidates categorically beat out-of-beam candidates.
      if (best == null ||
          (inBeam && !bestInBeam) ||
          (inBeam == bestInBeam && score < bestScore)) {
        best = node;
        bestInBeam = inBeam;
        bestScore = score;
      }
    }
    return best;
  }

  /// The wrap-around target: the in-region item furthest *behind* the
  /// source along the navigation axis, preferring the source's beam.
  FocusNode? _wrapCandidate(
    Rect source,
    List<FocusNode> candidates,
    TraversalDirection direction,
  ) {
    final TraversalDirection reverse = _reverseOf(direction);
    FocusNode? best;
    bool bestInBeam = false;
    double bestMajor = -1;
    double bestMinor = double.infinity;

    for (final FocusNode node in candidates) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null || rect == source) {
        continue;
      }
      if (!_isCandidate(source, rect, reverse)) {
        continue;
      }
      final bool inBeam = _inBeam(source, rect, direction);
      final double major = _majorDistance(source, rect, reverse);
      final double minor = _minorDistance(source, rect, reverse);

      final bool better;
      if (best == null) {
        better = true;
      } else if (inBeam != bestInBeam) {
        better = inBeam;
      } else if ((major - bestMajor).abs() > _kAxisEpsilon) {
        better = major > bestMajor;
      } else {
        better = minor < bestMinor;
      }
      if (better) {
        best = node;
        bestInBeam = inBeam;
        bestMajor = major;
        bestMinor = minor;
      }
    }
    return best;
  }

  static TraversalDirection _reverseOf(TraversalDirection direction) {
    switch (direction) {
      case TraversalDirection.up:
        return TraversalDirection.down;
      case TraversalDirection.down:
        return TraversalDirection.up;
      case TraversalDirection.left:
        return TraversalDirection.right;
      case TraversalDirection.right:
        return TraversalDirection.left;
    }
  }

  /// How many stepped rewinds one wrap press may chain toward the far end
  /// of a lazy line before landing on the best-built candidate. Bounded so
  /// an effectively infinite list cannot rewind forever on a single press.
  static const int _kWrapRewindHops = 10;

  /// Rewinds the lazy line behind [node] so a wrap press can land on the
  /// line's true start instead of the furthest still-cached item.
  ///
  /// [_wrapCandidate] only sees built children; when the axis scrollable
  /// still has room toward the reverse extreme, the true first item is
  /// likely evicted. This rewinds in 0.8-viewport hops, and after each hop
  /// moves focus to the in-region item at the geometric extreme of what is
  /// built. That anchor's own reveal pulls the same way as the rewind —
  /// focus restoration can never drag the offset back and stall the chain.
  /// The final hop lands on the freshly built true extreme. All picks are
  /// pure geometry, so RTL reading order falls out for free.
  ///
  /// Returns `true` when a rewind was started, which consumes the key press.
  bool _scrollToWrapExtreme(
    FocusNode node,
    TraversalDirection direction, {
    required DpadRegionState region,
  }) {
    final TraversalDirection reverse = _reverseOf(direction);
    final ScrollableState? scrollable =
        _nearestScrollableToward(node, reverse, region.context);
    if (scrollable == null) {
      return false;
    }
    final FocusScopeNode? scope = node.nearestScope;
    if (scope == null) {
      return false;
    }

    // Launching supersedes any rewind chain still in flight (rapid wrap
    // presses): the newest chain is the only one allowed to land.
    final int generation = ++_rewindGeneration;
    final int epoch = _rewindEpoch;

    // A key press during the rewind that moved focus into another region
    // (rail, dialog) must win; focus loss from cache eviction must not.
    bool interrupted() {
      final FocusNode? current = FocusManager.instance.primaryFocus;
      return current != null &&
          current is! FocusScopeNode &&
          current.context != null &&
          !identical(DpadRegion.ofNode(current), region);
    }

    // Superseded by a newer navigation decision (a synchronous move or a
    // newer rewind) or invalidated app-wide (a freeze, a programmatic
    // focus): the chain yields instead of stealing focus back.
    bool superseded() =>
        generation != _rewindGeneration || epoch != _rewindEpoch;

    void land() {
      if (interrupted() || superseded()) {
        return;
      }
      final FocusNode? target = _extremeNode(scope, region, direction);
      if (target != null && !target.hasPrimaryFocus) {
        _requestFocus(target);
      }
    }

    void hop(int remaining) {
      if (remaining == 0) {
        _postFrame(land);
        return;
      }
      if (interrupted() || superseded()) {
        return;
      }
      // The rewind can outlive its page (pop, section switch) across its
      // hop chain; a disposed scrollable's position throws.
      if (!scrollable.context.mounted) {
        return;
      }
      final ScrollPosition position = scrollable.position;
      if (!_canScrollToward(scrollable, reverse)) {
        // The extreme content is built by now (or one press rewinds only
        // this far); land on it after the frame that built it.
        _postFrame(land);
        return;
      }
      final bool forward = _isForward(scrollable.axisDirection, reverse);
      final double step = position.viewportDimension * 0.8;
      final double offset = (position.pixels + (forward ? step : -step)).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      position
          .animateTo(
        offset,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
      )
          .then((_) {
        _postFrame(() {
          land(); // Re-anchor on the extreme of what is built.
          _postFrame(() => hop(remaining - 1));
        });
      });
    }

    hop(_kWrapRewindHops);
    return true;
  }

  /// Runs [callback] after the next frame, requesting one when the pipeline
  /// has gone idle (a bare post-frame callback alone never wakes it).
  static void _postFrame(VoidCallback callback) {
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => callback())
      ..scheduleFrame();
  }

  /// The in-region item at the far end behind the line along [direction] —
  /// the true wrap target once the rewind has built it: the leftmost for
  /// `right`, the rightmost for `left`, the topmost for `down`, the
  /// bottommost for `up`; the topmost (leftmost on the cross axis) wins ties.
  FocusNode? _extremeNode(
    FocusScopeNode scope,
    DpadRegionState region,
    TraversalDirection direction,
  ) {
    final bool minimize = direction == TraversalDirection.right ||
        direction == TraversalDirection.down;
    FocusNode? best;
    double? bestExtreme;
    double? bestCross;
    for (final FocusNode node in scope.traversalDescendants) {
      if (!identical(DpadRegion.ofNode(node), region)) {
        continue;
      }
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null) {
        continue;
      }
      final double extreme = _lineExtreme(rect, direction);
      final double cross = direction == TraversalDirection.left ||
              direction == TraversalDirection.right
          ? rect.top
          : rect.left;
      final bool better;
      if (best == null) {
        better = true;
      } else if ((extreme - bestExtreme!).abs() > _kAxisEpsilon) {
        better = minimize ? extreme < bestExtreme : extreme > bestExtreme;
      } else {
        better = cross < bestCross!;
      }
      if (better) {
        best = node;
        bestExtreme = extreme;
        bestCross = cross;
      }
    }
    return best;
  }

  /// The cross-axis step a [DpadEdgeBehavior.lineWrap] takes when the
  /// current line runs out. The step follows the reading order: in LTR,
  /// right/left step to the line below/above; in RTL — where the reading
  /// direction runs the other way — left/right step to the line below/above.
  /// Down/up always step to the next/previous column, which in RTL lies on
  /// the left/right respectively.
  static TraversalDirection _crossStepOf(
    TraversalDirection direction, {
    required bool rtl,
  }) {
    switch (direction) {
      case TraversalDirection.right:
        return rtl ? TraversalDirection.up : TraversalDirection.down;
      case TraversalDirection.left:
        return rtl ? TraversalDirection.down : TraversalDirection.up;
      case TraversalDirection.down:
        return rtl ? TraversalDirection.left : TraversalDirection.right;
      case TraversalDirection.up:
        return rtl ? TraversalDirection.right : TraversalDirection.left;
    }
  }

  /// The leading edge of [rect] along [direction] — the coordinate the
  /// first cell of a line minimizes (or, reversed, the last cell
  /// maximizes).
  static double _lineExtreme(Rect rect, TraversalDirection direction) {
    switch (direction) {
      case TraversalDirection.right:
        return rect.left;
      case TraversalDirection.down:
        return rect.top;
      case TraversalDirection.left:
        return rect.right;
      case TraversalDirection.up:
        return rect.bottom;
    }
  }

  /// The [DpadEdgeBehavior.lineWrap] target: the first cell of the nearest
  /// line one cross-axis step away (the row below for `right`, the row
  /// above for `left`, and symmetrically for columns with `down`/`up`;
  /// flipped in RTL, where the reading direction runs right-to-left).
  ///
  /// Returns `null` when no such line exists among the built candidates.
  FocusNode? _lineWrapCandidate(
    Rect source,
    List<FocusNode> candidates,
    TraversalDirection direction, {
    required bool rtl,
  }) {
    final TraversalDirection cross = _crossStepOf(direction, rtl: rtl);

    // The nearest line one cross-step away, by major distance.
    FocusNode? nearest;
    Rect? nearestRect;
    double nearestMajor = double.infinity;
    final List<MapEntry<FocusNode, Rect>> stepped =
        <MapEntry<FocusNode, Rect>>[];

    for (final FocusNode node in candidates) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null || rect == source) {
        continue;
      }
      if (!_isCandidate(source, rect, cross)) {
        continue;
      }
      stepped.add(MapEntry<FocusNode, Rect>(node, rect));
      final double major = _majorDistance(source, rect, cross);
      if (major < nearestMajor) {
        nearestMajor = major;
        nearest = node;
        nearestRect = rect;
      }
    }
    if (nearest == null) {
      return null;
    }
    final Rect nearestRow = nearestRect!;

    // The first cell of that line: the member of the nearest's line that
    // leads along the original navigation axis. Line membership is
    // cross-axis overlap, i.e. the beam test with the original direction.
    //
    // Heuristic: `_majorDistance` clamps at zero, so for touching or
    // overlapping lines the "nearest" cell is whichever the focus tree
    // yielded first; the beam filter then anchors the line to that cell.
    // Uniform grids are unaffected; heavily staggered layouts may get a
    // nearby cell of the intended line — acceptable for a FocusFinder-style
    // heuristic.
    final bool minimize = direction == TraversalDirection.right ||
        direction == TraversalDirection.down;
    FocusNode? first;
    double firstExtreme = minimize ? double.infinity : double.negativeInfinity;
    for (final MapEntry<FocusNode, Rect> entry in stepped) {
      if (!_inBeam(nearestRow, entry.value, direction)) {
        continue;
      }
      final double extreme = _lineExtreme(entry.value, direction);
      final bool better =
          minimize ? extreme < firstExtreme : extreme > firstExtreme;
      if (better) {
        firstExtreme = extreme;
        first = entry.key;
      }
    }
    return first ?? nearest;
  }

  // ---------------------------------------------------------------------
  // Lazy-content scrolling
  // ---------------------------------------------------------------------

  /// When no candidate exists, scrolls the nearest matching-axis scrollable
  /// (between the node and [boundary]) one step further and re-runs the
  /// search once the new content is laid out.
  ///
  /// [scrollDirection] picks the scrollable and the scroll step; it defaults
  /// to [direction] (the key being retried), but
  /// [DpadEdgeBehavior.lineWrap] passes the cross-axis step instead — the
  /// next line lives below/above, not sideways.
  ///
  /// Returns `true` when a scroll was started, which consumes the key press.
  bool _scrollForMore(
    FocusNode node,
    TraversalDirection direction, {
    BuildContext? boundary,
    TraversalDirection? scrollDirection,
  }) {
    final TraversalDirection scroll = scrollDirection ?? direction;
    final ScrollableState? scrollable =
        _nearestScrollableToward(node, scroll, boundary);
    if (scrollable == null) {
      return false;
    }

    final ScrollPosition position = scrollable.position;
    final bool forward = _isForward(scrollable.axisDirection, scroll);
    final double step = position.viewportDimension * 0.8;
    final double offset = (position.pixels + (forward ? step : -step)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    // A collapsed (zero along-axis) viewport cannot make progress: the
    // animation completes instantly and the retry would re-enter this
    // method every frame without ever moving — same guard as
    // [DpadScroll._revealIn].
    if ((offset - position.pixels).abs() < 0.5) {
      return false;
    }

    position
        .animateTo(
      offset,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
    )
        .then((_) {
      // Retry once the newly built content is in place.
      if (!node.hasPrimaryFocus || node.context == null) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (node.hasPrimaryFocus && node.context != null) {
          inDirection(node, direction);
        }
      });
    });
    return true;
  }

  /// The nearest scrollable between [node] and [boundary] that can still
  /// scroll toward [direction], or `null`.
  ScrollableState? _nearestScrollableToward(
    FocusNode node,
    TraversalDirection direction,
    BuildContext? boundary,
  ) {
    final BuildContext? context = node.context;
    if (context == null || !context.mounted) {
      return null;
    }

    ScrollableState? match;
    context.visitAncestorElements((Element element) {
      if (boundary != null && identical(element, boundary)) {
        return false;
      }
      if (element is StatefulElement && element.state is ScrollableState) {
        final ScrollableState scrollable = element.state as ScrollableState;
        if (_canScrollToward(scrollable, direction)) {
          match = scrollable;
          return false;
        }
      }
      return true;
    });
    return match;
  }

  static bool _canScrollToward(
    ScrollableState scrollable,
    TraversalDirection direction,
  ) {
    final Axis axis = axisDirectionToAxis(scrollable.axisDirection);
    final bool horizontal = direction == TraversalDirection.left ||
        direction == TraversalDirection.right;
    if (horizontal != (axis == Axis.horizontal)) {
      return false;
    }
    final ScrollPosition position = scrollable.position;
    if (!position.hasPixels || !position.hasContentDimensions) {
      return false;
    }
    final bool forward = _isForward(scrollable.axisDirection, direction);
    return forward
        ? position.pixels < position.maxScrollExtent - 1.0
        : position.pixels > position.minScrollExtent + 1.0;
  }

  /// Whether moving in [direction] corresponds to increasing scroll pixels
  /// for the given [axisDirection].
  static bool _isForward(
    AxisDirection axisDirection,
    TraversalDirection direction,
  ) {
    switch (axisDirection) {
      case AxisDirection.down:
        return direction == TraversalDirection.down;
      case AxisDirection.up:
        return direction == TraversalDirection.up;
      case AxisDirection.right:
        return direction == TraversalDirection.right;
      case AxisDirection.left:
        return direction == TraversalDirection.left;
    }
  }
}
