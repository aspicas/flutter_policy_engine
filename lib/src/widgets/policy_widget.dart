import 'package:flutter/widgets.dart';
import 'package:flutter_policy_engine/src/core/policy_provider.dart';
import 'package:flutter_policy_engine/src/exceptions/i_policy_sdk_exceptions.dart';

/// A widget that conditionally displays its [child] based on policy access control.
///
/// [PolicyWidget] checks if the given [role] has access to the specified [content]
/// using the nearest [PolicyProvider] in the widget tree. If access is granted,
/// [child] is rendered. If access is denied, [fallback] is rendered (or an empty
/// [SizedBox] if [fallback] is null), and [onAccessDenied] is called if provided.
///
/// If a [IPolicySDKException] is thrown during access evaluation, an assertion
/// error is thrown in debug mode; in release mode, access is denied silently.
///
/// Example usage:
/// ```dart
/// PolicyWidget(
///   role: 'admin',
///   content: 'dashboard',
///   child: DashboardWidget(),
///   fallback: AccessDeniedWidget(),
///   onAccessDenied: () => log('Access denied'),
/// )
/// ```
class PolicyWidget extends StatelessWidget {
  /// Creates a [PolicyWidget].
  ///
  /// [role] is the user or entity role to check.
  /// [content] is the resource or content identifier to check access for.
  /// [child] is the widget to display if access is granted.
  /// [fallback] is the widget to display if access is denied (optional).
  /// [onAccessDenied] is a callback invoked when access is denied (optional).
  const PolicyWidget({
    required this.role,
    required this.content,
    required this.child,
    this.fallback,
    this.onAccessDenied,
    super.key,
  });

  /// The role to check for access.
  final String role;

  /// The content or resource identifier to check access for.
  final String content;

  /// The widget to display if access is granted.
  final Widget child;

  /// The widget to display if access is denied. If null, an empty [SizedBox] is shown.
  final Widget? fallback;

  /// Callback invoked when access is denied.
  final VoidCallback? onAccessDenied;

  @override
  Widget build(BuildContext context) {
    final policyManager = PolicyProvider.policyManagerOf(context);

    try {
      final hasAccess = policyManager.hasAccess(role, content);

      if (hasAccess) {
        return child;
      } else {
        onAccessDenied?.call();
        return fallback ?? const SizedBox.shrink();
      }
    } catch (e) {
      if (e is IPolicySDKException) {
        assert(() {
          throw FlutterError('Error en PolicyWidget: ${e.message}');
        }());

        // On production, deny access silently
        onAccessDenied?.call();
        return fallback ?? const SizedBox.shrink();
      }
      rethrow;
    }
  }
}
