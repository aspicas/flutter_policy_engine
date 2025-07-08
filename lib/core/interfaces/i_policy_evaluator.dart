import 'package:meta/meta.dart';

@immutable
abstract class IPolicyEvaluator {
  Future<bool> evaluate(String roleName, String content);
}
