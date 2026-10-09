import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

/// Regression tests for the focus inspector (`debugOverlay: true`).
///
/// They live in their own file because the overlay is a debug tool with a
/// per-frame repaint: the interesting cases are the ones where the rect it
/// reads is not usable geometry yet.
void main() {
  testWidgets('a non-finite focused rect blanks the overlay, not the frame',
      (tester) async {
    // An ancestor transform can go non-finite for a frame — the framework's
    // stretch-overscroll effect does exactly that while a fling is in
    // flight — and the focused node's global rect then is not finite either.
    // The overlay repaints every frame, so rounding or positioning that rect
    // used to throw `UnsupportedError: Infinity or NaN toInt` once per frame.
    final node = FocusNode(debugLabel: 'hero-button');

    await tester.pumpWidget(tvApp(
      debugOverlay: true,
      // Excluded from semantics on purpose: the non-finite transform makes
      // every offset in this subtree non-finite, and the semantics tree
      // asserts on those independently of the overlay. This test is about the
      // overlay's geometry read, not about the framework's semantics.
      home: ExcludeSemantics(
        child: Transform(
          alignment: Alignment.topLeft,
          transform: Matrix4.diagonal3Values(double.infinity, 1.0, 1.0),
          child: item('a', node, autofocus: true),
        ),
      ),
    ));
    await tester.pump();

    expect(node.hasPrimaryFocus, isTrue,
        reason: 'the case only means something while a node is focused');
    expect(tester.takeException(), isNull,
        reason: 'the overlay must not throw for a non-finite rect');

    // The ticker repaints the overlay every frame; those must be clean too.
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
