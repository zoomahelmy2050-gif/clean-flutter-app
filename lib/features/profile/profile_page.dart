import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';
import '../../generated/app_localizations.dart';
import '../../core/services/language_service.dart';
import 'package:clean_flutter/core/services/user_profile_service.dart';
import 'package:clean_flutter/features/profile/personal_information_page.dart';
import 'package:clean_flutter/features/profile/notifications_page.dart';
import 'package:clean_flutter/features/profile/appearance_page.dart';
import 'package:clean_flutter/features/profile/help_center_page.dart';
import 'package:clean_flutter/features/profile/send_feedback_page.dart';
import 'package:clean_flutter/features/profile/change_password_page.dart';
import 'package:clean_flutter/features/profile/security_hub_page.dart';
import 'package:clean_flutter/features/auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = locator<AuthService>();
  String? _currentUser;
  bool _isLoading = false;
  Map<String, dynamic> _userStats = {};

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock loading user statistics - in real app, load from backend
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _userStats = {
            'securityScore': _calculateSecurityScore(),
            'lastLogin': DateTime.now().subtract(const Duration(hours: 2)),
            'accountAge': DateTime.now().subtract(const Duration(days: 45)),
            'totalSessions': 127,
            'activeDevices': 3,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final l10n = AppLocalizations.of(context)!;
                return Text('Failed to load user statistics');
              },
            ),
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

  int _calculateSecurityScore() {
    int score = 40; // Base score for email/password

    if (_currentUser != null) {
      if (_authService.isUserTotpEnrolled(_currentUser!)) score += 30;
      if (_authService.hasUserBackupCodes(_currentUser!)) score += 20;
      // Add more security factors as needed
    }

    return score.clamp(0, 100);
  }

  Future<bool?> _showPasswordVerificationDialog() async {
    // Check if user is a Google user - if so, skip password verification
    if (_currentUser != null && _authService.isGoogleUser(_currentUser!)) {
      // For Google users, show a dialog explaining they need to set a password first
      final shouldSetPassword = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set Password Required'),
          content: const Text(
            'You signed in with Google and don\'t have a password set. Would you like to set one now to access security features?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Set Password'),
            ),
          ],
        ),
      );
      
      if (shouldSetPassword == true && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ChangePasswordPage(),
          ),
        );
      }
      return null;
    }

    final passwordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    Future<void> verifyPassword(StateSetter dialogSetState) async {
      if (passwordController.text.isEmpty) {
        dialogSetState(() => errorMessage = 'Please enter your password');
        return;
      }

      dialogSetState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        final isValid = await _authService.reauthenticateWithPassword(
          _currentUser!,
          passwordController.text,
        );

        if (isValid) {
          if (mounted) Navigator.of(context).pop(true);
        } else {
          dialogSetState(() {
            errorMessage = 'Incorrect password. Please try again.';
            isLoading = false;
          });
        }
      } catch (e) {
        dialogSetState(() {
          errorMessage = 'Verification failed. Please try again.';
          isLoading = false;
        });
      }
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Consumer<LanguageService>(
                  builder: (context, languageService, child) {
                    final l10n = AppLocalizations.of(context)!;
                    return Text(l10n.securityVerification);
                  },
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please enter your password to access Security Hub',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    errorText: errorMessage,
                    isDense: true,
                  ),
                  onSubmitted: (_) => verifyPassword(dialogSetState),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () => verifyPassword(dialogSetState),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  Future<void> _navigateToSecurityHub() async {
    // Check if user is a Google user - if so, skip password verification
    if (_currentUser != null && _authService.isGoogleUser(_currentUser!)) {
      // For Google users, show a dialog explaining they need to set a password first
      final shouldSetPassword = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set Password Required'),
          content: const Text(
            'You signed in with Google and don\'t have a password set. Would you like to set one now to access security features?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Set Password'),
            ),
          ],
        ),
      );
      
      if (shouldSetPassword == true && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ChangePasswordPage(),
          ),
        );
      }
      return;
    }

    // For traditional users, show password verification first
    final verified = await _showPasswordVerificationDialog();
    if (verified == true && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SecurityHubPage(email: _currentUser ?? ''),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.logout);
          },
        ),
        content: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.logoutConfirmation);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.logout);
              },
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.logout();
        if (mounted) {
          Navigator.of(
            context,
          ).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Consumer<LanguageService>(
                builder: (context, languageService, child) {
                  final l10n = AppLocalizations.of(context)!;
                  return Text(l10n.logoutFailed);
                },
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToPage(Widget page, String pageName) {
    try {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Consumer<LanguageService>(
            builder: (context, languageService, child) {
              final l10n = AppLocalizations.of(context)!;
              return Text(l10n.failedToOpenPage(pageName));
            },
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Color _getSecurityScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getSecurityScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.profile);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadUserStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentUser ?? 'User',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Consumer<LanguageService>(
                                    builder: (context, languageService, child) {
                                      final l10n = AppLocalizations.of(context)!;
                                      return Text(
                                        l10n.environmentalCenter,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Security Section
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(
                          l10n.security,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Column(
                        children: [
                          Consumer<LanguageService>(
                            builder: (context, languageService, child) {
                              final l10n = AppLocalizations.of(context)!;
                              return ListTile(
                                leading: const Icon(Icons.security),
                                title: Text(l10n.securityHub),
                                subtitle: Text(l10n.securityHubSubtitle),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: _navigateToSecurityHub,
                              );
                            },
                          ),
                          const Divider(height: 1),
                          Consumer<LanguageService>(
                            builder: (context, languageService, child) {
                              final l10n = AppLocalizations.of(context)!;
                              return ListTile(
                                leading: const Icon(Icons.verified_user, color: Colors.green),
                                title: Text(l10n.accountStatus),
                                subtitle: Text(l10n.accountStatusSubtitle),
                                trailing: Container(
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
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Account Section
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(
                          l10n.account,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Column(
                        children: [
                          Consumer<LanguageService>(
                            builder: (context, languageService, child) {
                              final l10n = AppLocalizations.of(context)!;
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(l10n.personalInformation),
                                subtitle: Text(l10n.personalInformationSubtitle),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () => _navigateToPage(
                                  const PersonalInformationPage(),
                                  l10n.personalInformation,
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          Consumer<LanguageService>(
                            builder: (context, languageService, child) {
                              final l10n = AppLocalizations.of(context)!;
                              return ListTile(
                                leading: const Icon(Icons.notifications),
                                title: Text(l10n.notifications),
                                subtitle: Text(l10n.notificationsSubtitle),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () => _navigateToPage(
                                  const NotificationsPage(),
                                  l10n.notifications,
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          Consumer<LanguageService>(
                            builder: (context, languageService, child) {
                              final l10n = AppLocalizations.of(context)!;
                              return ListTile(
                                leading: const Icon(Icons.palette),
                                title: Text(l10n.appearance),
                                subtitle: Text(l10n.appearanceSubtitle),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () => _navigateToPage(
                                  const AppearancePage(),
                                  l10n.appearance,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Support Section
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(
                          l10n.helpCenter,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Column(
                        children: [
                          Consumer<LanguageService>(
                            builder: (context, languageService, child) {
                              final l10n = AppLocalizations.of(context)!;
                              return ListTile(
                                leading: const Icon(Icons.help_outline),
                                title: Text(l10n.helpCenter),
                                subtitle: const Text('Get support and find answers'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () => _navigateToPage(
                                  const HelpCenterPage(),
                                  l10n.helpCenter,
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          Consumer<LanguageService>(
                            builder: (context, languageService, child) {
                              final l10n = AppLocalizations.of(context)!;
                              return ListTile(
                                leading: const Icon(Icons.feedback),
                                title: Text(l10n.sendFeedback),
                                subtitle: const Text('Share your thoughts and suggestions'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () => _navigateToPage(
                                  const SendFeedbackPage(),
                                  l10n.sendFeedback,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: Consumer<LanguageService>(
                        builder: (context, languageService, child) {
                          final l10n = AppLocalizations.of(context)!;
                          return OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: Text(
                              l10n.logout,
                              style: const TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
