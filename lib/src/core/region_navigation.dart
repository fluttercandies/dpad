import 'dart:collection';

import 'package:flutter/material.dart';

/// Strategy for handling cross-region navigation.
///
/// Defines how focus should behave when navigating from one region to another.
/// Different strategies provide different user experiences for TV navigation.
enum RegionNavigationStrategy {
  /// Use Flutter's default geometric distance-based focus traversal.
  ///
  /// Leverages Flutter's built-in [DirectionalFocusTraversalPolicyMixin]
  /// which calculates the nearest focusable widget based on geometric distance.
  /// This may lead to unexpected behavior in complex layouts.
  geometric,

  /// Navigate to a fixed entry point in the target region.
  ///
  /// Always focuses the first/designated widget in the target region,
  /// regardless of the current scroll position or geometric distance.
  /// Uses [FocusTraversalPolicy.findFirstFocus] internally when possible.
  /// This is the most predictable behavior for users.
  ///
  /// Example: Tab → Content always focuses the first card.
  fixedEntry,

  /// Restore focus to the last focused widget in the target region.
  ///
  /// Uses focus memory to return to the previously focused widget
  /// in the target region. Falls back to [fixedEntry] if no history exists.
  ///
  /// Example: Content → Tab returns to the previously selected tab.
  memory,

  /// Use a custom resolver function to determine the target.
  ///
  /// Allows complete customization of navigation logic through
  /// [RegionNavigationRule.resolver].
  custom,
}

/// Defines a navigation rule from one region to another.
///
/// Specifies how focus should transition when the user navigates
/// in a specific direction from a source region.
///
/// Example:
/// ```dart
/// RegionNavigationRule(
///   fromRegion: 'tabs',
///   toRegion: 'content',
///   direction: TraversalDirection.down,
///   strategy: RegionNavigationStrategy.fixedEntry,
/// )
/// ```
class RegionNavigationRule {
  /// The source region identifier.
  ///
  /// Navigation will be intercepted when focus is in a widget
  /// with this region and the user presses the specified direction.
  final String fromRegion;

  /// The target region identifier.
  ///
  /// Focus will move to a widget in this region according to the strategy.
  final String toRegion;

  /// The direction that triggers this rule.
  ///
  /// Only navigation in this direction from [fromRegion] will be intercepted.
  final TraversalDirection direction;

  /// The navigation strategy to use.
  ///
  /// Determines how the target focus widget is selected.
  final RegionNavigationStrategy strategy;

  /// Custom resolver for [RegionNavigationStrategy.custom].
  ///
  /// Called to determine the target FocusNode when this rule is triggered.
  /// Should return the FocusNode to focus, or null to fall back to default behavior.
  ///
  /// Parameters:
  /// - [fromNode]: The current focus node
  /// - [toRegion]: The target region identifier
  /// - [direction]: The navigation direction
  /// - [candidates]: List of focusable nodes in the target region
  final FocusNode? Function(
    FocusNode fromNode,
    String toRegion,
    TraversalDirection direction,
    List<FocusNode> candidates,
  )? resolver;

  /// Whether to apply this rule bidirectionally.
  ///
  /// If true, a reverse rule is automatically created.
  /// For example, if [direction] is [TraversalDirection.down],
  /// a reverse rule for [TraversalDirection.up] from [toRegion] to [fromRegion]
  /// will also be applied.
  final bool bidirectional;

  /// The strategy to use for the reverse direction (if bidirectional).
  ///
  /// Defaults to [RegionNavigationStrategy.memory] for natural back navigation.
  final RegionNavigationStrategy? reverseStrategy;

  const RegionNavigationRule({
    required this.fromRegion,
    required this.toRegion,
    required this.direction,
    this.strategy = RegionNavigationStrategy.fixedEntry,
    this.resolver,
    this.bidirectional = false,
    this.reverseStrategy,
  });

  /// Creates the reverse rule for bidirectional navigation.
  RegionNavigationRule? createReverseRule() {
    if (!bidirectional) return null;

    return RegionNavigationRule(
      fromRegion: toRegion,
      toRegion: fromRegion,
      direction: _reverseDirection(direction),
      strategy: reverseStrategy ?? RegionNavigationStrategy.memory,
      bidirectional: false,
    );
  }

