import 'package:flutter/material.dart';

import '../navigation/dpad_navigator.dart';
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
/// // Focus memory utilities (requires context for navigator-scoped history)
/// final previousEntry = Dpad.getPreviousFocus(context);
/// final currentEntry = Dpad.getCurrentFocusEntry(context);
/// final history = Dpad.getFocusHistory(context);
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
  ///   // Widget has focus: ${currentFocus.debugLabel}
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
  ///   // Focus successfully requested
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
  /// Uses the navigator-scoped history manager from the given context.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for navigator-scoped history
  ///
  /// **Returns:** The current focus entry, or null if no focus or no navigator found
  ///
  /// **Example:**
  /// ```dart
  /// final currentEntry = Dpad.getCurrentFocusEntry(context);
  /// if (currentEntry != null) {
  ///   // Current region: ${currentEntry.region}
  /// }
  /// ```
  static FocusHistoryEntry? getCurrentFocusEntry(BuildContext context) {
    return DpadNavigator.historyOf(context)?.getCurrent();
  }

  /// Gets the previous focus entry for memory restoration.
  ///
  /// Uses the navigator-scoped history manager from the given context.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for navigator-scoped history
  ///
  /// **Returns:** The previous focus entry, or null if none exists or no navigator found
  ///
  /// **Example:**
  /// ```dart
  /// final previousEntry = Dpad.getPreviousFocus(context);
  /// if (previousEntry != null) {
  ///   // Previous region: ${previousEntry.region}
  /// }
  /// ```
  static FocusHistoryEntry? getPreviousFocus(BuildContext context) {
    return DpadNavigator.historyOf(context)?.getPrevious();
  }

  /// Gets the complete focus history as a list.
  ///
  /// Uses the navigator-scoped history manager from the given context.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for navigator-scoped history
  ///
  /// **Returns:** Complete list of focus history entries, empty if no navigator found
  ///
  /// **Example:**
  /// ```dart
  /// final history = Dpad.getFocusHistory(context);
  /// for (final entry in history) {
  ///   // Region: ${entry.region}, Route: ${entry.routeName}
  /// }
  /// ```
  static List<FocusHistoryEntry> getFocusHistory(BuildContext context) {
    return DpadNavigator.historyOf(context)?.getHistory() ?? [];
  }

  /// Clears all focus history entries and resets the memory state.
  ///
  /// Uses the navigator-scoped history manager from the given context.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for navigator-scoped history
  ///
  /// **Example:**
  /// ```dart
  /// Dpad.clearFocusHistory(context);
  /// ```
  static void clearFocusHistory(BuildContext context) {
    DpadNavigator.historyOf(context)?.clear();
  }

  /// Scrolls to ensure the focused widget is fully visible with proper padding.
  ///
  /// This method intelligently scrolls to make the focused widget fully visible,
  /// including any visual effects like focus glow, shadows, or borders.
  /// It handles both horizontal and vertical scrolling, and ensures the widget
  /// is not positioned at the edge of the viewport.
  ///
  /// **Features:**
  /// - Adds padding around the focused widget to show focus effects
  /// - Handles both horizontal and vertical scroll containers
  /// - Positions the widget with comfortable margins from viewport edges
  /// - Smooth animation with customizable duration and curve
  ///
  /// **Parameters:**
  /// - [focusNode]: The focus node to scroll into view
  /// - [padding]: Extra padding around the widget (default: 24.0)
  /// - [duration]: Animation duration (default: 300ms)
  /// - [curve]: Animation curve (default: Curves.easeOutCubic)
  static void scrollToFocus(
    FocusNode focusNode, {
    double padding = 24.0,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    if (focusNode.context == null || !focusNode.canRequestFocus) return;

    final context = focusNode.context!;

    try {
      // Get the RenderObject of the focused widget
      final renderObject = context.findRenderObject();
      if (renderObject == null || renderObject is! RenderBox) return;

      // Find all scrollable ancestors and scroll each one
      _scrollAllAncestors(
        context,
        renderObject,
        padding: padding,
        duration: duration,
        curve: curve,
      );
    } catch (e) {
      // Fallback to simple ensureVisible if smart scrolling fails
      try {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: duration,
          curve: curve,
        );
      } catch (_) {
        // Silently fail if scrolling is not possible
      }
    }
  }

  /// Scrolls all scrollable ancestors to ensure the widget is visible.
  static void _scrollAllAncestors(
    BuildContext context,
    RenderBox renderBox, {
    required double padding,
    required Duration duration,
    required Curve curve,
  }) {
    // Find all Scrollable ancestors
    final scrollables = <ScrollableState>[];
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        scrollables.add(element.state as ScrollableState);
      }
      return true;
    });

    // Scroll each scrollable ancestor
    for (final scrollable in scrollables) {
      _scrollInScrollable(
        scrollable,
        renderBox,
        padding: padding,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Scrolls within a specific scrollable to ensure the widget is visible.
  static void _scrollInScrollable(
    ScrollableState scrollable,
    RenderBox targetRenderBox, {
    required double padding,
    required Duration duration,
    required Curve curve,
  }) {
    final scrollableRenderBox =
        scrollable.context.findRenderObject() as RenderBox?;
    if (scrollableRenderBox == null) return;

    final position = scrollable.position;
    final axis = scrollable.axisDirection;
    final isHorizontal =
        axis == AxisDirection.left || axis == AxisDirection.right;

    // Get the target's position relative to the scrollable
    final targetOffset = targetRenderBox.localToGlobal(
      Offset.zero,
      ancestor: scrollableRenderBox,
    );

    // Get sizes
    final targetSize = targetRenderBox.size;
    final viewportSize = scrollableRenderBox.size;

    // Calculate the target's bounds in the scrollable's coordinate system
    final double targetStart;
    final double targetEnd;
    final double viewportExtent;

    if (isHorizontal) {
      targetStart = targetOffset.dx;
      targetEnd = targetOffset.dx + targetSize.width;
      viewportExtent = viewportSize.width;
    } else {
      targetStart = targetOffset.dy;
      targetEnd = targetOffset.dy + targetSize.height;
      viewportExtent = viewportSize.height;
    }

    // Calculate the ideal scroll offset to center the target with padding
    final targetCenter = (targetStart + targetEnd) / 2;
    final viewportCenter = viewportExtent / 2;

    // Check if the target is already well-positioned
    final minVisibleStart = padding;
    final maxVisibleEnd = viewportExtent - padding;

    // Target is fully visible with padding
    if (targetStart >= minVisibleStart && targetEnd <= maxVisibleEnd) {
      return; // No scrolling needed
    }

    // Calculate how much to scroll
    double scrollDelta = 0.0;

    if (targetEnd > maxVisibleEnd) {
      // Target is cut off at the end - scroll forward
      // Position the target so its end is at maxVisibleEnd
      scrollDelta = targetEnd - maxVisibleEnd + padding;
    } else if (targetStart < minVisibleStart) {
      // Target is cut off at the start - scroll backward
      // Position the target so its start is at minVisibleStart
      scrollDelta = targetStart - minVisibleStart - padding;
    }

    // If target is larger than viewport, center it
    final targetExtent = targetEnd - targetStart;
    if (targetExtent + padding * 2 > viewportExtent) {
      scrollDelta = targetCenter - viewportCenter;
    }

    // Calculate new scroll position
    final currentOffset = position.pixels;
    final newOffset = (currentOffset + scrollDelta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    // Only animate if there's actually a change
    if ((newOffset - currentOffset).abs() > 0.5) {
      position.animateTo(
        newOffset,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Safely requests focus on a FocusNode with validation.
  ///
  /// This method checks if the FocusNode is still valid before attempting
  /// to request focus, preventing errors with disposed nodes.
  ///
  /// [focusNode] The focus node to request focus on
  /// **Returns:** `true` if focus was successfully requested, `false` otherwise
  static bool requestFocusSafely(FocusNode? focusNode) {
    if (focusNode == null) return false;

    // Check if FocusNode can still request focus
    if (!focusNode.canRequestFocus) {
      return false;
    }

    try {
      focusNode.requestFocus();
      // Additional check: verify focus was actually granted
      // This helps catch edge cases where disposed nodes don't throw exceptions
      return FocusManager.instance.primaryFocus == focusNode;
    } catch (e) {
      // Focus request failed (likely due to disposal during operation)
      return false;
    }
  }
}
