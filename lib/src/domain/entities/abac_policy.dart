import 'package:meta/meta.dart';

/// A single attribute-matching rule used in ABAC evaluation.
///
/// Evaluates to `true` when:
/// - The subject has [subjectAttribute] present.
/// - If [expectedValue] is non-null, the subject's attribute value equals it.
/// - If [resourceAttribute] is non-null, the subject's attribute value equals
///   the resource's attribute value for [resourceAttribute].
@immutable
final class AttributeRule {
  /// Creates an [AttributeRule].
  const AttributeRule({
    required this.subjectAttribute,
    this.expectedValue,
    this.resourceAttribute,
  });

  /// The key that must be present on the subject's attributes.
  final String subjectAttribute;

  /// When set, the subject's [subjectAttribute] must equal this value.
  final String? expectedValue;

  /// When set, the subject's [subjectAttribute] must equal the resource's
  /// attribute at this key.
  final String? resourceAttribute;
}

/// A collection of [AttributeRule]s that must all pass for access to be
/// granted.
///
/// An empty [rules] list is an open policy — access is always granted.
@immutable
final class AbacPolicy {
  /// Creates an [AbacPolicy] with the given [rules].
  const AbacPolicy({required this.rules});

  /// The ordered list of attribute rules to evaluate.
  final List<AttributeRule> rules;
}
