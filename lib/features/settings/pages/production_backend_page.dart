import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clean_flutter/core/config/app_config.dart';
import 'package:clean_flutter/core/services/simple_sync_service.dart';
import 'package:clean_flutter/locator.dart';

class ProductionBackendPage extends StatefulWidget {
  const ProductionBackendPage({super.key});

  @override
  State<ProductionBackendPage> createState() => _ProductionBackendPageState();
}

class _ProductionBackendPageState extends State<ProductionBackendPage> {
  final SimpleSyncService _syncService = locator<SimpleSyncService>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _statusMessage = '';
  bool _backendHealthy = false;
  String _currentEnvironment = 'development';

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
    _syncService.init();
    _updateEnvironmentStatus();
  }

  void _updateEnvironmentStatus() {
    setState(() {
      if (AppConfig.isDevelopment) _currentEnvironment = 'Development (Local)';
      if (AppConfig.isStaging) _currentEnvironment = 'Staging (Render)';
      if (AppConfig.isProduction) _currentEnvironment = 'Production (Render)';
    });
  }

  Future<void> _checkBackendHealth() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking backend health...';
    });

    final healthy = await _syncService.checkBackendHealth();
    setState(() {
      _isLoading = false;
      _backendHealthy = healthy;
      _statusMessage = healthy 
        ? 'Backend is healthy ✅' 
        : 'Backend is not responding ❌\nCheck if your Render service is running';
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
      _statusMessage = 'Creating account on production backend...';
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
        _statusMessage = 'Account created successfully! ✅\nYou can now login to sync your data.';
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
      _statusMessage = 'Connecting to production backend...';
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
        _statusMessage = 'Connected to production backend! ✅\nYour data will now sync automatically.';
        _syncTotpSecrets();
      }
    });
  }

  Future<void> _logout() async {
    await _syncService.logoutFromBackend();
    setState(() {
      _statusMessage = 'Disconnected from production backend.\nData sync disabled.';
    });
  }

  Future<void> _syncTotpSecrets() async {
    setState(() {
      _statusMessage = 'Syncing your TOTP secrets to production...';
    });

    try {
      final success = await _syncService.syncUserDataToBackend();
      setState(() {
        _statusMessage = success 
          ? 'TOTP secrets synced to production! ✅\nYour data is now backed up securely.' 
          : 'Failed to sync TOTP secrets ❌';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error syncing TOTP secrets: $e';
      });
    }
  }

  void _copyBackendUrl() {
    Clipboard.setData(ClipboardData(text: AppConfig.backendUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backend URL copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Backend'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Environment Info
              Card(
                color: AppConfig.isProduction 
                  ? Colors.green.shade50 
                  : AppConfig.isStaging 
                    ? Colors.orange.shade50 
                    : Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            AppConfig.isProduction 
                              ? Icons.cloud_done 
                              : AppConfig.isStaging 
                                ? Icons.cloud_queue 
                                : Icons.developer_mode,
                            color: AppConfig.isProduction 
                              ? Colors.green 
                              : AppConfig.isStaging 
                                ? Colors.orange 
                                : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Environment: $_currentEnvironment',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Backend: ${AppConfig.backendUrl}',
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyBackendUrl,
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: 'Copy URL',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Backend Health Status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _backendHealthy ? Icons.health_and_safety : Icons.error,
                            color: _backendHealthy ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          const Text('Backend Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_statusMessage),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _checkBackendHealth,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Check Health'),
                        ),
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
                      Row(
                        children: [
                          Icon(
                            _syncService.isBackendAuthenticated ? Icons.verified_user : Icons.login,
                            color: _syncService.isBackendAuthenticated ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Text('Production Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (!_syncService.isBackendAuthenticated) ...[
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _register,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Create Account'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _login,
                                icon: const Icon(Icons.login),
                                label: const Text('Login'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_done, color: Colors.green),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Connected to production backend\nYour data is syncing automatically',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _syncTotpSecrets,
                                icon: const Icon(Icons.sync),
                                label: const Text('Sync Now'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout),
                                label: const Text('Disconnect'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),

              const SizedBox(height: 16),
              
              // Instructions Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('How to Deploy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Create a Render account at render.com\n'
                        '2. Create a PostgreSQL database\n'
                        '3. Deploy the backend web service\n'
                        '4. Update the backend URL in app config\n'
                        '5. Create your production account here',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
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
    super.dispose();
  }
}
