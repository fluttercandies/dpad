/// Flutter TV D-pad Navigation System
///
/// A simple yet powerful D-pad navigation system that makes Flutter development
/// for Android TV, Fire TV, and other TV platforms as easy as native Android development.
/// 
/// **Quick Setup - Just 3 Steps:**
/// 1. Wrap your app with [DpadNavigator] - Enables global D-pad support
/// 2. Wrap focusable widgets with [DpadFocusable] - Makes widgets respond to D-pad navigation
/// 3. Customize focus effects - Use the builder pattern for completely custom focus appearances
///
/// **Example Usage:**
/// ```dart
/// import 'package:dpad/dpad.dart';
///
/// void main() {
///   runApp(DpadNavigator(
///     enabled: true,
///     customShortcuts: {
///       LogicalKeyboardKey.keyG: () {}, // Grid view
///       LogicalKeyboardKey.keyL: () {}, // List view
///     },
///     onMenuPressed: () {}, // Menu pressed
///     onBackPressed: () {}, // Back pressed
///     child: MaterialApp(
///       theme: ThemeData.dark(),
///       home: MyScreen(),
///     ),
///   ));
/// }
///
/// class MyScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Padding(
///         padding: EdgeInsets.all(32),
///         child: Column(
///           children: [
///             // Custom focus effect with border highlight
///             DpadFocusable(
///               autofocus: true,
///               onFocus: () {}, // Button 1 focused
///               onSelect: () {}, // Button 1 selected
///               builder: (context, isFocused, child) {
///                 return AnimatedContainer(
///                   duration: Duration(milliseconds: 200),
///                   decoration: BoxDecoration(
///                     border: Border.all(
///                       color: isFocused ? Colors.blue : Colors.transparent,
///                       width: 3,
///                     ),
///                     borderRadius: BorderRadius.circular(8),
///                   ),
///                   child: child,
///                 );
///               },
///               child: ElevatedButton(
///                 onPressed: () {}, // Button 1 pressed
///                 child: Text('Button 1'),
///               ),
///             ),
///
///             // Using built-in glow effect
///             DpadFocusable(
///               onFocus: () {}, // Button 2 focused
///               onSelect: () {}, // Button 2 selected
///               builder: FocusEffects.glow(
///                 glowColor: Colors.green,
///                 blurRadius: 15.0,
///               ),
///               child: ElevatedButton(
///                 onPressed: () {}, // Button 2 pressed
///                 child: Text('Button 2'),
///               ),
///             ),
///
///             // Default focus effect (simple border)
///             DpadFocusable(
///               onFocus: () {}, // Button 3 focused
///               onSelect: () {}, // Button 3 selected
///               child: ElevatedButton(
///                 onPressed: () {}, // Button 3 pressed
///                 child: Text('Button 3'),
///               ),
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
/// **Key Features:**
/// - 🎯 Simple 3-step setup process
/// - 🎨 8+ built-in focus effects with unlimited customization
/// - 📱 Full platform support (Android TV, Fire TV, Apple TV, Game Controllers)
/// - ⚡ Optimized for smooth navigation performance
/// - 🔧 Complete programmatic control API
/// - 🎮 Game controller support out of the box
/// - 🔧 Custom keyboard shortcuts support
/// - 🎨 Custom focus effect builders
///
/// **Platform Support:**
/// - **Android TV**: Full native D-pad and remote control support
/// - **Amazon Fire TV**: Compatible with all Fire TV remotes
/// - **Apple TV**: Works with Siri Remote (Flutter web)
/// - **Game Controllers**: Standard D-pad and button navigation
/// - **Generic TV Platforms**: Any D-pad compatible input device
///
/// **Built-in Focus Effects:**
/// - [FocusEffects.border] - Simple colored border highlight
/// - [FocusEffects.glow] - Shadow/glow effect around focused widget
/// - [FocusEffects.scale] - Scale animation when focused
/// - [FocusEffects.gradient] - Gradient background change
/// - [FocusEffects.elevation] - Material design elevation effect
/// - [FocusEffects.scaleWithBorder] - Combined scale and border
/// - [FocusEffects.opacity] - Opacity change on focus
/// - [FocusEffects.colorTint] - Color overlay effect
/// - [FocusEffects.combine] - Multiple effects combined
///
/// **Custom Focus Effect Example:**
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
///   child: ElevatedButton(
///     onPressed: () {}, // Button pressed
///     child: Text('Custom Effect Button'),
///   ),
/// )
/// ```
///
/// **Programmatic Navigation:**
/// ```dart
/// // Navigate in specific directions
/// Dpad.navigateUp(context);
/// Dpad.navigateDown(context);
/// Dpad.navigateLeft(context);
/// Dpad.navigateRight(context);
///
/// // Sequential navigation (v1.1.0+)
/// Dpad.navigateNext(context);      // Tab / Media Track Next
/// Dpad.navigatePrevious(context);   // Shift+Tab / Media Track Previous
///
/// // Focus management
/// final currentFocus = Dpad.currentFocus;
/// Dpad.requestFocus(myFocusNode);
/// Dpad.clearFocus();
/// ```
///
/// **Custom Shortcuts Example:**
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
/// **Architecture:**
/// The system consists of three main components:
/// - **[DpadNavigator]**: Root widget that captures D-pad events and handles global navigation
/// - **[DpadFocusable]**: Wrapper that makes any widget focusable with custom effects
/// - **[Dpad]**: Utility class for programmatic focus control and navigation
/// - **[FocusEffects]**: Collection of built-in focus effects for common use cases
///
/// All components work seamlessly together with Flutter's native focus system.
///
/// **Migration from Other Solutions:**
/// If you're coming from other TV navigation libraries:
/// - ✅ No complex configuration needed
/// - ✅ Works with standard Flutter widgets
/// - ✅ No custom FocusNode management required
/// - ✅ Built-in support for all TV platforms
/// - ✅ Extensive customization options
///
/// For complete API documentation, see the individual component files.

library dpad;

// Navigation exports
export 'src/navigation/dpad_navigator.dart';

// Focus exports
export 'src/focus/dpad_focusable.dart';
export 'src/focus/focus_effects.dart';

// Core exports
export 'src/core/dpad_core.dart';
export 'src/core/focus_history.dart';
export 'src/core/focus_memory_options.dart';
