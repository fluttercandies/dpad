import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds a minimal TV app with the d-pad root installed the recommended
/// way (through `MaterialApp.builder`).
Widget tvApp({
  required Widget home,
  DpadThemeData? theme,
  DpadKeySet keySet = const DpadKeySet(),
  Map<LogicalKeyboardKey, VoidCallback> shortcuts =
      const <LogicalKeyboardKey, VoidCallback>{},
  bool Function()? onBack,
  VoidCallback? onMenu,
  ValueChanged<FocusNode?>? onFocusChange,
  bool debugOverlay = false,
  bool enabled = true,
  bool restoreFocus = true,
}) {
  return MaterialApp(
    builder: Dpad.wrap(
      theme: theme,
      keySet: keySet,
      shortcuts: shortcuts,
      onBack: onBack,
      onMenu: onMenu,
      onFocusChange: onFocusChange,
      debugOverlay: debugOverlay,
      enabled: enabled,
      restoreFocus: restoreFocus,
    ),
    home: Scaffold(body: home),
  );
}

/// A bare focusable square with no visual effects, for traversal tests.
Widget item(
  String id,
  FocusNode node, {
  VoidCallback? onSelect,
  VoidCallback? onLongSelect,
  ValueChanged<bool>? onFocusChange,
  DpadDirectionCallback? onDirection,
  bool autofocus = false,
  bool enabled = true,
  bool entry = false,
  double size = 60,
}) {
  return DpadFocusable(
    focusNode: node,
    autofocus: autofocus,
    enabled: enabled,
    entry: entry,
    onSelect: onSelect,
    onLongSelect: onLongSelect,
    onFocusChange: onFocusChange,
    onDirection: onDirection,
    effects: const <DpadEffect>[],
    child: SizedBox(
      width: size,
      height: size,
      child: Center(child: Text(id)),
    ),
  );
}
