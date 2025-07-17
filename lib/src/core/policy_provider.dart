import 'package:flutter/widgets.dart';
import 'package:flutter_policy_engine/src/core/policy_manager.dart';

/// A widget that provides a [PolicyManager] instance to its descendant widgets.
///
/// This widget uses Flutter's [InheritedWidget] pattern to make the [PolicyManager]
/// available throughout the widget tree without having to pass it explicitly
/// through constructors.
///
/// Example usage:
/// ```dart
/// PolicyProvider(
///   policyManager: myPolicyManager,
///   child: MyApp(),
/// )
/// ```
///
/// To access the [PolicyManager] in descendant widgets:
/// ```dart
/// final policyManager = PolicyProvider.policyManagerOf(context);
/// ```
class PolicyProvider extends InheritedWidget {
  /// Creates a [PolicyProvider] widget.
  ///
  /// The [policyManager] parameter is required and will be made available
  /// to all descendant widgets in the widget tree.
  ///
  /// The [child] parameter is required and represents the widget subtree
  /// that will have access to the provided [PolicyManager].
  const PolicyProvider({
    required this.policyManager,
    required super.child,
    super.key,
  });

  /// The [PolicyManager] instance that will be provided to descendant widgets.
  final PolicyManager policyManager;

  /// Returns the nearest [PolicyProvider] widget in the widget tree.
  ///
  /// This method uses [BuildContext.dependOnInheritedWidgetOfExactType] to
  /// establish a dependency on the [PolicyProvider] widget, which means
  /// the calling widget will rebuild when the [PolicyProvider] changes.
  ///
  /// Returns `null` if no [PolicyProvider] is found in the widget tree.
  ///
  /// Example:
  /// ```dart
  /// final provider = PolicyProvider.of(context);
  /// if (provider != null) {
  ///   // Use provider.policyManager
  /// }
  /// ```
  static PolicyProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PolicyProvider>();
  }

  /// Returns the [PolicyManager] from the nearest [PolicyProvider] widget.
  ///
  /// This is a convenience method that combines finding the [PolicyProvider]
  /// and accessing its [policyManager] property. It throws a [StateError]
  /// if no [PolicyProvider] is found in the widget tree.
  ///
  /// This method establishes a dependency on the [PolicyProvider] widget,
  /// causing the calling widget to rebuild when the provider changes.
  ///
  /// Throws:
  /// - [StateError] if no [PolicyProvider] is found in the widget tree.
  ///
  /// Example:
  /// ```dart
  /// final policyManager = PolicyProvider.policyManagerOf(context);
  /// // Use policyManager directly
  /// ```
  static PolicyManager policyManagerOf(BuildContext context) {
    final provider = of(context);
    if (provider == null) {
      throw StateError('PolicyProvider not found in context');
    }
    return provider.policyManager;
  }

  /// Determines whether this widget should notify its dependents of changes.
  ///
  /// Returns `true` if the [policyManager] has changed, indicating that
  /// dependent widgets should rebuild. This ensures that widgets using
  /// the [PolicyManager] are updated when the manager instance changes.
  ///
  /// The comparison is done by reference equality, so a new [PolicyManager]
  /// instance will trigger a rebuild even if it has the same configuration.
  @override
  bool updateShouldNotify(PolicyProvider oldWidget) {
    return policyManager != oldWidget.policyManager;
  }
}
