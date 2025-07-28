import 'package:flutter/material.dart';
import 'package:flutter_policy_engine/flutter_policy_engine.dart';

class JsonAssetsDemo extends StatefulWidget {
  const JsonAssetsDemo({super.key});

  @override
  State<JsonAssetsDemo> createState() => _JsonAssetsDemoState();
}

class _JsonAssetsDemoState extends State<JsonAssetsDemo> {
  final PolicyManager _policyManager = PolicyManager();
  bool _isInitialized = false;
  bool _isLoading = false;
  String _selectedRole = 'admin';
  String _selectedPermission = 'read';
  String _lastResult = '';
  String _errorMessage = '';

  final List<String> _availableRoles = [
    'admin',
    'manager',
    'editor',
    'viewer',
    'guest',
  ];

  final List<String> _availablePermissions = [
    'read',
    'write',
    'delete',
    'manage_users',
    'system_config',
    'manage_team',
    'publish',
  ];

  @override
  void initState() {
    super.initState();
    _initializePolicyManager();
  }

  Future<void> _initializePolicyManager() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _policyManager
          .initializeFromJsonAssets('assets/policies/user_roles.json');

      setState(() {
        _isInitialized = _policyManager.isInitialized;
        _isLoading = false;
        _lastResult = _isInitialized
            ? '✅ Policy manager initialized successfully from JSON assets!'
            : '❌ Failed to initialize policy manager';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
        _lastResult = '❌ Initialization failed';
      });
    }
  }

  void _testPermission() {
    if (!_isInitialized) {
      setState(() {
        _lastResult = '❌ Policy manager not initialized';
      });
      return;
    }

    try {
      final role = _policyManager.roles[_selectedRole];
      if (role != null) {
        final hasPermission = role.allowedContent.contains(_selectedPermission);
        setState(() {
          _lastResult = hasPermission
              ? '✅ Role "$_selectedRole" has permission "$_selectedPermission"'
              : '❌ Role "$_selectedRole" does NOT have permission "$_selectedPermission"';
        });
      } else {
        setState(() {
          _lastResult = '❌ Role "$_selectedRole" not found';
        });
      }
    } catch (e) {
      setState(() {
        _lastResult = '❌ Error testing permission: $e';
      });
    }
  }

  void _getRoleInfo() {
    if (!_isInitialized) {
      setState(() {
        _lastResult = '❌ Policy manager not initialized';
      });
      return;
    }

    try {
      final role = _policyManager.roles[_selectedRole];
      if (role != null) {
        setState(() {
          _lastResult = '''
✅ Role Information for "$_selectedRole":
   Name: ${role.name}
   Allowed Content: ${role.allowedContent.join(', ')}
''';
        });
      } else {
        setState(() {
          _lastResult = '❌ Role "$_selectedRole" not found';
        });
      }
    } catch (e) {
      setState(() {
        _lastResult = '❌ Error getting role info: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Assets Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Initialization Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.error,
                          color: _isInitialized ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Policy Manager Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const LinearProgressIndicator()
                    else
                      Text(
                        _isInitialized
                            ? '✅ Initialized from JSON assets'
                            : '❌ Not initialized',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                            ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _initializePolicyManager,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reinitialize'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Role Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role Selection',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Select Role',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableRoles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRole = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Permission Testing Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permission Testing',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPermission,
                      decoration: const InputDecoration(
                        labelText: 'Select Permission',
                        border: OutlineInputBorder(),
                      ),
                      items: _availablePermissions.map((permission) {
                        return DropdownMenuItem(
                          value: permission,
                          child: Text(permission),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPermission = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isInitialized ? _testPermission : null,
                      icon: const Icon(Icons.security),
                      label: const Text('Test Permission'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Role Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isInitialized ? _getRoleInfo : null,
                      icon: const Icon(Icons.info),
                      label: const Text('Get Role Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Results Card
            if (_lastResult.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _lastResult,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
