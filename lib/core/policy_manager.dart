import 'package:flutter/foundation.dart';
import 'package:flutter_policy_engine/core/interfaces/i_policy_storage.dart';
import 'package:flutter_policy_engine/models/policy.dart';

class PolicyManager extends ChangeNotifier {
  PolicyManager({
    required this.storage,
  });

  final IPolicyStorage storage;
  Map<String, Policy> _policies = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Map<String, Policy> get policies => Map.unmodifiable(_policies);

  Future<void> loadPolicies() async {
    throw UnimplementedError();
  }
}
