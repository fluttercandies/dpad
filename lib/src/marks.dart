import 'package:flutter/widgets.dart';

/// Internal per-[FocusNode] annotations shared between [DpadFocusable] and
/// the traversal engine, without coupling them to each other.
abstract final class DpadMarks {
  /// Nodes owned by a `DpadFocusable`. Those handle their own auto-scroll,
  /// so the traversal policy must not scroll for them.
  static final Expando<bool> managed = Expando<bool>('dpad.managed');

  /// Nodes flagged as the entry item of their region
  /// (`DpadFocusable(entry: true)`).
  static final Expando<bool> entry = Expando<bool>('dpad.entry');

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

  /// Picks the item that should receive focus when nothing better is known:
  /// the first entry-marked node, otherwise the topmost one at the start of
  /// the reading order — the leftmost in LTR, the rightmost in RTL.
  static FocusNode? initialCandidate(Iterable<FocusNode> candidates) {
    FocusNode? best;
    double? bestTop;
    double? bestLeading;
    for (final FocusNode node in candidates) {
      if (entry[node] ?? false) {
        return node;
      }
      final Rect? rect = rectOf(node);
      if (rect == null) {
        continue;
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