  /// Gets the reverse direction.
  static TraversalDirection _reverseDirection(TraversalDirection direction) {
    switch (direction) {
      case TraversalDirection.up:
        return TraversalDirection.down;
      case TraversalDirection.down:
        return TraversalDirection.up;
      case TraversalDirection.left:
        return TraversalDirection.right;
      case TraversalDirection.right:
        return TraversalDirection.left;
    }
  }

  @override
  String toString() {
    return 'RegionNavigationRule($fromRegion → $toRegion, $direction, $strategy)';
  }
}

/// Configuration options for region-based navigation.
///
/// Used to configure the behavior of cross-region navigation in TV apps.
///
/// Example:
/// ```dart
/// RegionNavigationOptions(
///   enabled: true,
///   rules: [
///     // Tab → Content: always focus first card
///     RegionNavigationRule(
///       fromRegion: 'tabs',
///       toRegion: 'content',
///       direction: TraversalDirection.down,
///       strategy: RegionNavigationStrategy.fixedEntry,
///       bidirectional: true,
///       reverseStrategy: RegionNavigationStrategy.memory,
///     ),
///     // Sidebar → Content: always focus first card
///     RegionNavigationRule(
///       fromRegion: 'sidebar',
///       toRegion: 'content',
///       direction: TraversalDirection.right,
///       strategy: RegionNavigationStrategy.fixedEntry,
///       bidirectional: true,
///       reverseStrategy: RegionNavigationStrategy.memory,
///     ),
///   ],
/// )
/// ```
class RegionNavigationOptions {
  /// Whether region-based navigation is enabled.
  ///
  /// When false, all navigation uses Flutter's default behavior.
  final bool enabled;

  /// List of navigation rules defining cross-region behavior.
  ///
  /// Rules are checked in order; the first matching rule is applied.
  final List<RegionNavigationRule> rules;

  /// Default strategy when no specific rule matches.
  ///
  /// Applied when navigating between regions that don't have explicit rules.
  final RegionNavigationStrategy defaultStrategy;

  const RegionNavigationOptions({
    this.enabled = true,
    this.rules = const [],
    this.defaultStrategy = RegionNavigationStrategy.geometric,
  });

  /// Disabled region navigation options.
  static const disabled = RegionNavigationOptions(enabled: false);

  /// Finds the rule that matches the given parameters.
  ///
  /// Returns null if no matching rule is found.
  RegionNavigationRule? findRule(
    String? fromRegion,
    TraversalDirection direction,
  ) {
    if (fromRegion == null) return null;

    for (final rule in rules) {
      if (rule.fromRegion == fromRegion && rule.direction == direction) {
        return rule;
      }
    }

    // Check reverse rules from bidirectional rules
    for (final rule in rules) {
      final reverseRule = rule.createReverseRule();
      if (reverseRule != null &&
          reverseRule.fromRegion == fromRegion &&
          reverseRule.direction == direction) {
        return reverseRule;
      }
    }

    return null;
  }

  /// Gets all expanded rules including reverse rules.
  List<RegionNavigationRule> get expandedRules {
    final result = <RegionNavigationRule>[];
    for (final rule in rules) {
      result.add(rule);
      final reverseRule = rule.createReverseRule();
      if (reverseRule != null) {
        result.add(reverseRule);
      }
    }
    return result;
  }
}

/// Entry point registration for a region.
///
/// Used to register the first/default focusable widget in a region
/// for [RegionNavigationStrategy.fixedEntry].
class RegionEntryPoint {
  /// The region identifier.
  final String region;

  /// The focus node to use as entry point.
  final FocusNode focusNode;

  /// Priority for multiple entry points (higher = preferred).
  final int priority;

  /// Debug label for identification.
  final String? debugLabel;

  const RegionEntryPoint({
    required this.region,
    required this.focusNode,
    this.priority = 0,
    this.debugLabel,
  });

  /// Whether this entry point is still valid.
  bool get isValid => focusNode.canRequestFocus;

  @override
  String toString() {
    return 'RegionEntryPoint($region, priority: $priority, label: $debugLabel)';
  }
}

