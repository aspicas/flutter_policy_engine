import 'package:flutter/material.dart';
import 'package:flutter_policy_engine/flutter_policy_engine.dart';

import 'demo_content.dart';

/// Demo 1: Basic RBAC with inline policy map and PolicyGate / PolicyBuilder.
class PolicyEngineDemo extends StatefulWidget {
  const PolicyEngineDemo({super.key});

  @override
  State<PolicyEngineDemo> createState() => _PolicyEngineDemoState();
}

class _PolicyEngineDemoState extends State<PolicyEngineDemo> {
  late final PolicyEngineController _controller;
  bool _initialized = false;
  String _selectedRole = kDemoRoles.first;
  String _selectedResource = kDemoResources.first;
  String _lastResult = '';

  @override
  void initState() {
    super.initState();
    _controller = PolicyEngineController.inMemory();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _controller.loadPolicies(kDemoPolicy);
    setState(() {
      _initialized = result.isOk;
      _lastResult = result.isOk
          ? '✅ Policies loaded successfully.'
          : '❌ ${(result as Err).error.message}';
    });
  }

  Future<void> _evaluate() async {
    final result =
        await _controller.evaluateAccess(_selectedRole, _selectedResource);
    setState(() {
      switch (result) {
        case Ok(:final value):
          _lastResult = value.isGranted
              ? '✅ "$_selectedRole" → "$_selectedResource": GRANTED'
              : '❌ "$_selectedRole" → "$_selectedResource": DENIED';
        case Err(:final error):
          _lastResult = '⚠️ Error: ${error.message}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PolicyEngineScope(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Basic Policy Demo (v2)'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusCard(initialized: _initialized),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evaluate Access',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _RoleDropdown(
                        value: _selectedRole,
                        onChanged: (v) => setState(() => _selectedRole = v!),
                      ),
                      const SizedBox(height: 12),
                      _ResourceDropdown(
                        value: _selectedResource,
                        onChanged: (v) =>
                            setState(() => _selectedResource = v!),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _initialized ? _evaluate : null,
                        icon: const Icon(Icons.security),
                        label: const Text('Evaluate'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_initialized) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PolicyGate widget',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        PolicyGate(
                          roleName: _selectedRole,
                          resourceId: _selectedResource,
                          fallback: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.block, color: Colors.red),
                                const SizedBox(width: 8),
                                Text('Access denied to $_selectedResource'),
                              ],
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text('Access granted to $_selectedResource'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_lastResult.isNotEmpty) _ResultCard(result: _lastResult),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 2: Role Management
// ---------------------------------------------------------------------------

/// Demo 2: CRUD role management with `addRole`, `updateRole`, `removeRole`.
class RoleManagementDemo extends StatefulWidget {
  const RoleManagementDemo({super.key});

  @override
  State<RoleManagementDemo> createState() => _RoleManagementDemoState();
}

class _RoleManagementDemoState extends State<RoleManagementDemo> {
  late final PolicyEngineController _controller;
  List<RoleEntity> _roles = [];
  String _log = '';

  @override
  void initState() {
    super.initState();
    _controller = PolicyEngineController.inMemory();
    _controller.addListener(_refreshRoles);
    _load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refreshRoles)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _controller.loadPolicies(kDemoPolicy);
    await _refreshRoles();
  }

  Future<void> _refreshRoles() async {
    final result = await _controller.listRoles();
    if (mounted) {
      setState(() {
        _roles = result.isOk ? (result as Ok).value as List<RoleEntity> : [];
      });
    }
  }

  Future<void> _addTempRole() async {
    final result = await _controller.addRole(
      RoleEntity(
        name: RoleName('temp_role'),
        allowedResources: const {'dashboard', 'reports'},
      ),
    );
    setState(() {
      _log = result.isOk
          ? '✅ Added "temp_role"'
          : '❌ ${(result as Err).error.message}';
    });
  }

  Future<void> _updateTempRole() async {
    final result = await _controller.updateRole(
      'temp_role',
      RoleEntity(
        name: RoleName('temp_role'),
        allowedResources: const {'dashboard', 'reports', 'analytics'},
      ),
    );
    setState(() {
      _log = result.isOk
          ? '✅ Updated "temp_role" with analytics access'
          : '❌ ${(result as Err).error.message}';
    });
  }

  Future<void> _removeTempRole() async {
    final result = await _controller.removeRole('temp_role');
    setState(() {
      _log = result.isOk
          ? '✅ Removed "temp_role"'
          : '❌ ${(result as Err).error.message}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management Demo (v2)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role CRUD operations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addTempRole,
                          icon: const Icon(Icons.add),
                          label: const Text('Add temp_role'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _updateTempRole,
                          icon: const Icon(Icons.edit),
                          label: const Text('Update temp_role'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _removeTempRole,
                          icon: const Icon(Icons.delete),
                          label: const Text('Remove temp_role'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_log.isNotEmpty) _ResultCard(result: _log),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current roles (${_roles.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._roles.map(
                      (role) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_outline),
                        title: Text(role.name.value),
                        subtitle: Text(
                          role.allowedResources.join(', '),
                          style: Theme.of(context).textTheme.bodySmall,
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

// ---------------------------------------------------------------------------
// Demo 3: JSON Asset loading
// ---------------------------------------------------------------------------

/// Demo 3: Load policies from a bundled JSON asset using `FlutterAssetLoader`.
class JsonAssetsDemo extends StatefulWidget {
  const JsonAssetsDemo({super.key});

  @override
  State<JsonAssetsDemo> createState() => _JsonAssetsDemoState();
}

class _JsonAssetsDemoState extends State<JsonAssetsDemo> {
  late final PolicyEngineController _controller;
  bool _initialized = false;
  bool _loading = false;
  String _selectedRole = kDemoRoles.first;
  String _selectedResource = kDemoResources.first;
  String _lastResult = '';

  @override
  void initState() {
    super.initState();
    _controller = PolicyEngineController.withRepository(
      repository: InMemoryPolicyRepository(),
      assetLoader: const FlutterAssetLoader(),
    );
    _loadFromAsset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFromAsset() async {
    setState(() {
      _loading = true;
      _lastResult = '';
    });
    final result = await _controller
        .loadPoliciesFromAsset('assets/policies/user_roles.json');
    setState(() {
      _loading = false;
      _initialized = result.isOk;
      _lastResult = result.isOk
          ? '✅ Loaded from assets/policies/user_roles.json'
          : '❌ ${(result as Err).error.message}';
    });
  }

  Future<void> _evaluate() async {
    final result =
        await _controller.evaluateAccess(_selectedRole, _selectedResource);
    setState(() {
      switch (result) {
        case Ok(:final value):
          _lastResult = value.isGranted
              ? '✅ "$_selectedRole" → "$_selectedResource": GRANTED'
              : '❌ "$_selectedRole" → "$_selectedResource": DENIED';
        case Err(:final error):
          _lastResult = '⚠️ ${error.message}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PolicyEngineScope(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('JSON Assets Demo (v2)'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusCard(initialized: _initialized, loading: _loading),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _loading ? null : _loadFromAsset,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload from asset'),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evaluate Access',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _RoleDropdown(
                        value: _selectedRole,
                        onChanged: (v) => setState(() => _selectedRole = v!),
                      ),
                      const SizedBox(height: 12),
                      _ResourceDropdown(
                        value: _selectedResource,
                        onChanged: (v) =>
                            setState(() => _selectedResource = v!),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _initialized ? _evaluate : null,
                        icon: const Icon(Icons.security),
                        label: const Text('Evaluate'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_lastResult.isNotEmpty) _ResultCard(result: _lastResult),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helper widgets
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.initialized, this.loading = false});

  final bool initialized;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                initialized ? Icons.check_circle : Icons.error,
                color: initialized ? Colors.green : Colors.red,
              ),
            const SizedBox(width: 12),
            Text(
              loading
                  ? 'Loading policies…'
                  : initialized
                      ? 'Engine ready'
                      : 'Engine not initialized',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Result', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                result,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Role',
        border: OutlineInputBorder(),
      ),
      items: kDemoRoles
          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ResourceDropdown extends StatelessWidget {
  const _ResourceDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Resource',
        border: OutlineInputBorder(),
      ),
      items: kDemoResources
          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
