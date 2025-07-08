import 'package:flutter_policy_engine/core/interfaces/i_policy_evaluator.dart';
import 'package:flutter_policy_engine/models/policy.dart';
import 'package:meta/meta.dart';

@immutable
class RoleEvaluator implements IPolicyEvaluator {
  const RoleEvaluator(this._policies);

  final Map<String, Policy> _policies;

  @override
  Future<bool> evaluate(String roleName, String content) {
    // TODO: implement evaluate
    throw UnimplementedError();
  }
}