/// Manager for region-based focus navigation.
///
/// Handles registration and lookup of regions and their focusable widgets.
/// Each [DpadNavigator] has its own [RegionNavigationManager] instance.
class RegionNavigationManager {
  /// Creates a new region navigation manager.
  RegionNavigationManager({this.options = const RegionNavigationOptions()});

  /// Configuration options for region navigation.
  final RegionNavigationOptions options;

  /// Map of region identifiers to their registered focus nodes.
  /// Uses LinkedHashSet to maintain insertion order for predictable fallback behavior.
  final Map<String, LinkedHashSet<FocusNode>> _regionNodes = {};

  /// Map of region identifiers to their entry points.
  final Map<String, List<RegionEntryPoint>> _entryPoints = {};

  /// Map of focus nodes to their regions.
  final Map<FocusNode, String> _nodeToRegion = {};

  /// Registers a focus node with a region.
  ///
  /// [region] The region identifier
  /// [focusNode] The focus node to register
  /// [isEntryPoint] Whether this node is the entry point for the region
  /// [entryPriority] Priority for entry point (higher = preferred)
  /// [debugLabel] Debug label for identification
  void registerNode(
    String region,
    FocusNode focusNode, {
    bool isEntryPoint = false,
    int entryPriority = 0,
    String? debugLabel,
  }) {
    // Add to region set (LinkedHashSet maintains insertion order)
    _regionNodes.putIfAbsent(region, () => LinkedHashSet<FocusNode>());
    _regionNodes[region]!.add(focusNode);

    // Map node to region
    _nodeToRegion[focusNode] = region;

    // Register entry point if specified
    if (isEntryPoint) {
      _entryPoints.putIfAbsent(region, () => []);
      _entryPoints[region]!.add(RegionEntryPoint(
        region: region,
        focusNode: focusNode,
        priority: entryPriority,
        debugLabel: debugLabel,
      ));
      // Sort by priority (descending)
      _entryPoints[region]!.sort((a, b) => b.priority.compareTo(a.priority));
    }
  }

  /// Unregisters a focus node from its region.
  void unregisterNode(FocusNode focusNode) {
    final region = _nodeToRegion.remove(focusNode);
    if (region != null) {
      _regionNodes[region]?.remove(focusNode);
      _entryPoints[region]?.removeWhere((e) => e.focusNode == focusNode);
    }
  }

  /// Gets the region for a focus node.
  String? getRegionForNode(FocusNode focusNode) {
    return _nodeToRegion[focusNode];
  }

  /// Gets all focus nodes in a region.
  List<FocusNode> getNodesInRegion(String region) {
    final nodes = _regionNodes[region];
    if (nodes == null) return [];
    // Filter out disposed nodes
    return nodes.where((n) => n.canRequestFocus).toList();
  }

  /// Gets the entry point focus node for a region.
  ///
  /// Returns the highest priority valid entry point, or null if none exists.
  /// Falls back to the first registered node if no entry point is defined.
  FocusNode? getEntryPointForRegion(String region) {
    final entryPoints = _entryPoints[region];

    // Try to find a valid entry point first
    if (entryPoints != null && entryPoints.isNotEmpty) {
      for (final entry in entryPoints) {
        if (entry.isValid) {
          return entry.focusNode;
        }
      }
    }

    // Fall back to first registered node in region
    // LinkedHashSet maintains insertion order, so this returns the first registered node
    final nodes = getNodesInRegion(region);
    return nodes.isNotEmpty ? nodes.first : null;
  }

  /// Handles navigation from one region in a specific direction.
  ///
  /// Returns the target FocusNode if a rule matches, null otherwise.
  FocusNode? handleNavigation(
    FocusNode currentNode,
    TraversalDirection direction,
    FocusNode? Function(String region)? getLastFocusInRegion,
  ) {
    if (!options.enabled) return null;

    final currentRegion = getRegionForNode(currentNode);
    if (currentRegion == null) return null;

    final rule = options.findRule(currentRegion, direction);
    if (rule == null) return null;

    final targetRegion = rule.toRegion;
    final candidates = getNodesInRegion(targetRegion);
    if (candidates.isEmpty) return null;

    switch (rule.strategy) {
      case RegionNavigationStrategy.geometric:
        // Let Flutter handle with default behavior
        return null;

      case RegionNavigationStrategy.fixedEntry:
        return getEntryPointForRegion(targetRegion);

      case RegionNavigationStrategy.memory:
        // Try to get last focused node in target region
        final lastFocus = getLastFocusInRegion?.call(targetRegion);
        if (lastFocus != null && lastFocus.canRequestFocus) {
          return lastFocus;
        }
        // Fall back to entry point
        return getEntryPointForRegion(targetRegion);

      case RegionNavigationStrategy.custom:
        return rule.resolver?.call(
          currentNode,
          targetRegion,
          direction,
          candidates,
        );
    }
  }

