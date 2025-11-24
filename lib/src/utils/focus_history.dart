import 'package:flutter/material.dart';

/// Focus history entry containing complete information for intelligent focus restoration.
/// 
/// Stores focus position, region, route, and other metadata for smart back navigation.
class FocusHistoryEntry {
  /// The focus node
  final FocusNode focusNode;
  
  /// Region identifier (e.g., 'tabs', 'filters', 'cards')
  final String? region;
  
  /// Route name
  final String? routeName;
  
  /// Timestamp of when focus was recorded
  final DateTime timestamp;
  
  /// Debug label for identification
  final String? debugLabel;
  
  FocusHistoryEntry({
    required this.focusNode,
    this.region,
    this.routeName,
    this.debugLabel,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() {
    return 'FocusEntry(${debugLabel ?? focusNode.hashCode}, region: $region, route: $routeName)';
  }
}

/// Focus history manager using stack structure for focus memory restoration.
/// 
/// Manages focus history with push/pop operations and intelligent restoration.
class FocusHistory {
  static final List<FocusHistoryEntry> _stack = [];
  static int _maxSize = 20;
  
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
    return _stack.isNotEmpty ? _stack.removeLast() : null;
  }
  
  /// Gets the complete history as a read-only list.
  /// 
  /// Returns an unmodifiable copy of the history stack
  static List<FocusHistoryEntry> getHistory() {
    return List.unmodifiable(_stack);
  }
  
  /// Clears all focus history entries.
  static void clear() {
    _stack.clear();
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
      if (entry.routeName == routeName) {
        return entry;
      }
    }
    return null;
  }
}
