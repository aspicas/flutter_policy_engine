import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:meta/meta.dart';

/// The outcome of an access control evaluation.
///
/// Use the factory constructors [AccessDecision.granted] and
/// [AccessDecision.denied] to create instances. Check [isGranted] or [isDenied]
/// to inspect the result.
@immutable
final class AccessDecision {
  const AccessDecision._({required bool granted, this.failure})
      : _granted = granted;

  /// Creates an access-granted decision.
  const AccessDecision.granted() : this._(granted: true);

  /// Creates an access-denied decision carrying the [failure] reason.
  const AccessDecision.denied(DomainFailure failure)
      : this._(granted: false, failure: failure);

  final bool _granted;

  /// The reason for denial, or `null` when access is granted.
  final DomainFailure? failure;

  /// Returns `true` when access was granted.
  bool get isGranted => _granted;

  /// Returns `true` when access was denied.
  bool get isDenied => !_granted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessDecision &&
          _granted == other._granted &&
          failure == other.failure;

  @override
  int get hashCode => Object.hash(_granted, failure);

  @override
  String toString() =>
      _granted ? 'AccessDecision.granted' : 'AccessDecision.denied($failure)';
}
