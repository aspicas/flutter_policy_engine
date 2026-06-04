import 'package:flutter_policy_engine/src/application/services/policy_json_codec.dart';
import 'package:flutter_policy_engine/src/domain/entities/policy.dart';
import 'package:flutter_policy_engine/src/domain/failures/domain_failure.dart';
import 'package:flutter_policy_engine/src/domain/repositories/i_policy_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A persistent [IPolicyRepository] backed by [SharedPreferences].
///
/// Serializes the policy to JSON using [PolicyJsonCodec] and stores it under
/// [storageKey]. Suitable for applications that need policies to survive app
/// restarts.
///
/// Obtain an instance via the async factory
/// `SharedPreferencesPolicyRepository.create`.
final class SharedPreferencesPolicyRepository implements IPolicyRepository {
  SharedPreferencesPolicyRepository._(this._prefs);

  /// The SharedPreferences key under which policies are stored.
  static const String storageKey = 'flutter_policy_engine_policies';

  static const _codec = PolicyJsonCodec();

  final SharedPreferences _prefs;

  /// Creates a [SharedPreferencesPolicyRepository] by obtaining an instance
  /// of [SharedPreferences].
  static Future<SharedPreferencesPolicyRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesPolicyRepository._(prefs);
  }

  @override
  Future<Result<void, DomainFailure>> save(Policy policy) async {
    try {
      final json = _codec.encode(policy);
      await _prefs.setString(storageKey, json);
      return const Ok(null);
    } catch (e) {
      return Err(
        StorageFailure('Failed to save policies: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<Policy, DomainFailure>> load() async {
    try {
      final json = _prefs.getString(storageKey);
      if (json == null) return const Ok(Policy(roles: {}));

      return _codec.decode(json);
    } catch (e) {
      return Err(StorageFailure('Failed to load policies: $e', cause: e));
    }
  }

  @override
  Future<Result<void, DomainFailure>> clear() async {
    try {
      await _prefs.remove(storageKey);
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure('Failed to clear policies: $e', cause: e));
    }
  }
}
