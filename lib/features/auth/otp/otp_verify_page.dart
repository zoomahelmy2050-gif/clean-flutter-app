import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import '../services/email_otp_service.dart';
import '../../home/home_page.dart';
import 'package:clean_flutter/locator.dart';
import '../services/auth_service.dart';
import '../../admin/services/logging_service.dart';
import '../../admin/security_center_page.dart';
import '../security_setup_page.dart';
import 'package:clean_flutter/generated/app_localizations.dart';
import '../../../core/services/language_service.dart';

class OtpVerifyPage extends StatefulWidget {
  const OtpVerifyPage({super.key, required this.email, this.toAdmin = false});
  static const routeName = '/otp-verify';
  final String email;
  final bool toAdmin;

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> with SingleTickerProviderStateMixin {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _resending = false;
  late final String _securityKey;
  int _cooldown = 0;
  Timer? _timer;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _securityKey = locator<AuthService>().getSecurityKey(widget.email);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<EmailOtpService>();
      _cooldown = s.getResendRemainingSeconds(widget.email);
      if (_cooldown > 0) {
        _startTimer();
      }
      setState(() {});
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _cooldown = _cooldown > 0 ? _cooldown - 1 : 0;
        if (_cooldown == 0) t.cancel();
      });
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final ok = context.read<EmailOtpService>().verifyOtp(widget.email, _pinController.text);
      if (!mounted) return;
      if (ok) {
        await locator<LoggingService>().logSuccessfulLogin(widget.email);
        await locator<LoggingService>().logMfaOtp(widget.email);
        const adminEmail = 'env.hygiene@gmail.com';
        final emailLower = widget.email.toLowerCase();
        final authService = locator<AuthService>();
        
        if (authService.needsSecuritySetup(widget.email) && emailLower != adminEmail) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => SecuritySetupPage(email: widget.email)),
            (route) => false,
          );
        } else if (emailLower == adminEmail) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SecurityCenterPage()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage(initialTab: 3)),
            (route) => false,
          );
        }
      } else {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invalidOrExpiredCode)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await context.read<EmailOtpService>().sendOtp(widget.email);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.otpResentTo.replaceAll('{email}', widget.email))),
      );
      _cooldown = context.read<EmailOtpService>().getResendRemainingSeconds(widget.email);
      if (_cooldown > 0) _startTimer();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToResend.replaceAll('{error}', e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: theme.textTheme.headlineSmall,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_open_outlined, size: 64, color: theme.primaryColor),
                    const SizedBox(height: 16),
                    Consumer<LanguageService>(
                      builder: (context, languageService, child) {
                        final l10n = AppLocalizations.of(context)!;
                        return Column(
                          children: [
                            Text(
                              l10n.verification,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.enterCodeSentTo.replaceAll('{email}', widget.email),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Pinput(
                      length: 6,
                      controller: _pinController,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: theme.primaryColor, width: 2),
                        ),
                      ),
                      submittedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          color: const Color(0xFFE8F5E9),
                        ),
                      ),
                      validator: (s) {
                        final l10n = AppLocalizations.of(context)!;
                        return s == null || s.length != 6 ? l10n.enterSixDigitCode : null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Consumer<LanguageService>(
                            builder: (context, languageService, child) {
                              final l10n = AppLocalizations.of(context)!;
                              return Column(
                                children: [
                                  Text(l10n.securityKey, style: theme.textTheme.titleMedium?.copyWith(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    _securityKey,
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.ensureKeyMatches,
                                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C7A3F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: _loading ? null : _verify,
                        child: _loading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                            : Consumer<LanguageService>(
                                builder: (context, languageService, child) {
                                  final l10n = AppLocalizations.of(context)!;
                                  return Text(l10n.verify, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: (_resending || _cooldown > 0) ? null : _resend,
                      child: Consumer<LanguageService>(
                        builder: (context, languageService, child) {
                          final l10n = AppLocalizations.of(context)!;
                          return _resending
                              ? Text(l10n.resending)
                              : Text(_cooldown > 0 ? l10n.resendIn.replaceAll('{seconds}', _cooldown.toString()) : l10n.resendCode);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
