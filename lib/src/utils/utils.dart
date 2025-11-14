import 'package:flutter/material.dart';

/// Utility class providing convenient methods for programmatic D-pad navigation.
///
/// This class offers static methods for controlling focus behavior programmatically,
/// allowing you to navigate, request focus, and manage focus state without
/// requiring user interaction with D-pad controls.
///
/// **Example Usage:**
/// ```dart
/// // Get current focus
/// final currentFocus = Dpad.currentFocus;
/// 
/// // Navigate programmatically
/// Dpad.navigateUp(context);
/// Dpad.navigateDown(context);
/// Dpad.navigateLeft(context);
/// Dpad.navigateRight(context);
/// 
/// // Request specific focus
/// Dpad.requestFocus(myFocusNode);
/// 
/// // Clear all focus
/// Dpad.clearFocus();
/// ```
///
/// **Use Cases:**
/// - Automatic focus management on screen changes
/// - Focus restoration after dialogs
/// - Programmatic navigation in response to gestures
/// - Custom navigation logic beyond D-pad controls
class Dpad {
  /// Gets the currently focused widget's FocusNode.
  /// 
  /// Returns the FocusNode of the widget that currently has focus,
  /// or `null` if no widget is currently focused.
  /// 
  /// **Example:**
  /// ```dart
  /// final currentFocus = Dpad.currentFocus;
  /// if (currentFocus != null) {
  ///   print('Widget has focus: ${currentFocus.debugLabel}');
  /// }
  /// ```
  static FocusNode? get currentFocus => FocusManager.instance.primaryFocus;

  /// Requests focus on the specified FocusNode.
  /// 
  /// Attempts to give focus to the provided FocusNode if it can receive focus.
  /// This is useful for programmatically setting focus on specific widgets.
  /// 
  /// **Parameters:**
  /// - [focusNode]: The FocusNode to request focus on, or null to do nothing
  /// 
  /// **Returns:** `true` if focus was successfully requested, `false` otherwise
  /// 
  /// **Example:**
  /// ```dart
  /// final success = Dpad.requestFocus(myButtonFocusNode);
  /// if (success) {
  ///   print('Focus successfully requested');
  /// }
  /// ```
  static bool requestFocus(FocusNode? focusNode) {
    if (focusNode != null && focusNode.canRequestFocus) {
      focusNode.requestFocus();
      return true;
    }
    return false;
  }

  /// Clears focus from the currently focused widget.
  /// 
  /// Removes focus from whatever widget currently has focus, leaving
  /// no widget focused. This is useful when you want to reset
  /// the focus state or prepare for focus changes.
  /// 
  /// **Example:**
  /// ```dart
  /// // Clear focus before showing a dialog
  /// Dpad.clearFocus();
  /// showDialog(...);
  /// ```
  static void clearFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Navigates focus in the specified direction.
  /// 
  /// Attempts to move focus from the currently focused widget to the next
  /// focusable widget in the specified direction.
  /// 
  /// **Parameters:**
  /// - [direction]: The direction to navigate (up, down, left, right)
  /// - [context]: The BuildContext to use for focus scope navigation
  /// 
  /// **Returns:** `true` if navigation was successful, `false` otherwise
  /// 
  /// **Note:** Navigation success depends on the layout and available
  /// focusable widgets in the specified direction.
  static bool navigateInDirection(
      TraversalDirection direction, BuildContext context) {
    return FocusScope.of(context).focusInDirection(direction);
  }

  /// Navigates focus upward.
  /// 
  /// Convenience method for navigating focus to the next focusable widget
  /// in the upward direction.
  /// 
  /// **Parameters:**
  /// - [context]: The BuildContext to use for focus navigation
  /// 
  /// **Returns:** `true` if upward navigation was successful
  /// 
  /// **Example:**
  /// ```dart
  /// // Handle volume up button
  /// Dpad.navigateUp(context);
  /// ```
  static bool navigateUp(BuildContext context) =>
      navigateInDirection(TraversalDirection.up, context);

  /// Navigates focus downward.
  /// 
  /// Convenience method for navigating focus to the next focusable widget
  /// in the downward direction.
  /// 
  /// **Parameters:**
  /// - [context]: The BuildContext to use for focus navigation
  /// 
  /// **Returns:** `true` if downward navigation was successful
  /// 
  /// **Example:**
  /// ```dart
  /// // Handle volume down button
  /// Dpad.navigateDown(context);
  /// ```
  static bool navigateDown(BuildContext context) =>
      navigateInDirection(TraversalDirection.down, context);

  /// Navigates focus leftward.
  /// 
  /// Convenience method for navigating focus to the next focusable widget
  /// in the leftward direction.
  /// 
  /// **Parameters:**
  /// - [context]: The BuildContext to use for focus navigation
  /// 
  /// **Returns:** `true` if leftward navigation was successful
  /// 
  /// **Example:**
  /// ```dart
  /// // Handle channel previous button
  /// Dpad.navigateLeft(context);
  /// ```
  static bool navigateLeft(BuildContext context) =>
      navigateInDirection(TraversalDirection.left, context);

  /// Navigates focus rightward.
  /// 
  /// Convenience method for navigating focus to the next focusable widget
  /// in the rightward direction.
  /// 
  /// **Parameters:**
  /// - [context]: The BuildContext to use for focus navigation
  /// 
  /// **Returns:** `true` if rightward navigation was successful
  /// 
  /// **Example:**
  /// ```dart
  /// // Handle channel next button
  /// Dpad.navigateRight(context);
  /// ```
  static bool navigateRight(BuildContext context) =>
      navigateInDirection(TraversalDirection.right, context);
}
