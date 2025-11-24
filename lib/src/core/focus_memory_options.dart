/// Configuration options for focus memory functionality.
///
/// Used to configure the enabled state and behavior of focus memory features.
class FocusMemoryOptions {
  /// Whether focus memory functionality is enabled.
  ///
  /// Defaults to false for backward compatibility.
  final bool enabled;

  /// Maximum number of history entries to keep.
  ///
  /// When exceeded, the oldest entries will be removed.
  /// Defaults to 20.
  final int maxHistory;

  /// Set of regions to track.
  ///
  /// Empty set means track all regions.
  /// Can specify only track specific regions, e.g., {'tabs', 'filters'}
  final Set<String> trackedRegions;

  /// Default route name.
  ///
  /// Used as fallback when current route cannot be determined.
  final String? defaultRoute;

  /// Creates focus memory configuration.
  ///
  /// [enabled] Whether to enable the feature
  /// [maxHistory] Maximum number of history entries
  /// [trackedRegions] Set of regions to track
  /// [defaultRoute] Default route name
  const FocusMemoryOptions({
    this.enabled = false,
    this.maxHistory = 20,
    this.trackedRegions = const {},
    this.defaultRoute,
  });

  /// Checks whether to track the specified region.
  ///
  /// [region] The region identifier
  /// Returns true if the region should be tracked
  bool shouldTrackRegion(String? region) {
    // Track null/empty regions if no specific regions are configured
    // This ensures all DpadFocusable widgets are tracked by default
    if (region == null || region.isEmpty) {
      return trackedRegions.isEmpty;
    }
    return trackedRegions.isEmpty || trackedRegions.contains(region);
  }
}
