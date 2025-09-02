import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/webauthn_service.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../locator.dart';
import 'package:intl/intl.dart';

class PasskeysPage extends StatefulWidget {
  const PasskeysPage({Key? key}) : super(key: key);

  @override
  State<PasskeysPage> createState() => _PasskeysPageState();
}

class _PasskeysPageState extends State<PasskeysPage> {
  final WebAuthnService _webAuthnService = locator<WebAuthnService>();
  final AuthService _authService = locator<AuthService>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _webAuthnService.initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passkeys'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ChangeNotifierProvider<WebAuthnService>.value(
        value: _webAuthnService,
        child: Consumer<WebAuthnService>(
          builder: (context, service, child) {
            if (!service.isSupported) {
              return _buildNotSupportedWidget();
            }

            return Column(
              children: [
                _buildHeader(service),
                Expanded(
                  child: service.credentials.isEmpty
                      ? _buildEmptyState()
                      : _buildCredentialsList(service),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader(WebAuthnService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fingerprint,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passwordless Authentication',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in faster and more securely with passkeys',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (service.credentials.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${service.credentials.length} passkey${service.credentials.length > 1 ? 's' : ''} registered',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.key_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Passkeys Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Add a passkey to enable passwordless sign-in',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addPasskey,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Passkey'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsList(WebAuthnService service) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.credentials.length,
      itemBuilder: (context, index) {
        final credential = service.credentials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                _getDeviceIcon(credential.platform),
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              credential.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Created: ${DateFormat('MMM d, yyyy').format(credential.createdAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Last used: ${_formatLastUsed(credential.lastUsed)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    _renamePasskey(credential);
                    break;
                  case 'delete':
                    _deletePasskey(credential);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Rename'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotSupportedWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber,
              size: 80,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Passkeys Not Supported',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Your device or browser doesn\'t support passkeys. Please use a compatible device or update your browser.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return ChangeNotifierProvider<WebAuthnService>.value(
      value: _webAuthnService,
      child: Consumer<WebAuthnService>(
        builder: (context, service, child) {
          if (!service.isSupported || service.isRegistering) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: _addPasskey,
            icon: const Icon(Icons.add),
            label: const Text('Add Passkey'),
          );
        },
      ),
    );
  }

  IconData _getDeviceIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'iphone':
      case 'ios':
        return Icons.phone_iphone;
      case 'android':
        return Icons.phone_android;
      case 'desktop':
      case 'macos':
      case 'windows':
      case 'linux':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(lastUsed);
    }
  }

  Future<void> _addPasskey() async {
    _nameController.text = '${_getDeviceName()}\'s Passkey';

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Passkey'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Give this passkey a name to help you identify it later.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Passkey Name',
                hintText: 'e.g., iPhone 14 Pro',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _nameController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final userId = _authService.currentUser;
      if (userId != null) {
        final result = await _webAuthnService.registerPasskey(
          userId: userId,
          username: userId, // Using userId as username for now
          displayName: name,
        );

        if (mounted) {
          if (result?.success == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Passkey added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add passkey: ${result?.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _renamePasskey(PasskeyCredential credential) async {
    _nameController.text = credential.name;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Passkey'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'New Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _nameController.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != credential.name) {
      final success = await _webAuthnService.renamePasskey(
        credential.id,
        newName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Passkey renamed successfully'
                  : 'Failed to rename passkey',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePasskey(PasskeyCredential credential) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Passkey'),
        content: Text(
          'Are you sure you want to delete "${credential.name}"?\n\n'
          'You won\'t be able to use this passkey to sign in anymore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _webAuthnService.deletePasskey(credential.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Passkey deleted successfully'
                  : 'Failed to delete passkey',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  String _getDeviceName() {
    // This would detect actual device name
    return 'This Device';
  }
}
