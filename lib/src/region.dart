import 'package:flutter/widgets.dart';

import 'marks.dart';
import 'traversal.dart';

/// What happens when d-pad navigation reaches the boundary of a [DpadRegion]
/// from a given direction (per-direction overrides on [DpadRegion] pick the
/// effective value for each key).
enum DpadEdgeBehavior {
  /// Focus leaves the region and continues to the geometrically best target
  /// outside it. This is the default.
  leave,

  /// Focus stays put. The key press is consumed and [DpadRegion.onEdge] is
  /// invoked — use it for an edge "bump" animation or a sound.
  ///
  /// Ideal for panels that navigation must not accidentally escape.
  stop,

  /// Focus wraps around to the opposite side of the region, carousel-style.
  ///
  /// While wrapping is enabled on an axis, focus never leaves the region on
  /// that axis.
  wrap,

  /// Focus steps to the next *line* of a grid, typewriter-style: right from
  /// the last cell of a row moves to the first cell of the row below, and
  /// left from the first cell of a row moves to the last cell of the row
  /// above (symmetrically for columns with up/down).
  ///
  /// The step follows the reading order: in RTL layouts — where rows read
  /// right-to-left — `left` steps to the line below and `right` back up.
  ///
  /// While the current line still has an in-beam candidate ahead, focus
  /// moves along the line; once it runs out, the line step wins over
  /// diagonal (out-of-beam) candidates, keeping the movement strictly
  /// typewriter.
  ///
  /// Unlike [wrap], which returns to the start of the *same* row, this is the
  /// behavior grids and multi-row carousels want. While line wrapping is
  /// enabled on an axis, focus never leaves the region on that axis; at the
  /// first/last line of the grid the key press is consumed and
  /// [DpadRegion.onEdge] is invoked. If the next line is not built yet (lazy
  /// grids), the engine scrolls and retries, like directional traversal.
  lineWrap,
}

/// How a [DpadRegion] chooses which item receives focus when d-pad
/// navigation enters it from another region.
enum DpadEnterBehavior {
  /// Restore focus to the item that was focused the last time the region
  /// held focus — the behavior users expect from TV rows and sidebars.
  ///
  /// Falls back to the entry item (see [DpadFocusable.entry]), then to the
  /// geometrically nearest item, when there is nothing to restore.
  /// This is the default.
  restore,

  /// Always focus the region's entry item ([DpadFocusable.entry]); falls
  /// back to the geometrically nearest item when none is marked.
  entry,

  /// Focus the geometrically nearest item, like plain Flutter traversal.
  nearest,
}

/// Groups focusables into a navigation area with TV semantics.
///
/// Real TV interfaces are built from *regions* — a sidebar, a row of
/// posters, a grid of settings. [DpadRegion] gives a subtree those
/// semantics declaratively:
///
/// * **Region-first navigation** — d-pad movement prefers items inside the
///   current region before considering anything outside it, even when an
///   outside widget is geometrically closer.
/// * **Focus memory** — when focus re-enters the region it returns to the
///   last focused item ([DpadEnterBehavior.restore]).
/// * **Edge control** — each direction independently chooses whether focus
///   leaves, stops, wraps or line-wraps at the region boundary
///   ([DpadEdgeBehavior]).
///
/// ```dart
/// DpadRegion(
///   // A carousel: wrap horizontally, remember the selected poster.
///   horizontalEdge: DpadEdgeBehavior.wrap,
///   child: SizedBox(
///     height: 200,
///     child: ListView(scrollDirection: Axis.horizontal, children: posters),
///   ),
/// )
/// ```
///
/// Regions nest; every [DpadFocusable] belongs to its *nearest* enclosing
/// region.
class DpadRegion extends StatefulWidget {
  /// Creates a navigation region around [child].
  const DpadRegion({
    super.key,
    required this.child,
    this.enter = DpadEnterBehavior.restore,
    this.horizontalEdge = DpadEdgeBehavior.leave,
    this.verticalEdge = DpadEdgeBehavior.leave,
    this.leftEdge,
    this.rightEdge,
    this.upEdge,
    this.downEdge,
    this.memoryKey,
    this.onEdge,
    this.onFocusChange,
    this.debugLabel,
  });

  /// The subtree whose focusables belong to this region.
  final Widget child;

  /// Persists this region's focus memory across rebuilds.
  ///
  /// Without a key, memory lives in the region's [State] and is lost when
  /// the subtree is rebuilt from scratch — the classic TV pitfall of a
  /// section switcher (`IndexedStack`-less tabs) forgetting where the user
  /// was. Give the region a stable app-unique string and its memory
  /// survives any rebuild:
  ///
  /// ```dart
  /// DpadRegion(
  ///   memoryKey: 'home/trending-row',
  ///   child: trendingRow,
  /// )
  /// ```
  ///
  /// Restoration is position-aware: if the exact item instance is gone
  /// (rebuilt), the item closest to the remembered position is chosen.
  ///
  /// The memory outlives the region itself, so conditionally-rendered
  /// sections can be switched back and forth without losing their place.
  /// Each entry holds its [FocusNode] weakly, so a collected node is not
  /// kept alive; the entry itself (with its remembered position, which
  /// position-aware restoration still uses) stays under its key until it
  /// is overwritten or [DpadRegionState.clearPersistentMemory] is called —
  /// keep keys stable and bounded, as with any cache key.
  final String? memoryKey;

