import 'package:flutter/widgets.dart';
import 'package:flutter_policy_engine/src/presentation/state/policy_engine_controller.dart';

/// Provides a [PolicyEngineController] to the widget subtree.
///
/// Uses [InheritedNotifier] so that descendant widgets rebuilt via
/// `PolicyEngineScope.of(context)` automatically re-render when
/// [PolicyEngineController] notifies listeners — fixing the rebuild bug in
/// the v1 `PolicyProvider`.
///
/// ```dart
/// PolicyEngineScope(
///   controller: PolicyEngineController.inMemory(),
///   child: MyApp(),
/// )
/// ```
class PolicyEngineScope extends InheritedNotifier<PolicyEngineController> {
  /// Creates a [PolicyEngineScope] that provides [controller] to descendants.
  const PolicyEngineScope({
    required PolicyEngineController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// Returns the nearest [PolicyEngineController] in the widget tree.
  ///
  /// Subscribes the calling context to rebuild notifications. Throws a
  /// [FlutterError] if no [PolicyEngineScope] is found in the tree.
  static PolicyEngineController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PolicyEngineScope>();
    if (scope == null) {
      throw FlutterError(
        'PolicyEngineScope.of() called with a context that does not contain a '
        'PolicyEngineScope.\n'
        'Make sure a PolicyEngineScope ancestor exists above this widget.',
      );
    }
    return scope.notifier!;
  }

  /// Returns the nearest [PolicyEngineController] without subscribing.
  ///
  /// Use this when you need the controller but do not want the context to
  /// rebuild when the controller notifies listeners.
  static PolicyEngineController? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<PolicyEngineScope>()?.notifier;
  }
}
