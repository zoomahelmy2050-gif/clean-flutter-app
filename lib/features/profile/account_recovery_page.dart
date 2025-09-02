import 'package:flutter/material.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';
import 'package:clean_flutter/core/services/user_profile_service.dart';
import 'package:clean_flutter/core/services/enhanced_backup_codes_service.dart';
import 'package:clean_flutter/core/services/email_service.dart';

class AccountRecoveryPage extends StatefulWidget {
  const AccountRecoveryPage({super.key});

  @override
  State<AccountRecoveryPage> createState() => _AccountRecoveryPageState();
}

class _AccountRecoveryPageState extends State<AccountRecoveryPage> {
  final _authService = locator<AuthService>();
  final _profileService = locator<UserProfileService>();
  final _backupCodesService = locator<EnhancedBackupCodesService>();
  final _emailService = locator<EmailService>();
  final _recoveryEmailController = TextEditingController();
  final _recoveryPhoneController = TextEditingController();

  bool _isLoading = false;
  String? _currentUser;

  // Recovery options status
  bool _hasBackupCodes = false;
  bool _hasTOTP = false;
  bool _hasRecoveryEmail = false;
  bool _hasRecoveryPhone = false;

  // Mock recovery data
  String _recoveryEmail = '';
  String _recoveryPhone = '';

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadRecoveryStatus();
  }

  @override
  void dispose() {
    _recoveryEmailController.dispose();
    _recoveryPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadRecoveryStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentUser != null) {
        // Load user profile to get recovery email/phone
        final profileSuccess = await _profileService.loadUserProfile(_currentUser!);
        if (profileSuccess && _profileService.currentProfile != null) {
          final profile = _profileService.currentProfile!;
          _recoveryEmail = profile.email;
          _recoveryPhone = profile.phone ?? '';
          _hasRecoveryEmail = _recoveryEmail.isNotEmpty;
          _hasRecoveryPhone = _recoveryPhone.isNotEmpty;
        }

        // Check backup codes status
        final backupCodesSuccess = await _backupCodesService.loadBackupCodes(_currentUser!);
        if (backupCodesSuccess) {
          _hasBackupCodes = _backupCodesService.backupCodes.isNotEmpty;
        }

        // Check TOTP status (mock for now)
        _hasTOTP = _authService.isUserTotpEnrolled(_authService.currentUser ?? '');
        // Check existing recovery methods
        _hasBackupCodes = _authService.hasUserBackupCodes(_currentUser!);
        _hasTOTP = _authService.isUserTotpEnrolled(_currentUser!);

        // Mock recovery contact info - in real app, load from backend
        _recoveryEmail = 'recovery@example.com';
        _recoveryPhone = '+1 (555) 123-4567';
        _hasRecoveryEmail = _recoveryEmail.isNotEmpty;
        _hasRecoveryPhone = _recoveryPhone.isNotEmpty;

        _recoveryEmailController.text = _recoveryEmail;
        _recoveryPhoneController.text = _recoveryPhone;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load recovery status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateRecoveryEmail() async {
    final email = _recoveryEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a recovery email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _recoveryEmail = email;
      _hasRecoveryEmail = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery email updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _updateRecoveryPhone() async {
    final phone = _recoveryPhoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a recovery phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _recoveryPhone = phone;
      _hasRecoveryPhone = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery phone updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _removeRecoveryMethod(String method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $method'),
        content: Text(
          'Are you sure you want to remove $method as a recovery method?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        if (method == 'Recovery Email') {
          _hasRecoveryEmail = false;
          _recoveryEmail = '';
          _recoveryEmailController.clear();
        } else if (method == 'Recovery Phone') {
          _hasRecoveryPhone = false;
          _recoveryPhone = '';
          _recoveryPhoneController.clear();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$method removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  int _getRecoveryScore() {
    int score = 0;
    if (_hasBackupCodes) score++;
    if (_hasTOTP) score++;
    if (_hasRecoveryEmail) score++;
    if (_hasRecoveryPhone) score++;
    return score;
  }

  String _getRecoveryLevel() {
    final score = _getRecoveryScore();
    if (score >= 3) return 'Excellent';
    if (score >= 2) return 'Good';
    if (score >= 1) return 'Basic';
    return 'Poor';
  }

  Color _getRecoveryColor() {
    final score = _getRecoveryScore();
    if (score >= 3) return Colors.green;
    if (score >= 2) return Colors.orange;
    if (score >= 1) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recoveryScore = _getRecoveryScore();
    final maxScore = 4;

    return Scaffold(
      appBar: AppBar(title: const Text('Account Recovery'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recovery Score Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shield,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Recovery Readiness',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildRecoveryScoreWidget(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recovery Methods Section
                  Text(
                    'Recovery Methods',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        _buildRecoveryMethodTile(
                          icon: Icons.backup,
                          title: 'Backup Codes',
                          subtitle: _hasBackupCodes
                              ? 'Recovery codes are set up'
                              : 'Set up backup codes for recovery',
                          isActive: _hasBackupCodes,
                          onTap: () {
                            // Navigate to backup codes page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Use Security Hub to manage backup codes',
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildRecoveryMethodTile(
                          icon: Icons.security,
                          title: 'Authenticator App',
                          subtitle: _hasTOTP
                              ? 'TOTP authenticator is set up'
                              : 'Set up authenticator app',
                          isActive: _hasTOTP,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Use Security Hub to manage TOTP',
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recovery Contacts Section
                  Text(
                    'Recovery Contacts',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recovery Email
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                color: _hasRecoveryEmail
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Recovery Email',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _recoveryEmailController,
                            decoration: InputDecoration(
                              labelText: 'Recovery Email Address',
                              hintText: 'Enter recovery email',
                              border: const OutlineInputBorder(),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_hasRecoveryEmail)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeRecoveryMethod(
                                        'Recovery Email',
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.save),
                                    onPressed: _updateRecoveryEmail,
                                  ),
                                ],
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 24),

                          // Recovery Phone
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                color: _hasRecoveryPhone
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Recovery Phone',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _recoveryPhoneController,
                            decoration: InputDecoration(
                              labelText: 'Recovery Phone Number',
                              hintText: 'Enter recovery phone',
                              border: const OutlineInputBorder(),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_hasRecoveryPhone)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeRecoveryMethod(
                                        'Recovery Phone',
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.save),
                                    onPressed: _updateRecoveryPhone,
                                  ),
                                ],
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recovery Instructions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'How Account Recovery Works',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1. If you lose access to your account, you can use any of the recovery methods above\n'
                            '2. Backup codes provide immediate access - each code can only be used once\n'
                            '3. Recovery email/phone will receive verification codes\n'
                            '4. Authenticator apps can generate recovery codes\n'
                            '5. Having multiple recovery methods increases your account security',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Security Warning
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important Security Notice',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Keep your recovery information secure and up-to-date. If you lose access to all recovery methods, you may permanently lose access to your account.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildRecoveryScoreWidget() {
    final theme = Theme.of(context);
    final score = _getRecoveryScore();
    final maxScore = 4;
    final percentage = (score / maxScore * 100).round();
    final color = _getRecoveryColor();
    final level = _getRecoveryLevel();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recovery Level: $level',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$score of $maxScore recovery methods set up',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.green.withOpacity(0.1)
              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.green : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Set Up',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }
}
