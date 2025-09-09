import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../auth/services/auth_service.dart';
import '../../core/services/enhanced_auth_service.dart';
import '../admin/services/logging_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/language_service.dart';
import '../../generated/app_localizations.dart';
import '../../locator.dart';
import '../admin/services/mfa_settings_service.dart';
import '../admin/security_center_page.dart';
import '../home/home_page.dart';
import 'backup_codes/backup_code_login_page.dart';
import 'otp/otp_verify_page.dart';
import 'password_reset/forgot_password_page.dart';
import 'phone_login_page.dart';
import 'security_setup_page.dart';
import 'services/biometric_service.dart';
import 'services/email_otp_service.dart';
import 'signup_page.dart';
import 'totp/totp_verify_page.dart';
import 'role_selection_page.dart';
import '../../core/services/role_management_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMessage;
  Timer? _errorTimer;
  Timer? _lockoutTimer;
  bool _rememberMe = false;
  bool _showCaptcha = false;
  Timer? _progressiveDelayTimer;
  int _progressiveDelaySeconds = 0;

  late AnimationController _animationController;

  static const String _adminEmail = 'env.hygiene@gmail.com';

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web client ID from your Firebase project
    serverClientId: '951850160974-frhtseulen7rp2hfceesr4onnop5t7mb.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    final auth = locator<AuthService>();
    _rememberMe = auth.rememberMe;
    final remembered = auth.rememberedEmail;
    if (remembered != null && remembered.isNotEmpty) {
      _emailController.text = remembered;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _errorTimer?.cancel();
    _lockoutTimer?.cancel();
    _progressiveDelayTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _showTemporaryError(String message) {
    setState(() {
      _errorMessage = message;
    });
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  void _startLockoutCountdown(Duration duration) {
    _errorTimer?.cancel();
    _lockoutTimer?.cancel();
    int remainingSeconds = duration.inSeconds;

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          _errorMessage = 'You can now try logging in again.';
        });
        _errorTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() => _errorMessage = null);
        });
      } else {
        final minutes = (remainingSeconds / 60).floor().toString().padLeft(
          2,
          '0',
        );
        final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
        setState(() {
          _errorMessage = 'Account locked. Try again in $minutes:$seconds.';
        });
        remainingSeconds--;
      }
    });
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    _proceedWithLogin();
  }


  Future<void> _proceedWithLogin() async {
    _errorTimer?.cancel();
    _lockoutTimer?.cancel();

    final enhancedAuth = locator<EnhancedAuthService>();
    final authService = locator<AuthService>();
    final loggingService = locator<LoggingService>();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (!enhancedAuth.isEmailRegistered(email)) {
      setState(() {
        _errorMessage = 'Email not registered. Please sign up.';
        _loading = false;
      });
      return;
    }

    // Check if login is allowed using the advanced system
    final preCheck = await enhancedAuth.checkLoginAllowed(
      email: email,
      ipAddress: '127.0.0.1',
      userAgent: 'Flutter App',
    );
    
    if (!preCheck['allowed']) {
      // Handle lockout
      if (preCheck['lockoutMinutes'] != null) {
        _startLockoutCountdown(Duration(minutes: preCheck['lockoutMinutes']));
      } else {
        _showTemporaryError(preCheck['error'] ?? 'Login not allowed');
      }
      setState(() => _loading = false);
      return;
    }
    
    // Handle progressive delay
    if (preCheck['progressiveDelay'] != null && preCheck['progressiveDelay'] > 0) {
      setState(() {
        _progressiveDelaySeconds = preCheck['progressiveDelay'];
        _errorMessage = 'Please wait $_progressiveDelaySeconds seconds...';
      });
      
      _progressiveDelayTimer?.cancel();
      _progressiveDelayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_progressiveDelaySeconds <= 1) {
          timer.cancel();
          setState(() {
            _progressiveDelaySeconds = 0;
            _errorMessage = null;
          });
          // Continue with login after delay
          _continueLogin(email, password);
        } else {
          setState(() {
            _progressiveDelaySeconds--;
            _errorMessage = 'Please wait $_progressiveDelaySeconds seconds...';
          });
        }
      });
      
      setState(() => _loading = false);
      return;
    }
    
    // Handle CAPTCHA requirement
    if (preCheck['requiresCaptcha'] == true && !_showCaptcha) {
      setState(() {
        _showCaptcha = true;
        _errorMessage = 'Please complete the security check';
        _loading = false;
      });
      return;
    }
    
    await _continueLogin(email, password);
  }
  
  Future<void> _continueLogin(String email, String password) async {
    final enhancedAuth = locator<EnhancedAuthService>();
    final authService = locator<AuthService>();
    final loggingService = locator<LoggingService>();

    // Use advanced login security system
    final loginResult = await enhancedAuth.login(
      email: email,
      password: password,
      ipAddress: '127.0.0.1', // Mock IP for local testing
      userAgent: 'Flutter App',
    );

    if (loginResult['success'] == true) {
      await enhancedAuth.setRememberMe(_rememberMe, email);
      await authService.setCurrentUser(email);
      try {
        final isMfaEnabled = authService.isUserMfaEnabled(email);
        if (!isMfaEnabled) {
          await loggingService.logSuccessfulLogin(email);
          try {
            final bio = BiometricService();
            if (await bio.canAuthenticate() &&
                !locator<AuthService>().isUserBiometricEnabled(email)) {
              if (!mounted) return;
              final enable = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Enable biometric sign-in?'),
                  content: const Text(
                    'Use fingerprint/Face ID to sign in faster on this device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Not now'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Enable'),
                    ),
                  ],
                ),
              );
              if (enable == true) {
                final ok = await bio.authenticateBiometricOnly(
                  'Enable biometric sign-in',
                );
                if (ok) {
                  await locator<AuthService>().setUserBiometricEnabled(
                    email,
                    true,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Biometric sign-in enabled for this account.',
                        ),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Biometric enrollment was not completed.',
                        ),
                      ),
                    );
                  }
                }
              }
            }
          } catch (_) {}

          if (!mounted) return;

          // Check user role for admin/moderator/super admin
          final roleService = locator<RoleManagementService>();
          final userRole = roleService.getUserRole(email);
          
          // Check if user needs security setup
          if (authService.needsSecuritySetup(email) && email != _adminEmail) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => SecuritySetupPage(email: email),
              ),
              (route) => false,
            );
          } else if (userRole == UserRole.superAdmin || 
                     userRole == UserRole.admin || 
                     userRole == UserRole.moderator) {
            // Show role selection page for admin/moderator/super admin users
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => RoleSelectionPage(
                  userEmail: email,
                  userRole: userRole,
                ),
              ),
              (route) => false,
            );
          } else {
            // Normal user - go to home page
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage(initialTab: 3)),
              (route) => false,
            );
          }
        } else {
          if (!mounted) return;
          final authSvc = locator<AuthService>();
          final bio = BiometricService();

          // Check if user has any MFA methods configured
          final canBio = await bio.canAuthenticate();
          final isBioEnabled = authSvc.isUserBiometricEnabled(email);
          final isTotpEnrolled = authSvc.isUserTotpEnrolled(email);

          // If no MFA methods are configured, skip MFA selection and go to security setup
          if (!isBioEnabled && !isTotpEnrolled) {
            await loggingService.logSuccessfulLogin(email);
            if (!mounted) return;

            // Check user role before navigating
            final roleService = locator<RoleManagementService>();
            final userRole = roleService.getUserRole(email);
            
            if (userRole == UserRole.superAdmin || 
                userRole == UserRole.admin || 
                userRole == UserRole.moderator) {
              // Show role selection page for admin/moderator/super admin users
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => RoleSelectionPage(
                    userEmail: email,
                    userRole: userRole,
                  ),
                ),
                (route) => false,
              );
            } else {
              // Go to security setup screen for normal users
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => SecuritySetupPage(email: email),
                ),
                (route) => false,
              );
            }
            return;
          }

          final defaultMethod = authSvc.getUserMfaMethodPreference(email);
          final choice = await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            builder: (ctx) {
              final tiles = <Widget>[
                const ListTile(title: Text('Choose second factor')),
              ];
              if (canBio && isBioEnabled) {
                tiles.add(
                  ListTile(
                    leading: const Icon(Icons.fingerprint_outlined),
                    title: const Text('Biometric (Recommended)'),
                    subtitle: const Text(
                      'Use Face ID / fingerprint on this device',
                    ),
                    trailing: defaultMethod == 'biometric'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () => Navigator.of(ctx).pop('biometric'),
                  ),
                );
              }
              if (isTotpEnrolled) {
                tiles.add(
                  ListTile(
                    leading: const Icon(Icons.key_outlined),
                    title: const Text('Authenticator App (TOTP)'),
                    subtitle: const Text(
                      'Use 6-digit codes from Google Authenticator, Authy, etc.',
                    ),
                    trailing: defaultMethod == 'totp'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () => Navigator.of(ctx).pop('totp'),
                  ),
                );
              }
              tiles.addAll([
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email OTP'),
                  subtitle: const Text('Receive a one-time code in your inbox'),
                  trailing: defaultMethod == 'otp'
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => Navigator.of(ctx).pop('otp'),
                ),
                const SizedBox(height: 8),
              ]);
              return SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: tiles),
              );
            },
          );

          if (!mounted) return;
          if (choice == 'biometric') {
            await authSvc.setUserMfaMethodPreference(email, 'biometric');

            if (!await bio.canAuthenticate()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Biometrics are not available on this device'),
                ),
              );
              return;
            }
            if (!authSvc.isUserBiometricEnabled(email)) {
              final enroll = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Enable biometric?'),
                  content: const Text(
                    'Enable biometrics for this account on this device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Enable'),
                    ),
                  ],
                ),
              );
              if (enroll == true) {
                final ok = await bio.authenticateBiometricOnly(
                  'Enable biometric sign-in',
                );
                if (ok) {
                  await authSvc.setUserBiometricEnabled(email, true);
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biometric enrollment failed'),
                    ),
                  );
                  return;
                }
              } else {
                return;
              }
            }

            final ok = await bio.authenticateWithDevicePasscode(
              'Authenticate to continue',
            );
            if (ok) {
              await locator<LoggingService>().logMfaBiometric(email);
              await locator<LoggingService>().logSuccessfulLogin(email);
              if (!mounted) return;

              // Check if user needs security setup after MFA
              if (authService.needsSecuritySetup(email) &&
                  email != _adminEmail) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => SecuritySetupPage(email: email),
                  ),
                  (route) => false,
                );
              } else if (email == _adminEmail) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SecurityCenterPage()),
                  (route) => false,
                );
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const HomePage(initialTab: 3),
                  ),
                  (route) => false,
                );
              }
            } else {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Biometric authentication failed'),
                ),
              );
            }
          } else if (choice == 'totp') {
            await authSvc.setUserMfaMethodPreference(email, 'totp');
            if (authSvc.isUserTotpEnrolled(email)) {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TotpVerifyPage(email: email)),
              );
            } else {
              if (!mounted) return;
              await showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Set up authenticator app'),
                  content: const Text('Please set up your authenticator app first.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Consumer<LanguageService>(
                        builder: (context, languageService, child) {
                          final l10n = AppLocalizations.of(context)!;
                          return Text(l10n.or);
                        },
                      ),
                    ),
                  ],
                ),
              );
              await authSvc.setUserMfaMethodPreference(email, 'otp');
              final emailOtpService = context.read<EmailOtpService>();
              await emailOtpService.sendOtp(email);
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => OtpVerifyPage(email: email)),
              );
            }
          } else if (choice == 'otp' || choice == null) {
            await authSvc.setUserMfaMethodPreference(email, 'otp');
            final emailOtpService = context.read<EmailOtpService>();
            await emailOtpService.sendOtp(email);
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OtpVerifyPage(email: email)),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to continue login: $e';
        });
      }
    } else {
      await loggingService.logFailedAttempt(email);
      
      // Handle enhanced authentication errors
      final error = loginResult['error'] ?? 'Login failed';
      final lockoutMinutes = loginResult['lockoutMinutes'];
      final attemptsRemaining = loginResult['attemptsRemaining'];
      final progressiveDelay = loginResult['progressiveDelay'];
      final requiresCaptcha = loginResult['requiresCaptcha'];
      final requiresMFA = loginResult['requiresMFA'];
      final riskScore = loginResult['riskScore'];
      final riskLevel = loginResult['riskLevel'];
      
      developer.log('Login failed - attemptsRemaining: $attemptsRemaining, lockoutMinutes: $lockoutMinutes, risk: $riskLevel ($riskScore)', name: 'LoginPage');
      
      if (lockoutMinutes != null && lockoutMinutes > 0) {
        _startLockoutCountdown(Duration(minutes: lockoutMinutes));
      } else if (progressiveDelay != null && progressiveDelay > 0) {
        _showTemporaryError('Too many attempts. Please wait $progressiveDelay seconds before trying again.');
      } else if (requiresCaptcha == true && !_showCaptcha) {
        setState(() {
          _showCaptcha = true;
          _errorMessage = 'Security check required. $attemptsRemaining attempts remaining.';
        });
      } else if (attemptsRemaining != null && attemptsRemaining > 0) {
        String warningMessage = error;
        if (attemptsRemaining <= 2) {
          warningMessage = '⚠️ Warning: Only $attemptsRemaining attempts remaining before lockout!';
        } else {
          warningMessage = '$error ($attemptsRemaining attempts remaining)';
        }
        if (riskLevel == 'high') {
          warningMessage += '\n⚠️ High risk detected - additional verification may be required';
        }
        _showTemporaryError(warningMessage);
      } else {
        _showTemporaryError(error);
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _onGoogleSignIn() async {
    try {
      setState(() => _loading = true);

      // Clear any previous sign-in state
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        developer.log('Error signing out: $e', name: 'GoogleSignIn');
      }

      // Attempt sign-in with better error handling
      developer.log('Starting Google Sign-In...', name: 'GoogleSignIn');
      final account = await _googleSignIn.signIn();

      if (account == null) {
        developer.log(
          'Google Sign-In was cancelled by user',
          name: 'GoogleSignIn',
        );
        setState(() => _loading = false);
        return;
      }

      // Use standalone Google Sign-In (temporarily bypass Firebase Auth)
      final email = account.email;
      
      if (email.isEmpty) {
        throw Exception('No email found in Google account');
      }
      
      developer.log(
        'Google Sign-In success for: $email',
        name: 'GoogleSignIn',
      );
      final enhancedAuth = locator<EnhancedAuthService>();
      final authService = locator<AuthService>();
      
      // FORCE RELOAD to get latest blocked users from storage
      await authService.reloadBlockedUsers();
      
      // Check if user is blocked FIRST
      print('🔍 Login: Checking if $email is blocked...');
      if (authService.isUserBlocked(email)) {
        print('🚫 Login: User $email IS BLOCKED - denying access');
        if (!mounted) return;
        setState(() => _loading = false);
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Account Blocked'),
            content: Text(
              'The account "$email" has been blocked by an administrator. Please contact support for assistance.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        // Sign out from Google to prevent cached login
        await _googleSignIn.signOut();
        return;
      }
      
      if (!enhancedAuth.isEmailRegistered(email)) {
        if (!mounted) return;
        setState(() => _loading = false);
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Account not found'),
            content: Text(
              'The Google account "$email" is not registered. Please sign up first.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      if (!mounted) return;
      
      // For Google Sign-In, we'll use the regular auth service since it's already authenticated
      await locator<LoggingService>().logSuccessfulLogin(email);
      await authService.setCurrentUser(email);
      setState(() => _loading = false);

      // Check user role for admin/moderator/super admin after Google sign-in
      final roleService = locator<RoleManagementService>();
      final userRole = roleService.getUserRole(email);
      
      // Check if user needs security setup after Google sign-in
      if (authService.needsSecuritySetup(email) &&
          email.toLowerCase() != _adminEmail) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => SecuritySetupPage(email: email)),
          (route) => false,
        );
      } else if (userRole == UserRole.superAdmin || 
                 userRole == UserRole.admin || 
                 userRole == UserRole.moderator) {
        // Show role selection page for admin/moderator/super admin users
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => RoleSelectionPage(
              userEmail: email,
              userRole: userRole,
            ),
          ),
          (route) => false,
        );
      } else {
        // Normal user - go to home page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage(initialTab: 3)),
          (route) => false,
        );
      }
    } catch (e, stackTrace) {
      developer.log('Google Sign-In error: $e', name: 'GoogleSignIn');
      developer.log('Stack trace: $stackTrace', name: 'GoogleSignIn');
      
      // Log detailed error information for debugging
      if (e is PlatformException) {
        developer.log('PlatformException code: ${e.code}', name: 'GoogleSignIn');
        developer.log('PlatformException message: ${e.message}', name: 'GoogleSignIn');
        developer.log('PlatformException details: ${e.details}', name: 'GoogleSignIn');
      }
      
      if (!mounted) return;
      setState(() => _loading = false);
      
      String errorMessage = 'Google sign-in failed: $e';
      if (e is PlatformException) {
        switch (e.code) {
          case 'sign_in_canceled':
            errorMessage = 'Sign-in was cancelled';
            break;
          case 'network_error':
            errorMessage = 'Network error. Please check your connection.';
            break;
          case 'sign_in_failed':
            errorMessage = 'Google sign-in failed. Error code: ${e.code}';
            break;
          default:
            errorMessage = 'Google sign-in failed. Error: ${e.code} - ${e.message}';
        }
      } else if (e.toString().contains('network_error')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMessage = 'Sign-in was cancelled';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage = 'Google sign-in failed. Please try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mfaSettings = locator<MfaSettingsService>();
    final bool backupCodesEnabled = mfaSettings.isBackupCodesEnabled;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          size: 64,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Consumer<LanguageService>(
                          builder: (context, languageService, child) {
                            final l10n = AppLocalizations.of(context)!;
                            return Column(
                              children: [
                                Text(
                                  l10n.welcomeBack,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.loginSubtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        Consumer<LanguageService>(
                          builder: (context, languageService, child) {
                            final l10n = AppLocalizations.of(context)!;
                            return TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: languageService.isArabic ? TextDirection.ltr : null,
                              decoration: InputDecoration(
                                labelText: l10n.usernameOrEmail,
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.enterEmailValidation;
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Consumer<LanguageService>(
                          builder: (context, languageService, child) {
                            final l10n = AppLocalizations.of(context)!;
                            return TextFormField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText: l10n.password,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.enterPasswordValidation;
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(
                                      () => _rememberMe = v ?? false,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Consumer<LanguageService>(
                                  builder: (context, languageService, child) {
                                    final l10n = AppLocalizations.of(context)!;
                                    return Text(l10n.rememberMe);
                                  },
                                ),
                              ],
                            ),
                            Consumer<LanguageService>(
                              builder: (context, languageService, child) {
                                final l10n = AppLocalizations.of(context)!;
                                return TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(ForgotPasswordPage.routeName);
                                  },
                                  child: Text(l10n.forgotPassword),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: theme.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4C7A3F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _loading ? null : _onLogin,
                            child: _loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : Consumer<LanguageService>(
                                    builder: (context, languageService, child) {
                                      final l10n = AppLocalizations.of(context)!;
                                      return Text(
                                        l10n.login,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Consumer<LanguageService>(
                                builder: (context, languageService, child) {
                                  final l10n = AppLocalizations.of(context)!;
                                  return Text(l10n.or);
                                },
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.g_mobiledata),
                            label: Consumer<LanguageService>(
                              builder: (context, languageService, child) {
                                final l10n = AppLocalizations.of(context)!;
                                return Text(
                                  l10n.signInWithGoogle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                            onPressed: _loading ? null : _onGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.phone),
                            label: Consumer<LanguageService>(
                              builder: (context, languageService, child) {
                                final l10n = AppLocalizations.of(context)!;
                                return Text(
                                  l10n.signInWithPhone,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                            onPressed: _loading
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PhoneLoginPage(),
                                    ),
                                  ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (backupCodesEnabled)
                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.shield_outlined),
                              label: Text(
                                AppLocalizations.of(context)!.useBackupCode,
                              ),
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(BackupCodeLoginPage.routeName),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.dontHaveAccount),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.of(
                                      context,
                                    ).pushNamed(SignupPage.routeName),
                              child: Text(AppLocalizations.of(context)!.signup),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Language switcher button
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final isArabic =
                            languageService.currentLocale.languageCode == 'ar';
                        return InkWell(
                          onTap: () {
                            languageService.toggleLanguage();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isArabic ? '🇸🇦' : '🇺🇸',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isArabic ? 'العربية' : 'English',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Theme toggle button
                  IconButton(
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.light
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    onPressed: () {
                      locator<ThemeService>().toggleTheme();
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
