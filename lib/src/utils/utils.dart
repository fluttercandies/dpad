import 'package:flutter/material.dart';

/// Utility class providing convenient methods for programmatic D-pad navigation.
class Dpad {
  /// Gets currently focused widget's FocusNode.
  static FocusNode? get currentFocus => FocusManager.instance.primaryFocus;

  /// Requests focus on specified FocusNode.
  static bool requestFocus(FocusNode? focusNode) {
    if (focusNode != null && focusNode.canRequestFocus) {
      focusNode.requestFocus();
      return true;
    }
    return false;
  }

  /// Clears focus from currently focused widget.
  static void clearFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Navigates focus in the specified direction.
  static bool navigateInDirection(
      TraversalDirection direction, BuildContext context) {
    return FocusScope.of(context).focusInDirection(direction);
  }

  /// Navigates focus upward.
  static bool navigateUp(BuildContext context) =>
      navigateInDirection(TraversalDirection.up, context);

  /// Navigates focus downward.
  static bool navigateDown(BuildContext context) =>
      navigateInDirection(TraversalDirection.down, context);

  /// Navigates focus leftward.
  static bool navigateLeft(BuildContext context) =>
      navigateInDirection(TraversalDirection.left, context);

  /// Navigates focus rightward.
  static bool navigateRight(BuildContext context) =>
      navigateInDirection(TraversalDirection.right, context);
}
