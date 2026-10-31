import 'package:flutter/material.dart';

/// The Material primary when a [Theme] surrounds the item, white otherwise,
/// so default-colored effects work (and stay neutral) in Material-less apps.
///
/// Internal shared helper for the item effects and the flying-highlight
/// effects — not part of the package's public API.
Color defaultEffectColor(BuildContext context) {
  if (context.findAncestorWidgetOfExactType<Theme>() == null) {
    return const Color(0xFFFFFFFF);
  }
  return Theme.of(context).colorScheme.primary;
}