  /// How focus enters this region from outside. Defaults to
  /// [DpadEnterBehavior.restore].
  final DpadEnterBehavior enter;

  /// What happens when navigating left or right past the region's last item.
  final DpadEdgeBehavior horizontalEdge;

  /// What happens when navigating up or down past the region's last item.
  final DpadEdgeBehavior verticalEdge;

  /// Overrides [DpadRegion.horizontalEdge] for the left boundary only.
  ///
  /// Direction names are *physical* — they name the remote's keys, exactly
  /// like [TraversalDirection] — so `leftEdge` always governs the left
  /// arrow, in LTR and RTL layouts alike. Behaviors that follow the
  /// reading order ([DpadEdgeBehavior.lineWrap], initial focus placement)
  /// resolve RTL automatically and need no per-directionality configuration.
  ///
  /// Per-direction edges express layouts an axis-wide behavior cannot: a
  /// carousel that wraps to the right but lets `left` exit towards a
  /// navigation rail, or a grid row that stops at its end while `left`
  /// still reaches the rail:
  ///
  /// ```dart
  /// DpadRegion(
  ///   horizontalEdge: DpadEdgeBehavior.stop,
  ///   leftEdge: DpadEdgeBehavior.leave, // only the rail stays reachable
  ///   child: row,
  /// )
  /// ```
  final DpadEdgeBehavior? leftEdge;

  /// Overrides [DpadRegion.horizontalEdge] for the right boundary only.
  /// See [DpadRegion.leftEdge] for when per-direction edges pay off.
  final DpadEdgeBehavior? rightEdge;

  /// Overrides [DpadRegion.verticalEdge] for the top boundary only.
  /// See [DpadRegion.leftEdge] for when per-direction edges pay off.
  final DpadEdgeBehavior? upEdge;

  /// Overrides [DpadRegion.verticalEdge] for the bottom boundary only.
  /// See [DpadRegion.leftEdge] for when per-direction edges pay off.
  final DpadEdgeBehavior? downEdge;

  /// Called when a key press hits a [DpadEdgeBehavior.stop] boundary, a
  /// [DpadEdgeBehavior.wrap] boundary with nothing to wrap to, or the
  /// first/last line of a [DpadEdgeBehavior.lineWrap] grid.
  final ValueChanged<TraversalDirection>? onEdge;

  /// Called with `true` when focus enters the region and `false` when it
  /// leaves — handy for highlighting the active section.
  final ValueChanged<bool>? onFocusChange;

  /// A label shown in focus debug output.
  final String? debugLabel;

  /// The state of the closest enclosing [DpadRegion], if any.
  ///
  /// Does not establish a build dependency.
  static DpadRegionState? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_DpadRegionScope>()?.state;
  }

  /// The region that [node] belongs to, if any.
  static DpadRegionState? ofNode(FocusNode node) {
    final BuildContext? context = node.context;
    if (context == null || !context.mounted) {
      return null;
    }
    return maybeOf(context);
  }

  @override
  State<DpadRegion> createState() => DpadRegionState();
}

/// The runtime state of a [DpadRegion].
///
/// Exposes the region's focus memory so advanced callers (and the built-in
/// traversal policy) can query and steer it.
class DpadRegionState extends State<DpadRegion> {
  /// Memory persisted across State recreations, keyed by
  /// [DpadRegion.memoryKey].
  static final Map<String, _RegionMemory> _persistentMemory =
      <String, _RegionMemory>{};

  /// Clears the persistent memory stored under [memoryKey], or all
  /// persistent region memory when [memoryKey] is null.
  static void clearPersistentMemory([String? memoryKey]) {
    if (memoryKey == null) {
      _persistentMemory.clear();
    } else {
      _persistentMemory.remove(memoryKey);
    }
  }

  late final FocusNode _marker = FocusNode(
    debugLabel: 'DpadRegion(${widget.debugLabel ?? hashCode})',
  );

  // A stable instance: a fresh policy in every build would make
  // FocusTraversalGroup.didUpdateWidget re-set the group's policy each time.
  late final DpadTraversalPolicy _policy = DpadTraversalPolicy();

  FocusNode? _lastFocused;
  Rect? _lastFocusedRect;

  @override
  void initState() {
    super.initState();
    _loadPersistentMemory();
  }

