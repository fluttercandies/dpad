import 'package:flutter/material.dart';

/// The demo's near-black page background.
const Color kPageBackground = Color(0xFF0E1116);

/// Shared surface language for the floating layers (dialogs and the
/// options sheet): a subtle top-lit dark gradient.
const LinearGradient kSurfaceGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: <Color>[Color(0xFF1E2431), Color(0xFF151A23)],
);