  /// Cleans up disposed nodes from all regions.
  void cleanup() {
    for (final region in _regionNodes.keys.toList()) {
      _regionNodes[region]?.removeWhere((n) => !n.canRequestFocus);
    }
    for (final region in _entryPoints.keys.toList()) {
      _entryPoints[region]?.removeWhere((e) => !e.isValid);
    }
    _nodeToRegion.removeWhere((node, _) => !node.canRequestFocus);
  }

  /// Clears all registrations.
  void clear() {
    _regionNodes.clear();
    _entryPoints.clear();
    _nodeToRegion.clear();
  }
}

// =============================================================================
// Flutter System API-based Implementation
// =============================================================================

/// A custom [FocusTraversalPolicy] that supports region-based navigation.
///
/// This policy extends Flutter's built-in [ReadingOrderTraversalPolicy] and
/// adds region-aware navigation capabilities. It uses the system's
/// [DirectionalFocusTraversalPolicyMixin] for geometric calculations.
///
/// When a navigation rule matches, this policy will override the default
/// geometric behavior with the specified strategy (fixedEntry, memory, etc.).
/// However, it will first check if there are more focusable items in the
/// same region in the navigation direction before crossing to another region.
///
/// **Usage with FocusTraversalGroup:**
/// ```dart
/// FocusTraversalGroup(
///   policy: RegionAwareFocusTraversalPolicy(
///     regionManager: DpadNavigator.regionManagerOf(context),
///     getLastFocusInRegion: (region) => historyManager?.getLastFocusInRegion(region)?.focusNode,
///   ),
///   child: YourWidget(),
/// )
/// ```
///
/// **Note:** This policy leverages Flutter's native focus system:
/// - Uses [ReadingOrderTraversalPolicy] as the base for widget ordering
/// - Uses [DirectionalFocusTraversalPolicyMixin] for direction calculations
/// - Calls [FocusTraversalPolicy.defaultTraversalRequestFocusCallback] for focus requests
class RegionAwareFocusTraversalPolicy extends ReadingOrderTraversalPolicy {
  /// Creates a region-aware focus traversal policy.
  ///
  /// [regionManager] provides region registration and lookup
  /// [getLastFocusInRegion] callback to retrieve focus memory for a region
  RegionAwareFocusTraversalPolicy({
    this.regionManager,
    this.getLastFocusInRegion,
    super.requestFocusCallback,
  });

  /// The region navigation manager for looking up regions and rules.
  final RegionNavigationManager? regionManager;

  /// Callback to get the last focused node in a region for memory-based navigation.
  final FocusNode? Function(String region)? getLastFocusInRegion;

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final manager = regionManager;

    // If no region manager or disabled, use default behavior
    if (manager == null || !manager.options.enabled) {
      return super.inDirection(currentNode, direction);
    }

    // Get current node's region
    final currentRegion = manager.getRegionForNode(currentNode);

    // If current node is not in a managed region, use default behavior
    if (currentRegion == null) {
      return super.inDirection(currentNode, direction);
    }

    // STEP 1: Try to find a node in the SAME region first
    final sameRegionTarget = _findNextNodeInSameRegion(
      currentNode,
      direction,
      manager,
      currentRegion,
    );

