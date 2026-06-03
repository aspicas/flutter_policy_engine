// ignore_for_file: public_member_api_docs

import 'package:flutter_policy_engine/src/models/role.dart';

/// Returns a [Role] with given [name] and [allowedContent].
Role aRole({
  String name = 'test_role',
  List<String> allowedContent = const [],
  Map<String, dynamic> metadata = const {},
}) =>
    Role(name: name, allowedContent: allowedContent, metadata: metadata);

/// Returns an admin [Role] with common permissions.
Role anAdminRole() => aRole(
      name: 'admin',
      allowedContent: ['dashboard', 'users', 'settings', 'reports'],
    );

/// Returns a standard user [Role] with limited permissions.
Role aUserRole() => aRole(
      name: 'user',
      allowedContent: ['dashboard'],
    );

/// Returns a guest [Role] with minimal permissions.
Role aGuestRole() => aRole(
      name: 'guest',
      allowedContent: ['login'],
    );

/// Returns a policy map suitable for use with `PolicyManager.initialize`.
Map<String, dynamic> aBasicPolicyMap() => {
      'admin': ['dashboard', 'users', 'settings', 'reports'],
      'manager': ['dashboard', 'users', 'reports'],
      'user': ['dashboard'],
      'guest': ['login'],
    };
