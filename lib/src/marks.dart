import 'package:flutter/widgets.dart';

import 'highlight.dart';

/// Internal per-[FocusNode] annotations shared between [DpadFocusable] and
/// the traversal engine, without coupling them to each other.
abstract final class DpadMarks {
  /// Nodes owned by a `DpadFocusable`. Those handle their own auto-scroll,
  /// so the traversal policy must not scroll for them.
  static final Expando<bool> managed = Expando<bool>('dpad.managed');

  /// Nodes flagged as the entry item of their region
  /// (`DpadFocusable(entry: true)`).
  static final Expando<bool> entry = Expando<bool>('dpad.entry');

  /// Per-item flying-highlight overrides (`DpadFocusable(highlight: ...)`).
  ///
  /// A present value is the override — including [DpadHighlight.none], which
  /// opts the item out of the highlight entirely. Absent means "inherit from
  /// the enclosing [DpadHighlightTheme] or the [Dpad] root".
  static final Expando<DpadHighlight> highlightStyle =
      Expando<DpadHighlight>('dpad.highlightStyle');

  /// Whether the select key (or a pointer) is currently held down on the
  /// item that owns this node — the live press state for the flying
  /// highlight's [DpadHighlightState.pressed].
  static final Expando<bool> pressed = Expando<bool>('dpad.pressed');

  /// The programmatic press pulse of a `DpadFocusable` — the hook
  /// `DpadController.select()` fires so the item's presentation (and the
  /// flying highlight) react like a real key press. Absent on foreign
  /// nodes.
  static final Expando<VoidCallback> pressPulse =
      Expando<VoidCallback>('dpad.pressPulse');

  /// The item's steady-state focused scale — the product of its
  /// [DpadScaleEffect] factors. The flying highlight frames the scaled
  /// visual, not the un-scaled layout rect; absent (or from a custom
  /// builder, whose scale the package cannot know) means `1.0`.
  static final Expando<double> visualScale = Expando<double>();

  /// Returns the geometry of [node] in global coordinates, or `null` when
  /// the node is not attached to a laid-out render object or its geometry is
  /// not finite.
  static Rect? rectOf(FocusNode node) {
    final BuildContext? context = node.context;
    if (context == null || !context.mounted) {
      return null;
    }
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    final rect = MatrixUtils.transformRect(
      renderObject.getTransformTo(null),
      Offset.zero & renderObject.size,
    );
    // A non-finite rect is not usable geometry: an ancestor transform can go
    // non-finite for a frame (an overscroll stretch driven by a fling is the
    // usual case), and every caller already treats `null` as "no rect yet".
    return rect.isFinite ? rect : null;
  }

  /// Whether [node] can be focused right now.
  ///
  /// A node must be attached to the focus tree ([FocusNode.parent] set):
  /// after a `Focus` widget hands an externally owned node back, the node's
  /// `context` can keep pointing at a still-mounted (reused) element, so
  /// the context alone is not proof of life.
  static bool isUsable(FocusNode? node) {
    if (node == null || node.parent == null) {
      return false;
    }
    final BuildContext? context = node.context;
    return context != null && context.mounted && node.canRequestFocus;
  }

  /// The node of the [DpadFocusable] that owns [node] — [node] itself when
  /// it is a focusable's own node, otherwise the closest managed ancestor
  /// (a focusable with `excludeChildFocus: false` wrapping an inner focus
  /// target such as a text field), or `null` for foreign nodes.
  static FocusNode? itemOf(FocusNode node) {
    FocusNode? current = node;
    while (current != null) {
      if (managed[current] ?? false) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }

  /// Picks the item that should receive focus when nothing better is known:
  /// the first entry-marked node, otherwise the topmost one at the start of
  /// the reading order — the leftmost in LTR, the rightmost in RTL.
  static FocusNode? initialCandidate(Iterable<FocusNode> candidates) {
    FocusNode? best;
    double? bestTop;
    double? bestLeading;
    for (final FocusNode node in candidates) {
      final Rect? rect = rectOf(node);
      // An entry target still has to be focusable and laid out — a
      // disabled or unbuilt entry would strand the initial focus.
      if (rect == null || !node.canRequestFocus) {
        continue;
      }
      if (entry[node] ?? false) {
        return node;
      }
      // Negate the RTL leading edge so "smaller wins" means "reading start"
      // for both text directions.
      final BuildContext? context = node.context;
      final bool rtl = context != null &&
          Directionality.maybeOf(context) == TextDirection.rtl;
      final double leading = rtl ? -rect.right : rect.left;
      if (bestTop == null ||
          rect.top < bestTop - 0.01 ||
          (rect.top <= bestTop + 0.01 && leading < bestLeading!)) {
        best = node;
        bestTop = rect.top;
        bestLeading = leading;
      }
    }
    return best;
  }
}
