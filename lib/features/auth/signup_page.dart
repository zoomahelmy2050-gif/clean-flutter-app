import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'otp/otp_verify_page.dart';
import 'services/email_otp_service.dart';
import 'package:clean_flutter/locator.dart';
import 'services/auth_service.dart';
import '../../core/services/enhanced_auth_service.dart';
import '../admin/services/logging_service.dart';
import '../../core/widgets/password_strength_meter.dart';
import '../../generated/app_localizations.dart';
import '../../core/services/language_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  static const routeName = '/signup';

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web client ID from your Firebase project
    serverClientId: '951850160974-frhtseulen7rp2hfceesr4onnop5t7mb.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSignup() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    _proceedWithSignup();
  }

  Future<void> _proceedWithSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final enhancedAuth = locator<EnhancedAuthService>();
    final auth = locator<AuthService>();
    
    // Check registration in enhanced auth service
    if (enhancedAuth.isEmailRegistered(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.emailAlreadyRegistered),
          ),
        );
        setState(() => _loading = false);
      }
      return;
    }

    // Register in enhanced auth service
    final registerResult = await enhancedAuth.register(email: email, password: password);
    final didRegister = registerResult['success'] == true;
    
    // Also register in legacy auth service for compatibility
    if (didRegister) {
      await auth.register(email, password);
    }
    if (!mounted) return;

    if (!didRegister) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.registrationFailed),
        ),
      );
      setState(() => _loading = false);
      return;
    }

    locator<LoggingService>().logSignUp(email);
    try {
      final emailOtpService = context.read<EmailOtpService>();
      if (!mounted) return;
      await emailOtpService.sendOtp(email);
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => OtpVerifyPage(email: email)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendOtpAndNavigate(String email) async {
    try {
      final emailOtpService = context.read<EmailOtpService>();
      if (!mounted) return;
      await emailOtpService.sendOtp(email);
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => OtpVerifyPage(email: email)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
    }
  }

  Future<void> _onGoogleSignIn() async {
    try {
      setState(() => _loading = true);
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Sign-in was cancelled');
      }
      if (!mounted) return;

      // Use standalone Google Sign-In (temporarily bypass Firebase Auth)
      final email = account.email;
      
      if (email.isEmpty) {
        throw Exception('No email found in Google account');
      }

      final enhancedAuth = locator<EnhancedAuthService>();
      final auth = locator<AuthService>();
      if (!enhancedAuth.isEmailRegistered(email)) {
        await enhancedAuth.register(email: email, password: 'google');
        await auth.register(email, 'google');
      }
      await locator<LoggingService>().logSignUp(email);

      await _sendOtpAndNavigate(email);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.googleSignupFailed}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final theme = Theme.of(context);
        final localizations = AppLocalizations.of(context)!;
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.createNewAccount,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.signupSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _buildInputDecoration(
                            localizations.fullName,
                            Icons.person_outline,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? localizations.nameValidation
                              : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDecoration(
                            localizations.email,
                            Icons.email_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return localizations.enterEmail;
                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(v)) {
                              return localizations.emailValidation;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              onChanged: (value) => setState(() {}),
                              decoration:
                                  _buildInputDecoration(
                                    localizations.password,
                                    Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return localizations.enterPassword;
                                if (!PasswordStrengthService.isPasswordStrong(
                                  v,
                                )) {
                                  return localizations.passwordValidation;
                                }
                                return null;
                              },
                            ),
                            PasswordStrengthMeter(
                              password: _passwordController.text,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _onSignup,
                            child: _loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(localizations.signup),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(localizations.or),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.g_mobiledata),
                            label: Text(localizations.signupWithGoogle),
                            onPressed: _loading ? null : _onGoogleSignIn,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(localizations.alreadyHaveAccount),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/login'),
                              child: Text(localizations.login),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData prefixIcon) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon, color: scheme.onSurfaceVariant),
      filled: true,
      fillColor:
          Theme.of(context).inputDecorationTheme.fillColor ??
          scheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    );
  }
}
