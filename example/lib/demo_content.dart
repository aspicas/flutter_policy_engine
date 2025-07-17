import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_policy_engine/flutter_policy_engine.dart';

class DemoContent extends StatefulWidget {
  const DemoContent({super.key});

  @override
  State<DemoContent> createState() => _DemoContentState();
}

class _DemoContentState extends State<DemoContent> {
  String _currentRole = 'guest';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rol actual: $_currentRole',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Selector de rol
          Row(
            children: [
              _buildRoleButton('guest'),
              const SizedBox(width: 8),
              _buildRoleButton('user'),
              const SizedBox(width: 8),
              _buildRoleButton('admin'),
            ],
          ),

          const SizedBox(height: 32),

          // Ejemplos de PolicyWidget
          _buildPolicyExample('LoginPage', 'Página de Login'),
          _buildPolicyExample('Dashboard', 'Dashboard'),
          _buildPolicyExample('UserManagement', 'Gestión de Usuarios'),
          _buildPolicyExample('Settings', 'Configuración'),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String role) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentRole = role;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _currentRole == role ? Colors.blue : Colors.grey,
      ),
      child: Text(role),
    );
  }

  Widget _buildPolicyExample(String content, String displayName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$displayName:'),
          const SizedBox(height: 4),
          PolicyWidget(
            role: _currentRole,
            content: content,
            fallback: Card(
              color: Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Acceso denegado para $displayName'),
              ),
            ),
            onAccessDenied: () {
              log('Acceso denegado para $_currentRole a $content');
            },
            child: Card(
              color: Colors.green[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Acceso permitido a $displayName'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
