import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_policy_engine/flutter_policy_engine.dart';

class RoleManagementDemo extends StatefulWidget {
  const RoleManagementDemo({super.key});

  @override
  State<RoleManagementDemo> createState() => _RoleManagementDemoState();
}

class _RoleManagementDemoState extends State<RoleManagementDemo> {
  late PolicyManager policyManager;
  bool _isInitialized = false;
  String _selectedRole = 'guest';

  // Form controllers for role management
  final TextEditingController _roleNameController = TextEditingController();
  final TextEditingController _permissionsController = TextEditingController();

  // Status messages
  String _statusMessage = '';
  bool _isSuccess = true;

  @override
  void initState() {
    super.initState();
    _initializePolicyManager();
  }

  @override
  void dispose() {
    _roleNameController.dispose();
    _permissionsController.dispose();
    super.dispose();
  }

  Future<void> _initializePolicyManager() async {
    policyManager = PolicyManager();
    final policies = {
      "admin": ["LoginPage", "Dashboard", "UserManagement", "Settings"],
      "user": ["LoginPage", "Dashboard"],
      "guest": ["LoginPage"]
    };
    try {
      await policyManager.initialize(policies);
      setState(() {
        _isInitialized = true;
        _selectedRole = 'guest';
      });
    } catch (e) {
      log(e.toString());
      setState(() {
        _isInitialized = false;
        _statusMessage = 'Failed to initialize: $e';
        _isSuccess = false;
      });
    }
  }

  void _showStatus(String message, bool isSuccess) {
    setState(() {
      _statusMessage = message;
      _isSuccess = isSuccess;
    });

    // Clear status after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  Future<void> _addRole() async {
    final roleName = _roleNameController.text.trim();
    final permissionsText = _permissionsController.text.trim();

    if (roleName.isEmpty) {
      _showStatus('Role name cannot be empty', false);
      return;
    }

    try {
      final permissions = permissionsText.isEmpty
          ? <String>[]
          : permissionsText.split(',').map((e) => e.trim()).toList();

      final role = Role(name: roleName, allowedContent: permissions);
      await policyManager.addRole(role);

      _showStatus('Role "$roleName" added successfully', true);
      _roleNameController.clear();
      _permissionsController.clear();

      // Update selected role if it's the new one
      setState(() {
        _selectedRole = roleName;
      });
    } catch (e) {
      _showStatus('Failed to add role: $e', false);
    }
  }

  Future<void> _removeRole() async {
    final roleName = _roleNameController.text.trim();

    if (roleName.isEmpty) {
      _showStatus('Role name cannot be empty', false);
      return;
    }

    try {
      await policyManager.removeRole(roleName);
      _showStatus('Role "$roleName" removed successfully', true);
      _roleNameController.clear();
      _permissionsController.clear();

      // Update selected role if the removed one was selected
      if (_selectedRole == roleName) {
        setState(() {
          _selectedRole = 'guest';
        });
      }
    } catch (e) {
      _showStatus('Failed to remove role: $e', false);
    }
  }

  Future<void> _updateRole() async {
    final roleName = _roleNameController.text.trim();
    final permissionsText = _permissionsController.text.trim();

    if (roleName.isEmpty) {
      _showStatus('Role name cannot be empty', false);
      return;
    }

    try {
      final permissions = permissionsText.isEmpty
          ? <String>[]
          : permissionsText.split(',').map((e) => e.trim()).toList();

      final role = Role(name: roleName, allowedContent: permissions);
      await policyManager.updateRole(roleName, role);

      _showStatus('Role "$roleName" updated successfully', true);
      _roleNameController.clear();
      _permissionsController.clear();
    } catch (e) {
      _showStatus('Failed to update role: $e', false);
    }
  }

  List<String> _getAvailableRoles() {
    return policyManager.roles.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Role Management Demo'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading policies...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Current roles section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Roles',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    ..._getAvailableRoles().map((roleName) {
                      final role = policyManager.roles[roleName];
                      return ListTile(
                        title: Text(roleName),
                        subtitle: Text(
                            'Permissions: ${role?.allowedContent.join(', ') ?? 'None'}'),
                        trailing: roleName == _selectedRole
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedRole = roleName;
                            _roleNameController.text = roleName;
                            _permissionsController.text =
                                role?.allowedContent.join(', ') ?? '';
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Role management form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role Management',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _roleNameController,
                      decoration: const InputDecoration(
                        labelText: 'Role Name',
                        hintText: 'Enter role name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _permissionsController,
                      decoration: const InputDecoration(
                        labelText: 'Permissions',
                        hintText: 'Enter permissions separated by commas',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addRole,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Role'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _updateRole,
                            icon: const Icon(Icons.edit),
                            label: const Text('Update Role'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _removeRole,
                            icon: const Icon(Icons.delete),
                            label: const Text('Remove Role'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Policy testing section
            PolicyProvider(
              policyManager: policyManager,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Policy Testing',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),

                      Text('Selected Role: $_selectedRole'),
                      const SizedBox(height: 16),

                      // Role selector
                      Wrap(
                        spacing: 8,
                        children: _getAvailableRoles().map((role) {
                          return ChoiceChip(
                            label: Text(role),
                            selected: _selectedRole == role,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedRole = role;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Policy examples
                      _buildPolicyExample('LoginPage', 'Login Page'),
                      _buildPolicyExample('Dashboard', 'Dashboard'),
                      _buildPolicyExample('UserManagement', 'User Management'),
                      _buildPolicyExample('Settings', 'Settings'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyExample(String content, String displayName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$displayName:'),
          const SizedBox(height: 4),
          PolicyWidget(
            role: _selectedRole,
            content: content,
            fallback: Card(
              color: Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Access denied for $displayName'),
              ),
            ),
            onAccessDenied: () {
              log('Access denied for $_selectedRole to $content');
            },
            child: Card(
              color: Colors.green[100],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Access granted to $displayName'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
