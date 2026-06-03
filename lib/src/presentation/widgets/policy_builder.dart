import 'package:flutter/widgets.dart';
import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/presentation/providers/policy_engine_scope.dart';
import 'package:flutter_policy_engine/src/presentation/widgets/policy_gate.dart' show PolicyGate;

/// Builder callback providing the access [decision] to the widget.
///
/// [decision] is `null` while evaluation is still in progress.
typedef PolicyWidgetBuilder = Widget Function(
  BuildContext context,
  AccessDecision? decision,
);

/// An access-aware builder that exposes the [AccessDecision] to its subtree.
///
/// Unlike [PolicyGate], this widget gives callers full control over rendering
/// for granted, denied, and loading states through a single [builder] callback.
///
/// ```dart
/// PolicyBuilder(
///   roleName: 'editor',
///   resourceId: 'posts',
///   builder: (context, decision) {
///     if (decision == null) return const CircularProgressIndicator();
///     if (decision.isGranted) return const EditButton();
///     return const Text('Read-only');
///   },
/// )
/// ```
class PolicyBuilder extends StatefulWidget {
  /// Creates a [PolicyBuilder] for [roleName] accessing [resourceId].
  const PolicyBuilder({
    required this.roleName,
    required this.resourceId,
    required this.builder,
    super.key,
  });

  /// The role to evaluate.
  final String roleName;

  /// The resource to check access against.
  final String resourceId;

  /// Builder called with the current [AccessDecision] (null while loading).
  final PolicyWidgetBuilder builder;

  @override
  State<PolicyBuilder> createState() => _PolicyBuilderState();
}

class _PolicyBuilderState extends State<PolicyBuilder> {
  late Future<Result<AccessDecision, DomainFailure>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _evaluate();
  }

  void _evaluate() {
    _future = PolicyEngineScope.of(context)
        .evaluateAccess(widget.roleName, widget.resourceId);
  }

  @override
  void didUpdateWidget(PolicyBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roleName != widget.roleName ||
        oldWidget.resourceId != widget.resourceId) {
      _evaluate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<AccessDecision, DomainFailure>>(
      future: _future,
      builder: (context, snapshot) {
        AccessDecision? decision;
        if (snapshot.hasData) {
          final result = snapshot.data!;
          if (result.isOk) {
            decision = (result as Ok<AccessDecision, DomainFailure>).value;
          } else {
            decision = AccessDecision.denied(
              (result as Err<AccessDecision, DomainFailure>).error,
            );
          }
        }
        return widget.builder(context, decision);
      },
    );
  }
}
