import 'package:flutter/widgets.dart';
import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/presentation/providers/policy_engine_scope.dart';

/// A widget that shows [child] when access is granted, and [fallback] (or
/// nothing) when access is denied.
///
/// ```dart
/// PolicyGate(
///   roleName: 'admin',
///   resourceId: 'dashboard',
///   child: DashboardWidget(),
///   fallback: AccessDeniedWidget(),
/// )
/// ```
class PolicyGate extends StatefulWidget {
  /// Creates a [PolicyGate] for [roleName] accessing [resourceId].
  const PolicyGate({
    required this.roleName,
    required this.resourceId,
    required this.child,
    this.fallback,
    this.loading,
    this.onDenied,
    super.key,
  });

  /// The role to evaluate.
  final String roleName;

  /// The resource to check access against.
  final String resourceId;

  /// The widget to show when access is granted.
  final Widget child;

  /// The widget to show when access is denied. Defaults to empty [SizedBox].
  final Widget? fallback;

  /// The widget to show while the evaluation is in progress.
  final Widget? loading;

  /// Called when access is denied, with the [DomainFailure] reason.
  final void Function(DomainFailure failure)? onDenied;

  @override
  State<PolicyGate> createState() => _PolicyGateState();
}

class _PolicyGateState extends State<PolicyGate> {
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
  void didUpdateWidget(PolicyGate oldWidget) {
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
        if (!snapshot.hasData) {
          return widget.loading ?? const SizedBox.shrink();
        }
        final result = snapshot.data!;
        if (result.isOk) {
          final decision = (result as Ok<AccessDecision, DomainFailure>).value;
          if (decision.isGranted) return widget.child;
          widget.onDenied?.call(
            decision.failure ??
                const ResourceNotAllowedFailure(
                  roleName: '',
                  resourceId: '',
                ),
          );
          return widget.fallback ?? const SizedBox.shrink();
        } else {
          final failure = (result as Err<AccessDecision, DomainFailure>).error;
          widget.onDenied?.call(failure);
          return widget.fallback ?? const SizedBox.shrink();
        }
      },
    );
  }
}
