import 'package:flutter/material.dart';
import 'focus_history.dart';

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
/// 
/// // Focus memory utilities
/// final previousEntry = Dpad.getPreviousFocus();
/// final currentEntry = Dpad.getCurrentFocusEntry();
/// final history = Dpad.getFocusHistory();
/// ```
///
/// **Use Cases:**
/// - Automatic focus management on screen changes
/// - Focus restoration after dialogs
/// - Programmatic navigation in response to gestures
/// - Custom navigation logic beyond D-pad controls
/// - Focus memory management and restoration
final class Dpad {

  Dpad._();

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

  /// Navigates focus to the next widget in the focus traversal order.
  /// 
  /// This method follows the logical focus order rather than spatial positioning,
  /// making it ideal for sequential navigation like media controls, lists,
  /// or form fields. Equivalent to pressing the Tab key.
  /// 
  /// **Parameters:**
  /// - [context]: The BuildContext to use for focus navigation
  /// 
  /// **Returns:** `true` if navigation to the next widget was successful
  /// 
  /// **Example:**
  /// ```dart
  /// // Handle media next button
  /// Dpad.navigateNext(context);
  /// 
  /// // Navigate to next form field
  /// Dpad.navigateNext(context);
  /// ```
  static bool navigateNext(BuildContext context) {
    return FocusScope.of(context).nextFocus();
  }

  /// Navigates focus to the previous widget in the focus traversal order.
  /// 
  /// This method follows the logical focus order in reverse, making it ideal
  /// for sequential navigation like media controls, lists, or form fields.
  /// Equivalent to pressing Shift+Tab.
  /// 
  /// **Parameters:**
  /// - [context]: The BuildContext to use for focus navigation
  /// 
  /// **Returns:** `true` if navigation to the previous widget was successful
  /// 
  /// **Example:**
  /// ```dart
  /// // Handle media previous button
  /// Dpad.navigatePrevious(context);
  /// 
  /// // Navigate to previous form field
  /// Dpad.navigatePrevious(context);
  /// ```
  static bool navigatePrevious(BuildContext context) {
    return FocusScope.of(context).previousFocus();
  }

  /// Gets the current focus entry with complete information.
  /// 
  /// Returns the current focus entry with region, route, and other metadata.
  /// 
  /// **Returns:** The current focus entry, or null if no focus
  /// 
  /// **Example:**
  /// ```dart
  /// final currentEntry = Dpad.getCurrentFocusEntry();
  /// if (currentEntry != null) {
  ///   print('Current region: ${currentEntry.region}');
  /// }
  /// ```
  static FocusHistoryEntry? getCurrentFocusEntry() {
    return FocusHistory.getCurrent();
  }

  /// Gets the previous focus entry for memory restoration.
  /// 
  /// Returns the entry before the current one, used for focus memory restoration.
  /// 
  /// **Returns:** The previous focus entry, or null if none exists
  /// 
  /// **Example:**
  /// ```dart
  /// final previousEntry = Dpad.getPreviousFocus();
  /// if (previousEntry != null) {
  ///   print('Previous region: ${previousEntry.region}');
  /// }
  /// ```
  static FocusHistoryEntry? getPreviousFocus() {
    return FocusHistory.getPrevious();
  }

  /// Gets the complete focus history as a list.
  /// 
  /// Returns the complete focus history stack for analysis and custom logic.
  /// 
  /// **Returns:** Complete list of focus history entries
  /// 
  /// **Example:**
  /// ```dart
  /// final history = Dpad.getFocusHistory();
  /// for (final entry in history) {
  ///   print('Region: ${entry.region}, Route: ${entry.routeName}');
  /// }
  /// ```
  static List<FocusHistoryEntry> getFocusHistory() {
    return FocusHistory.getHistory();
  }

  /// Clears all focus history entries and resets the memory state.
  /// 
  /// Clears all recorded focus history, resetting the focus memory state.
  /// 
  /// **Example:**
  /// ```dart
  /// Dpad.clearFocusHistory();
  /// ```
  static void clearFocusHistory() {
    FocusHistory.clear();
  }

  /// Scrolls to focused widget using Flutter's built-in ensureVisible method.
  /// 
  /// Uses the official Flutter SDK method to handle all scrolling logic.
  /// 
  /// [focusNode] The focus node to scroll into view
  static void scrollToFocus(FocusNode focusNode) {
    if (focusNode.context == null) return;
    
    try {
      // Simply use Flutter's ensureVisible with center alignment
      // Let Flutter handle all the edge detection and scrolling logic
      Scrollable.ensureVisible(
        focusNode.context!,
        alignment: 0.4, // Slightly above center to avoid bottom edge issues
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } catch (e) {
      // Silently fail if scrolling is not possible
    }
  }
}

