import 'package:meta/meta.dart';

@immutable
abstract class IPolicyStorage {
  Future<Map<String, dynamic>> loadPolicies();
  Future<void> savePolicies(Map<String, dynamic> policies);
  Future<void> clearPolicies();
}
