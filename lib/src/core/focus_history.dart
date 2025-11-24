import 'package:flutter/material.dart';

/// Focus history entry containing complete information for intelligent focus restoration.
///
/// Stores focus position, region, route, and other metadata for smart back navigation.
class FocusHistoryEntry {
  /// The focus node
  final FocusNode focusNode;

  /// Region identifier (e.g., 'tabs', 'filters', 'cards')
  final String? region;

  /// Route object
  final Route<dynamic>? route;

  /// Timestamp of when focus was recorded
  final DateTime timestamp;

  /// Debug label for identification
  final String? debugLabel;

  FocusHistoryEntry({
    required this.focusNode,
    this.region,
    this.route,
    this.debugLabel,
  }) : timestamp = DateTime.now();

  /// Checks if this focus entry is still valid and can be used.
  ///
  /// An entry is considered valid if:
  /// - The FocusNode can still request focus
  /// - The FocusNode has a valid context (if available)
  ///
  /// **Note:** A null context is valid for FocusNodes that haven't been attached
  /// to the widget tree yet but are still functional.
  ///
  /// **Returns:** `true` if the entry is valid and safe to use
  bool get isValid {
    // Multiple validation checks for disposed FocusNode
    // FocusNode.dispose() might not immediately update canRequestFocus in all cases
    try {
      // Try to access a debug property immediately - this will throw if disposed
      // This is the most reliable way to detect disposed state
      focusNode.debugLabel;

      // Check if FocusNode has been disposed
      if (!focusNode.canRequestFocus) {
        return false;
      }

      // Try to access context owner - will fail if disposed
      if (focusNode.context != null) {
        focusNode.context!.owner;
      }

      // Additional check: try to access listeners array
      // This will throw if the FocusNode is disposed
      focusNode.hasListeners;

      return true;
    } catch (e) {
      // Any exception indicates the FocusNode is disposed
      return false;
    }
  }

  /// Attempts to safely request focus on this entry's FocusNode.
  ///
  /// This method validates that the entry is still valid before
  /// attempting to request focus. If the entry is invalid, it returns false.
  /// Includes additional safeguards to handle race conditions during disposal.
  ///
  /// **Returns:** `true` if focus was successfully requested, `false` otherwise
  bool requestFocusSafely() {
    try {
      // First check if FocusNode can still request focus
      // This is the most reliable check for disposed state
      if (!focusNode.canRequestFocus) {
        return false;
      }

      // Additional validation: try to access debug properties
      // These will throw if FocusNode is disposed
      focusNode.debugLabel;
      focusNode.hasListeners;

      focusNode.requestFocus();

      // Final verification: check if focus was actually granted
      return FocusManager.instance.primaryFocus == focusNode;
    } catch (e) {
      // Focus request failed (likely due to disposal during operation)
      return false;
    }
  }

  @override
  String toString() {
    final status = isValid ? 'valid' : 'invalid';
    return 'FocusEntry(${debugLabel ?? focusNode.hashCode}, region: $region, route: ${route?.settings.name}, status: $status)';
  }
}

/// Focus history manager using stack structure for focus memory restoration.
///
/// Manages focus history with push/pop operations and intelligent restoration.
///
/// **Memory Management:** Automatically cleans up disposed FocusNodes to prevent
/// memory leaks. Call [cleanup] periodically or when widgets are destroyed.
final class FocusHistory {
  const FocusHistory._();

  static final List<FocusHistoryEntry> _stack = [];
  static int _maxSize = 20;

  static FocusHistoryEntry? _lastPoppedEntry;

  /// Pushes focus entry to the history stack.
  ///
  /// [entry] The focus entry to record
  static void push(FocusHistoryEntry entry) {
    // Avoid adding duplicate focus entries
    if (_stack.isEmpty || _stack.last.focusNode != entry.focusNode) {
      _stack.add(entry);

      // Limit stack size
      if (_stack.length > _maxSize) {
        _stack.removeAt(0); // Remove from bottom
      }
    }
  }

  /// Gets the current focus entry.
  ///
  /// Returns the top focus entry in the stack, or null if empty
  static FocusHistoryEntry? getCurrent() {
    return _stack.isNotEmpty ? _stack.last : null;
  }

  /// Gets the previous focus entry.
  ///
  /// Returns the entry before the current one, or null if none exists
  static FocusHistoryEntry? getPrevious() {
    return _stack.length >= 2 ? _stack[_stack.length - 2] : null;
  }

  /// Pops the current focus entry from the stack.
  ///
  /// Removes and returns the top focus entry, or null if empty
  static FocusHistoryEntry? pop() {
    _lastPoppedEntry = _stack.isNotEmpty ? _stack.removeLast() : null;
    return _lastPoppedEntry;
  }

  /// Gets the last popped focus entry.
  static FocusHistoryEntry? getLastPoppedEntry() {
    return _lastPoppedEntry;
  }

  /// Gets the complete history as a read-only list.
  ///
  /// Returns an unmodifiable copy of the history stack
  static List<FocusHistoryEntry> getHistory() {
    return List.unmodifiable(_stack);
  }

  static bool get isEmpty => _stack.isEmpty;

  /// Clears all focus history entries.
  static void clear() {
    _stack.clear();
  }

  /// Removes invalid entries from the history stack.
  ///
  /// This method iterates through the history and removes any entries
  /// whose FocusNodes are no longer valid (disposed or cannot request focus).
  /// Useful for cleanup when widgets are destroyed.
  ///
  /// **Returns:** The number of invalid entries that were removed
  static int removeInvalidEntries() {
    final initialSize = _stack.length;
    if (initialSize == 0) return 0;

    _stack.removeWhere((entry) => !entry.isValid);
    return initialSize - _stack.length;
  }

  /// Manual cleanup method to free memory from disposed FocusNodes.
  ///
  /// This can be called when widgets are destroyed or periodically
  /// to ensure memory doesn't leak from retained FocusNode references.
  ///
  /// **Note:** [push] automatically calls cleanup periodically,
  /// but this method provides explicit control when needed.
  static void cleanup() {
    removeInvalidEntries();
  }

  /// Sets the maximum number of history entries to keep.
  ///
  /// [size] The maximum number of entries
  static void setMaxSize(int size) {
    _maxSize = size;

    // Adjust current stack size if needed
    while (_stack.length > _maxSize) {
      _stack.removeAt(0);
    }
  }

  /// Gets the last focus entry for a specific region.
  ///
  /// [region] The region identifier
  /// Returns the last entry in the specified region, or null if none found
  static FocusHistoryEntry? getLastFocusInRegion(String region) {
    for (int i = _stack.length - 1; i >= 0; i--) {
      final entry = _stack.elementAt(i);
      if (entry.region == region) {
        return entry;
      }
    }
    return null;
  }

  /// Gets the last focus entry for a specific route.
  ///
  /// [routeName] The route name
  /// Returns the last entry in the specified route, or null if none found
  static FocusHistoryEntry? getLastFocusInRoute(String routeName) {
    for (int i = _stack.length - 1; i >= 0; i--) {
      final entry = _stack.elementAt(i);
      if (entry.route?.settings.name == routeName) {
        return entry;
      }
    }
    return null;
  }
}
