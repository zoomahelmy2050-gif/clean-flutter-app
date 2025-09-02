import 'package:flutter/material.dart';
import 'dart:async';
import 'package:clean_flutter/features/auth/services/auth_service.dart';
import 'package:clean_flutter/locator.dart';
import 'package:provider/provider.dart';
import 'package:clean_flutter/features/auth/services/email_otp_service.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordPage({super.key, required this.email, required this.otp});
  static const routeName = '/reset-password';

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _securityKey;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  int _cooldown = 0;
  bool _resending = false;
  Timer? _timer;
  double _strength = 0.0;
  String _strengthLabel = 'Weak';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<EmailOtpService>();
      _cooldown = s.getResendRemainingSeconds(widget.email);
      if (_cooldown > 0) _startTimer();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
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

  Future<void> _resendOtp() async {
    setState(() => _resending = true);
    try {
      await context.read<EmailOtpService>().sendOtp(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP re-sent to ${widget.email}')));
      _cooldown = context.read<EmailOtpService>().getResendRemainingSeconds(widget.email);
      if (_cooldown > 0) _startTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to resend: $e')));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _calculateStrength(String v) {
    // Simple strength heuristic
    int score = 0;
    if (v.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[a-z]').hasMatch(v)) score++;
    if (RegExp(r'\d').hasMatch(v)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(v)) score++;
    _strength = (score / 5).clamp(0, 1).toDouble();
    if (_strength < 0.34) {
      _strengthLabel = 'Weak';
    } else if (_strength < 0.67) {
      _strengthLabel = 'Medium';
    } else {
      _strengthLabel = 'Strong';
    }
    setState(() {});
  }

  void _onResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final enteredOtp = _otpController.text.trim();
    // Verify OTP using the EmailOtpService (shared via Provider)
    final emailOtp = context.read<EmailOtpService>();
    final otpOk = emailOtp.verifyOtp(widget.email, enteredOtp);

    if (otpOk) {
      // Update this specific user's password (hashed) and persist
      final newPassword = _passwordController.text.trim();
      final ok = await locator<AuthService>().updateUserPassword(widget.email, newPassword);

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password has been reset successfully!')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account not found for this email.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or expired OTP. Please try again.')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Load and memoize the security key for display
    _securityKey ??= locator<AuthService>().getSecurityKey(widget.email);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final cardWidth = maxWidth > 600 ? 500.0 : double.infinity;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardWidth),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(Icons.vpn_key_outlined, color: theme.colorScheme.onPrimaryContainer),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Enter New Password', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text('An OTP has been sent to ${widget.email}. Enter it below, then set a new password.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 12),
                            if (_securityKey != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text('Security Key', style: theme.textTheme.labelLarge),
                                    const SizedBox(height: 4),
                                    SelectableText(_securityKey!, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                                    const SizedBox(height: 4),
                                    Text('Ensure this key matches the one in your email to avoid phishing.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _otpController,
                                    decoration: const InputDecoration(
                                      labelText: 'OTP Code',
                                      prefixIcon: Icon(Icons.pin),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v == null || v.isEmpty ? 'Please enter the OTP' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: (_resending || _cooldown > 0) ? null : _resendOtp,
                                  child: _resending
                                      ? const Text('Resending...')
                                      : Text(_cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                helperText: 'Use 8+ chars with letters, numbers and symbols',
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                ),
                              ),
                              obscureText: _obscureNew,
                              onChanged: _calculateStrength,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter a new password';
                                if (v.length < 8) return 'Password must be at least 8 characters';
                                final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
                                final hasLower = RegExp(r'[a-z]').hasMatch(v);
                                final hasNum = RegExp(r'\d').hasMatch(v);
                                if (!(hasUpper && hasLower && hasNum)) return 'Add upper, lower and a number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: _strength,
                                      minHeight: 8,
                                      backgroundColor: theme.colorScheme.surfaceVariant,
                                      color: _strength < 0.34
                                          ? Colors.red
                                          : (_strength < 0.67 ? Colors.orange : Colors.green),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(_strengthLabel, style: theme.textTheme.labelLarge),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              obscureText: _obscureConfirm,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please confirm your password';
                                if (v != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _isLoading ? null : _onResetPassword,
                              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }
}
