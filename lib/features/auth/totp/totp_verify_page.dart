import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../../core/widgets/fade_slide_transition.dart';
import '../../../locator.dart';
import '../../admin/security_center_page.dart';
import '../security_account_center_page.dart';
import '../services/auth_service.dart';
import '../services/totp_service.dart';
import '../../admin/services/logging_service.dart';
import '../security_setup_page.dart';

class TotpVerifyPage extends StatefulWidget {
  final String email;
  const TotpVerifyPage({super.key, required this.email});

  static const routeName = '/totp-verify';

  @override
  State<TotpVerifyPage> createState() => _TotpVerifyPageState();
}

class _TotpVerifyPageState extends State<TotpVerifyPage> with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _verifying = false;

  late final Animation<double> _animation;
  late final AnimationController _animationController;

  static const String _adminEmail = 'env.hygiene@gmail.com';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _verifying = true);
    final auth = locator<AuthService>();
    final secret = auth.getUserTotpSecret(widget.email);
    if (secret == null || secret.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TOTP not enrolled for this account.')));
        setState(() => _verifying = false);
      }
      return;
    }
    final totp = TotpService();
    final ok = totp.verifyCode(secret, _codeController.text);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or expired code. Try again.')));
        _formKey.currentState?.reset();
        _codeController.clear();
        setState(() => _verifying = false);
      }
      return;
    }
    // Success: log and navigate
    await locator<LoggingService>().logMfaTotp(widget.email);
    await locator<LoggingService>().logSuccessfulLogin(widget.email);
    await locator<AuthService>().setCurrentUser(widget.email);
    if (!mounted) return;
    final authService = locator<AuthService>();
    
    if (authService.needsSecuritySetup(widget.email) && widget.email.toLowerCase() != _adminEmail) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SecuritySetupPage(email: widget.email)),
        (route) => false,
      );
    } else if (widget.email.toLowerCase() == _adminEmail) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SecurityCenterPage()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => UserSecurityAccountCenterPage(email: widget.email)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = const Color(0xFF4C7A3F);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FadeSlideTransition(
                      animation: AlwaysStoppedAnimation(1),
                      additionalOffset: 0,
                      child: Icon(Icons.phonelink_lock, size: 64, color: Color(0xFF4C7A3F)),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideTransition(
                      animation: _animation,
                      additionalOffset: 16,
                      child: Text(
                        'Enter Authenticator Code',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideTransition(
                      animation: _animation,
                      additionalOffset: 32,
                      child: Text(
                        'Enter the 6-digit code from your authenticator app.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeSlideTransition(
                      animation: _animation,
                      additionalOffset: 48,
                      child: Pinput(
                        controller: _codeController,
                        length: 6,
                        autofocus: true,
                        pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                        validator: (s) => (s?.length ?? 0) < 6 ? 'Enter the 6-digit code' : null,
                        onCompleted: (_) => _verify(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideTransition(
                      animation: _animation,
                      additionalOffset: 64,
                      child: FilledButton(
                        onPressed: _verifying ? null : _verify,
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _verifying
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Verify & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
