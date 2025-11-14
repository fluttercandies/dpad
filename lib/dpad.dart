/// Flutter D-pad Navigation System for TV Apps
///
/// A simple yet powerful D-pad navigation system that makes Flutter development
/// for Android TV, Fire TV, and other TV platforms as easy as native Android development.
///
/// ## Quick Start
///
/// Setting up D-pad navigation takes just three steps:
///
/// 1. **Wrap your app with DpadNavigator** - This enables global D-pad support
/// 2. **Wrap focusable widgets with DpadFocusable** - Makes widgets respond to D-pad navigation
/// 3. **Customize focus effects** - Use the builder pattern for completely custom focus appearances
///
/// ## Basic Example
///
/// ```dart
/// import 'package:dpad/dpad.dart';
///
/// void main() {
///   runApp(DpadNavigator(
///     child: MyApp(),
///   ));
/// }
///
/// class MyScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         // Custom focus effect with border highlight
///         DpadFocusable(
///           autofocus: true,
///           onFocus: () => print('Got focus'),
///           onSelect: () => print('Selected'),
///           builder: (context, isFocused, child) {
///             return AnimatedContainer(
///               duration: Duration(milliseconds: 200),
///               decoration: BoxDecoration(
///                 border: Border.all(
///                   color: isFocused ? Colors.blue : Colors.transparent,
///                   width: 3,
///                 ),
///                 borderRadius: BorderRadius.circular(8),
///               ),
///               child: child,
///             );
///           },
///           child: ElevatedButton(
///             onPressed: () => print('Button 1 pressed'),
///             child: Text('Button 1'),
///           ),
///         ),
///
///         // Default focus effect (simple border)
///         DpadFocusable(
///           onFocus: () => print('Button 2 focused'),
///           onSelect: () => print('Button 2 selected'),
///           child: ElevatedButton(
///             onPressed: () => print('Button 2 pressed'),
///             child: Text('Button 2'),
///           ),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// ## Advanced Features
///
/// ### Custom Focus Effects
///
/// Create any focus effect you can imagine with the builder pattern:
///
/// ```dart
/// DpadFocusable(
///   builder: (context, isFocused, child) {
///     return Transform.scale(
///       scale: isFocused ? 1.1 : 1.0,
///       child: AnimatedContainer(
///         duration: Duration(milliseconds: 300),
///         decoration: BoxDecoration(
///           boxShadow: isFocused ? [
///             BoxShadow(
///               color: Colors.blue.withValues(alpha: 0.6),
///               blurRadius: 20,
///               spreadRadius: 2,
///             ),
///           ] : null,
///         ),
///         child: child,
///       ),
///     );
///   },
///   child: Container(
///     child: Text('Custom Focus Effect'),
///   ),
/// )
/// ```
///
/// ### Programmatic Navigation
///
/// Use Dpad for programmatic focus control:
///
/// ```dart
/// // Navigate in specific directions
/// Dpad.navigateUp();
/// Dpad.navigateDown();
/// Dpad.navigateLeft();
/// Dpad.navigateRight();
///
/// // Focus management
/// final currentFocus = Dpad.currentFocus;
/// Dpad.requestFocus(myFocusNode);
/// Dpad.clearFocus();
/// ```
///
/// ### Custom Shortcuts and Actions
///
/// Add custom keyboard shortcuts to your DpadNavigator:
///
/// ```dart
/// DpadNavigator(
///   customShortcuts: {
///     LogicalKeyboardKey.keyG: () => _showGridView(),
///     LogicalKeyboardKey.keyL: () => _showListView(),
///     LogicalKeyboardKey.keyR: () => _refreshData(),
///     LogicalKeyboardKey.keyS: () => _showSearch(),
///   },
///   onMenuPressed: () => _showMenu(),
///   onBackPressed: () => _handleBack(),
///   child: MyApp(),
/// )
/// ```
///
/// ## Platform Support
///
/// - **Android TV**: Full native D-pad support
/// - **Amazon Fire TV**: Compatible with Fire TV remotes
/// - **Apple TV**: Works with Siri Remote (Flutter web)
/// - **Game Controllers**: Standard controller navigation
/// - **Generic TV Platforms**: Any D-pad compatible input
///
/// ## Best Practices
///
/// 1. **Always set autofocus** on one widget per screen to ensure initial focus
/// 2. **Test with real D-pad** hardware, not just keyboard arrows
/// 3. **Consider focus order** - arrange widgets logically for navigation
/// 4. **Provide visual feedback** - use clear focus indicators
/// 5. **Handle edge cases** - what happens when navigation fails?
///
/// ## Architecture
///
/// The system consists of three main components:
///
/// - **[DpadNavigator]**: Root widget that captures D-pad events
/// - **[DpadFocusable]**: Wrapper that makes widgets focusable
/// - **[Dpad]**: Utility class for programmatic control
///
/// All components work together seamlessly with Flutter's focus system.
///
/// ## Migration from Other Solutions
///
/// If you're coming from other TV navigation libraries:
///
/// - No complex configuration needed
/// - Works with standard Flutter widgets
/// - No custom FocusNode management required
/// - Built-in support for all TV platforms
/// - Extensive customization options
///
/// For complete API documentation, see the individual component files.

library dpad;

// Widget exports
export 'src/widgets/navigator.dart';
export 'src/widgets/focusable.dart';

// Effects exports
export 'src/effects/focus_effects.dart';

// Utility exports
export 'src/utils/utils.dart';