    if (sameRegionTarget != null) {
      // Found a node in the same region, use it
      requestFocusCallback(
        sameRegionTarget,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
      return true;
    }

    // STEP 2: No node in same region, check for cross-region rules
    final ruleTarget = manager.handleNavigation(
      currentNode,
      direction,
      getLastFocusInRegion,
    );

    if (ruleTarget != null) {
      // Use the rule-specified target
      requestFocusCallback(
        ruleTarget,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
      return true;
    }

    // STEP 3: No rule, try geometric navigation to any region
    final geometricTarget = _findNextNodeUsingGeometric(currentNode, direction);
    if (geometricTarget != null) {
      requestFocusCallback(
        geometricTarget,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
      return true;
    }

    // Fall back to super implementation
    return super.inDirection(currentNode, direction);
  }

  /// Finds the next focus node in the SAME region using geometric calculation.
  FocusNode? _findNextNodeInSameRegion(
    FocusNode currentNode,
    TraversalDirection direction,
    RegionNavigationManager manager,
    String currentRegion,
  ) {
    // Get all nodes in the same region
    final nodesInRegion = manager.getNodesInRegion(currentRegion);
    if (nodesInRegion.isEmpty) return null;

    final currentRect = currentNode.rect;
    FocusNode? bestNode;
    double bestScore = double.infinity;

    for (final candidate in nodesInRegion) {
      if (candidate == currentNode) continue;
      if (!candidate.canRequestFocus) continue;

      final candidateRect = candidate.rect;

      // Check if candidate is in the correct direction
      if (!_isInDirection(currentRect, candidateRect, direction)) {
        continue;
      }

      // Calculate distance score
      final score = _calculateDirectionalScore(
        currentRect,
        candidateRect,
        direction,
      );

      if (score < bestScore) {
        bestScore = score;
        bestNode = candidate;
      }
    }

    return bestNode;
  }

  /// Finds the next focus node using geometric calculation across all regions.
  FocusNode? _findNextNodeUsingGeometric(
    FocusNode currentNode,
    TraversalDirection direction,
  ) {
    final nearestScope = currentNode.nearestScope;
    if (nearestScope == null) return null;

    final sortedNodes = _getSortedNodesInScope(nearestScope);
    if (sortedNodes.isEmpty) return null;

    // Use geometric calculation to find the next node
    return _findNextNodeInDirection(
      currentNode, // Use currentNode, not focusedChild
      sortedNodes,
      direction,
    );
  }

  /// Gets sorted focusable nodes in the given scope.
  List<FocusNode> _getSortedNodesInScope(FocusScopeNode scope) {
    final descendants = scope.descendants.toList();
    final sortedNodes = <FocusNode>[];

    for (final node in descendants) {
      if (node.canRequestFocus &&
          !node.skipTraversal &&
          node is! FocusScopeNode) {
        sortedNodes.add(node);
      }
    }

    return sortedNodes;
  }

  /// Finds the next node in the given direction using geometric calculation.
  ///
  /// This mimics Flutter's [DirectionalFocusTraversalPolicyMixin.inDirection]
  /// but returns the node instead of focusing it.
  FocusNode? _findNextNodeInDirection(
    FocusNode currentNode,
    List<FocusNode> candidates,
    TraversalDirection direction,
  ) {
    final currentRect = currentNode.rect;
    FocusNode? bestNode;
    double bestScore = double.infinity;

    for (final candidate in candidates) {
      if (candidate == currentNode) continue;
      if (!candidate.canRequestFocus) continue;

      final candidateRect = candidate.rect;

      // Check if candidate is in the correct direction
      if (!_isInDirection(currentRect, candidateRect, direction)) {
        continue;
      }

      // Calculate distance score
      final score = _calculateDirectionalScore(
        currentRect,
        candidateRect,
        direction,
      );

      if (score < bestScore) {
        bestScore = score;
        bestNode = candidate;
      }
    }

    return bestNode;
  }

  /// Checks if the candidate rect is in the specified direction from current.
  bool _isInDirection(
    Rect current,
    Rect candidate,
    TraversalDirection direction,
  ) {
    switch (direction) {
      case TraversalDirection.up:
        return candidate.bottom <= current.top + 1;
      case TraversalDirection.down:
        return candidate.top >= current.bottom - 1;
      case TraversalDirection.left:
        return candidate.right <= current.left + 1;
      case TraversalDirection.right:
        return candidate.left >= current.right - 1;
    }
  }

  /// Calculates a score for directional navigation.
  ///
  /// Lower scores are better. Considers both the distance in the primary
  /// direction and the perpendicular offset.
  double _calculateDirectionalScore(
    Rect current,
    Rect candidate,
    TraversalDirection direction,
  ) {
    final currentCenter = current.center;
    final candidateCenter = candidate.center;

    double primaryDistance;
    double perpendicularOffset;

    switch (direction) {
      case TraversalDirection.up:
        primaryDistance = currentCenter.dy - candidateCenter.dy;
        perpendicularOffset = (currentCenter.dx - candidateCenter.dx).abs();
        break;
      case TraversalDirection.down:
        primaryDistance = candidateCenter.dy - currentCenter.dy;
        perpendicularOffset = (currentCenter.dx - candidateCenter.dx).abs();
        break;
      case TraversalDirection.left:
        primaryDistance = currentCenter.dx - candidateCenter.dx;
        perpendicularOffset = (currentCenter.dy - candidateCenter.dy).abs();
        break;
      case TraversalDirection.right:
        primaryDistance = candidateCenter.dx - currentCenter.dx;
        perpendicularOffset = (currentCenter.dy - candidateCenter.dy).abs();
        break;
    }

    // Weight the perpendicular offset more heavily to prefer items
    // that are more directly in the navigation direction
    return primaryDistance + perpendicularOffset * 2;
  }
}

/// A widget that wraps its child with region-aware focus traversal.
///
/// This is a convenience widget that sets up a [FocusTraversalGroup] with
/// [RegionAwareFocusTraversalPolicy]. It automatically retrieves the
/// region manager from the nearest [DpadNavigator].
///
/// **Example:**
/// ```dart
/// RegionTraversalGroup(
///   child: Column(
///     children: [
///       TabBar(...),
///       ContentGrid(...),
///     ],
///   ),
/// )
/// ```
class RegionTraversalGroup extends StatelessWidget {
  /// Creates a region traversal group.
  const RegionTraversalGroup({
    super.key,
    required this.child,
    this.regionManager,
    this.getLastFocusInRegion,
  });

  /// The child widget tree.
  final Widget child;

  /// The region manager to use for navigation rules.
  /// If null, must be provided via [RegionTraversalGroupScope].
  final RegionNavigationManager? regionManager;

  /// Callback to get last focused node in a region for memory strategy.
  final FocusNode? Function(String region)? getLastFocusInRegion;

  @override
  Widget build(BuildContext context) {
    final manager = regionManager ?? RegionTraversalGroupScope.maybeOf(context);

    final policy = RegionAwareFocusTraversalPolicy(
      regionManager: manager,
      getLastFocusInRegion: getLastFocusInRegion,
    );

    return FocusTraversalGroup(
      policy: policy,
      child: child,
    );
  }
}

/// An [InheritedWidget] that provides [RegionNavigationManager] to descendants.
///
/// This is typically provided by [DpadNavigator] and can be accessed using
/// [RegionTraversalGroupScope.of] or [RegionTraversalGroupScope.maybeOf].
class RegionTraversalGroupScope extends InheritedWidget {
  /// Creates a region traversal group scope.
  const RegionTraversalGroupScope({
    super.key,
    required super.child,
    required this.regionManager,
    this.getLastFocusInRegion,
  });

  /// The region navigation manager.
  final RegionNavigationManager? regionManager;

  /// Callback to get last focused node in a region.
  final FocusNode? Function(String region)? getLastFocusInRegion;

  /// Returns the [RegionNavigationManager] from the nearest ancestor.
  ///
  /// Throws if no ancestor is found.
  static RegionNavigationManager of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<RegionTraversalGroupScope>();
    assert(scope != null,
        'No RegionTraversalGroupScope found in context. Wrap with DpadNavigator or RegionTraversalGroupScope.');
    return scope!.regionManager!;
  }

  /// Returns the [RegionNavigationManager] from the nearest ancestor, or null.
  static RegionNavigationManager? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<RegionTraversalGroupScope>();
    return scope?.regionManager;
  }

  /// Returns the getLastFocusInRegion callback from the nearest ancestor.
  static FocusNode? Function(String region)? getLastFocusInRegionOf(
      BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<RegionTraversalGroupScope>();
    return scope?.getLastFocusInRegion;
  }

  @override
  bool updateShouldNotify(RegionTraversalGroupScope oldWidget) {
    return regionManager != oldWidget.regionManager ||
        getLastFocusInRegion != oldWidget.getLastFocusInRegion;
  }
}
