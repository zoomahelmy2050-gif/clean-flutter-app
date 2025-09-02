import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../../core/widgets/fade_slide_transition.dart';
import '../../../locator.dart';
import '../services/auth_service.dart';
import '../services/totp_service.dart';
import '../../../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/core/services/language_service.dart';

class TotpSetupVerifyPage extends StatefulWidget {
  final String email;
  final String secret;
  
  const TotpSetupVerifyPage({
    super.key,
    required this.email,
    required this.secret,
  });

  static const routeName = '/totp-setup-verify';

  @override
  State<TotpSetupVerifyPage> createState() => _TotpSetupVerifyPageState();
}

class _TotpSetupVerifyPageState extends State<TotpSetupVerifyPage> with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _verifying = false;

  late final Animation<double> _animation;
  late final AnimationController _animationController;

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

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _verifying = true);
    
    try {
      final totp = TotpService();
      final isValid = totp.verifyCode(widget.secret, _codeController.text);
      
      if (!mounted) return;
      
      if (isValid) {
        // Save the TOTP secret to complete enrollment
        final auth = locator<AuthService>();
        await auth.setUserTotpSecret(widget.email, widget.secret);
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TOTP successfully set up!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return to security setup with success
        Navigator.of(context).pop('verified');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        _codeController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = const Color(0xFF4C7A3F);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Color.fromRGBO(30, 60, 87, 1),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(8),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: const Color.fromRGBO(234, 239, 243, 1),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.totpVerification);
          },
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
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
                      child: Icon(Icons.security, size: 64, color: Color(0xFF4C7A3F)),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideTransition(
                      animation: _animation,
                      additionalOffset: 16,
                      child: Text(
                        'Verify TOTP Code',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideTransition(
                      animation: _animation,
                      additionalOffset: 32,
                      child: Text(
                        'Enter the 6-digit code from your authenticator app to complete setup.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeSlideTransition(
                      animation: _animation,
                      additionalOffset: 48,
                      child: Pinput(
                        controller: _codeController,
                        length: 6,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the code';
                          }
                          if (value.length != 6) {
                            return 'Code must be 6 digits';
                          }
                          return null;
                        },
                        pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                        showCursor: true,
                        onCompleted: (pin) => _verifyCode(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeSlideTransition(
                      animation: _animation,
                      additionalOffset: 64,
                      child: FilledButton.icon(
                        icon: _verifying 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified_outlined),
                        label: Text(
                          _verifying ? 'Verifying...' : 'Verify Code',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _verifying ? null : _verifyCode,
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideTransition(
                      animation: _animation,
                      additionalOffset: 80,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Go Back to QR Code',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                          ),
                        ),
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
