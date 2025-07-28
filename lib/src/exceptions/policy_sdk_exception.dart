import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';

class PolicySDKException implements IPolicySDKException {
  PolicySDKException(
    this.message, {
    required this.exception,
  });

  @override
  final String message;

  final Exception? exception;

  @override
  String toString() {
    final buffer = StringBuffer('SDKException: $message');
    if (exception != null) {
      buffer.write('\nExtra info: ${exception?.toString()}');
    }
    return buffer.toString();
  }
}