  @override
  void didUpdateWidget(DpadRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memoryKey != widget.memoryKey) {
      _loadPersistentMemory();
    }
  }

  void _loadPersistentMemory() {
    final _RegionMemory? persisted = _persistentMemory[widget.memoryKey];
    if (persisted != null) {
      _lastFocused = persisted.node.target;
      _lastFocusedRect = persisted.rect;
    }
  }

  /// The item that most recently held focus inside this region, if it is
  /// still focusable.
  FocusNode? get lastFocused =>
      DpadMarks.isUsable(_lastFocused) ? _lastFocused : null;

  /// How focus enters this region. See [DpadRegion.enter].
  DpadEnterBehavior get enterBehavior => widget.enter;

  /// All currently traversable focus nodes that belong to this region
  /// (excluding ones owned by nested regions).
  Iterable<FocusNode> get focusNodes {
    return _marker.traversalDescendants.where(
      (FocusNode node) => identical(DpadRegion.ofNode(node), this),
    );
  }

  /// The edge behavior governing [direction].
  ///
  /// Per-direction overrides ([DpadRegion.leftEdge] and friends) win over
  /// the axis-wide defaults.
  DpadEdgeBehavior edgeBehaviorFor(TraversalDirection direction) {
    switch (direction) {
      case TraversalDirection.left:
        return widget.leftEdge ?? widget.horizontalEdge;
      case TraversalDirection.right:
        return widget.rightEdge ?? widget.horizontalEdge;
      case TraversalDirection.up:
        return widget.upEdge ?? widget.verticalEdge;
      case TraversalDirection.down:
        return widget.downEdge ?? widget.verticalEdge;
    }
  }

  /// Records [node] as the region's focus memory.
  ///
  /// Called automatically whenever an item inside the region gains focus.
  void noteFocus(FocusNode node) {
    _lastFocused = node;
    _lastFocusedRect = DpadMarks.rectOf(node) ?? _lastFocusedRect;
    final String? key = widget.memoryKey;
    if (key != null) {
      _persistentMemory[key] =
          _RegionMemory(WeakReference(node), _lastFocusedRect);
    }
  }

  /// Drops [node] from the focus memory, keeping its last known position as
  /// a geometric fallback. Called when a focusable is disposed.
  void forget(FocusNode node) {
    if (identical(_lastFocused, node)) {
      _lastFocused = null;
    }
  }

  /// Clears the focus memory entirely (including the persistent memory
  /// under [DpadRegion.memoryKey], if any).
  void clearMemory() {
    _lastFocused = null;
    _lastFocusedRect = null;
    final String? key = widget.memoryKey;
    if (key != null) {
      _persistentMemory.remove(key);
    }
  }

  /// Notifies [DpadRegion.onEdge] that navigation hit the region boundary.
  void notifyEdge(TraversalDirection direction) {
    widget.onEdge?.call(direction);
  }

  /// Resolves the item that should receive focus when navigation enters
  /// this region, given the geometrically [nearest] candidate and the
  /// region's [candidates].
  FocusNode resolveEnter(FocusNode nearest, List<FocusNode> candidates) {
    switch (widget.enter) {
      case DpadEnterBehavior.nearest:
        return nearest;
      case DpadEnterBehavior.entry:
        return _entryNode(candidates) ?? nearest;
      case DpadEnterBehavior.restore:
        final FocusNode? remembered = lastFocused;
        if (remembered != null && candidates.contains(remembered)) {
          return remembered;
        }
        final FocusNode? nearLastRect = _nearestToMemory(candidates);
        if (nearLastRect != null) {
          return nearLastRect;
        }
        return _entryNode(candidates) ?? nearest;
    }
  }

  FocusNode? _entryNode(List<FocusNode> candidates) {
    for (final FocusNode node in candidates) {
      if (DpadMarks.entry[node] ?? false) {
        return node;
      }
    }
    return null;
  }

  FocusNode? _nearestToMemory(List<FocusNode> candidates) {
    final Rect? memory = _lastFocusedRect;
    if (memory == null) {
      return null;
    }
    FocusNode? best;
    double bestDistance = double.infinity;
    for (final FocusNode node in candidates) {
      final Rect? rect = DpadMarks.rectOf(node);
      if (rect == null) {
        continue;
      }
      final double distance = (rect.center - memory.center).distanceSquared;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = node;
      }
    }
    return best;
  }

  @override
  void dispose() {
    _marker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: _policy,
      child: Focus(
        focusNode: _marker,
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onFocusChange: widget.onFocusChange,
        child: _DpadRegionScope(state: this, child: widget.child),
      ),
    );
  }
}

class _DpadRegionScope extends InheritedWidget {
  const _DpadRegionScope({required this.state, required super.child});

  final DpadRegionState state;

  @override
  bool updateShouldNotify(_DpadRegionScope oldWidget) =>
      state != oldWidget.state;
}

class _RegionMemory {
  _RegionMemory(this.node, this.rect);

  final WeakReference<FocusNode> node;
  final Rect? rect;
}
