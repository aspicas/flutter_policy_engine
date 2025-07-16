import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_policy_engine/flutter_policy_engine.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Policy Engine Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PolicyEngineDemo(),
    );
  }
}

class PolicyEngineDemo extends StatefulWidget {
  const PolicyEngineDemo({super.key});

  @override
  State<StatefulWidget> createState() {
    return _PolicyEngineDemoState();
  }
}

class _PolicyEngineDemoState extends State<PolicyEngineDemo> {
  late PolicyManager policyManager;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePolicyManager();
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
      });
    } catch (e) {
      log(e.toString());
      setState(() {
        _isInitialized = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Policy Engine Demo'),
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
    return const Center(
      child: Text('Policies loaded'),
    );
  }
}
