import 'package:flutter/material.dart';
import 'package:clean_flutter/core/services/simple_sync_service.dart';
import 'package:clean_flutter/locator.dart';
import 'local_data_viewer_page.dart';

class BackendSyncPage extends StatefulWidget {
  const BackendSyncPage({super.key});

  @override
  State<BackendSyncPage> createState() => _BackendSyncPageState();
}

class _BackendSyncPageState extends State<BackendSyncPage> {
  final SimpleSyncService _syncService = locator<SimpleSyncService>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _testDataController = TextEditingController();
  
  bool _isLoading = false;
  String _statusMessage = '';
  bool _backendHealthy = false;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
    _syncService.init();
  }

  Future<void> _checkBackendHealth() async {
    final healthy = await _syncService.checkBackendHealth();
    setState(() {
      _backendHealthy = healthy;
      _statusMessage = healthy ? 'Backend is healthy ✅' : 'Backend is not responding ❌';
    });
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Registering...';
    });

    final result = await _syncService.registerOnBackend(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
      if (result['error'] != null) {
        _statusMessage = 'Registration failed: ${result['error']}';
      } else {
        _statusMessage = 'Registration successful! ✅';
      }
    });
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Logging in...';
    });

    final result = await _syncService.loginToBackend(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
      if (result['error'] != null) {
        _statusMessage = 'Login failed: ${result['error']}';
      } else {
        _statusMessage = 'Login successful! Sync enabled ✅';
        // Auto-sync TOTP secrets after successful login
        _syncTotpSecrets();
      }
    });
  }

  Future<void> _logout() async {
    await _syncService.logoutFromBackend();
    setState(() {
      _statusMessage = 'Logged out. Sync disabled.';
    });
  }

  Future<void> _syncTotpSecrets() async {
    setState(() {
      _statusMessage = 'Syncing TOTP secrets...';
    });

    try {
      final success = await _syncService.syncUserDataToBackend();
      setState(() {
        _statusMessage = success 
          ? 'TOTP secrets synced successfully! ✅' 
          : 'Failed to sync TOTP secrets ❌';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error syncing TOTP secrets: $e';
      });
    }
  }

  Future<void> _syncTestData() async {
    if (_testDataController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter test data to sync';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Syncing data...';
    });

    final success = await _syncService.syncTextToBackend('test_data', _testDataController.text);

    setState(() {
      _isLoading = false;
      _statusMessage = success ? 'Data synced successfully! ✅' : 'Failed to sync data ❌';
    });
  }

  Future<void> _retrieveTestData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Retrieving data...';
    });

    final data = await _syncService.getTextFromBackend('test_data');

    setState(() {
      _isLoading = false;
      if (data != null) {
        _testDataController.text = data;
        _statusMessage = 'Data retrieved successfully! ✅';
      } else {
        _statusMessage = 'No data found or failed to retrieve ❌';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Sync'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Backend Health Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Backend Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _checkBackendHealth,
                      child: const Text('Check Health'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Authentication Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Authentication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            child: const Text('Register'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: const Text('Login'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_syncService.isBackendAuthenticated)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Logout'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Local Data Viewer Card
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storage, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Local Database', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'View and manage all locally stored data including users, TOTP secrets, and sync data.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LocalDataViewerPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Local Database'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Data Sync Test Section
            if (_syncService.isBackendAuthenticated)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Test Data Sync', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _testDataController,
                        decoration: const InputDecoration(
                          labelText: 'Test Data',
                          border: OutlineInputBorder(),
                          hintText: 'Enter some text to sync...',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _syncTestData,
                              child: const Text('Sync to Backend'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _retrieveTestData,
                              child: const Text('Retrieve from Backend'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _testDataController.dispose();
    super.dispose();
  }
}
