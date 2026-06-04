import 'package:flutter_policy_engine/src/domain/entities/abac_policy.dart';
import 'package:flutter_policy_engine/src/domain/entities/access_decision.dart';
import 'package:flutter_policy_engine/src/domain/entities/resource.dart';
import 'package:flutter_policy_engine/src/domain/entities/subject.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:meta/meta.dart';

/// Evaluates access based on Attribute-Based Access Control rules.
///
/// Every [AttributeRule] in the policy must be satisfied for access to be
/// granted. An empty rule list is an open policy — always grants.
@immutable
final class AbacEvaluator {
  /// Creates an [AbacEvaluator].
  const AbacEvaluator();

  /// Evaluates [subject]'s access to [resource] against [abacPolicy].
  AccessDecision evaluate(
    Subject subject,
    Resource resource,
    AbacPolicy abacPolicy,
  ) {
    for (final rule in abacPolicy.rules) {
      final failure = _evaluateRule(rule, subject, resource);
      if (failure != null) {
        return AccessDecision.denied(failure);
      }
    }
    return const AccessDecision.granted();
  }

  DomainFailure? _evaluateRule(
    AttributeRule rule,
    Subject subject,
    Resource resource,
  ) {
    final subjectValue = subject.getAttribute(rule.subjectAttribute);
    if (subjectValue == null) {
      return MissingAttributeFailure(
        attributeKey: rule.subjectAttribute,
        target: 'subject',
      );
    }

    if (rule.expectedValue != null && subjectValue != rule.expectedValue) {
      return MissingAttributeFailure(
        attributeKey: rule.subjectAttribute,
        target: 'subject',
      );
    }

    if (rule.resourceAttribute != null) {
      final resourceValue = resource.getAttribute(rule.resourceAttribute!);
      if (resourceValue == null || subjectValue != resourceValue) {
        return MissingAttributeFailure(
          attributeKey: rule.resourceAttribute!,
          target: 'resource',
        );
      }
    }

    return null;
  }
}
