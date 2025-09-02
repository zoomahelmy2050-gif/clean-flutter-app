import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/widgets/fade_slide_transition.dart';
import '../../../locator.dart';
import '../services/auth_service.dart';
import '../services/totp_service.dart';
import 'totp_setup_verify_page.dart';

class TotpEnrollPage extends StatefulWidget {
  final String email;
  const TotpEnrollPage({super.key, required this.email});

  static const routeName = '/totp-enroll';

  @override
  State<TotpEnrollPage> createState() => _TotpEnrollPageState();
}

class _TotpEnrollPageState extends State<TotpEnrollPage> with SingleTickerProviderStateMixin {
  late final TotpService _totp;
  String? _secret;
  late final String _issuer;

  late final Animation<double> _animation;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _totp = TotpService();
    _issuer = 'CleanFlutter';
    final auth = locator<AuthService>();
    final existing = auth.getUserTotpSecret(widget.email);
    _secret = existing?.isNotEmpty == true ? existing : _totp.generateBase32Secret();

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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = locator<AuthService>();
    final secret = _secret!;
    final label = '$_issuer:${widget.email}';
    final uri = _totp.buildProvisioningUri(base32Secret: secret, label: label, issuer: _issuer);
    final color = const Color(0xFF4C7A3F);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FadeSlideTransition(
                    animation: AlwaysStoppedAnimation(1),
                    additionalOffset: 0,
                    child: Icon(Icons.qr_code_scanner, size: 64, color: Color(0xFF4C7A3F)),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideTransition(
                    animation: _animation,
                    additionalOffset: 16,
                    child: Text(
                      'Enroll TOTP',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideTransition(
                    animation: _animation,
                    additionalOffset: 32,
                    child: Text(
                      'Scan the QR code with your authenticator app to enable TOTP.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeSlideTransition(
                    animation: _animation,
                    additionalOffset: 48,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(data: uri, size: 220, gapless: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideTransition(
                    animation: _animation,
                    additionalOffset: 64,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              secret,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: secret));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Secret copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideTransition(
                    animation: _animation,
                    additionalOffset: 80,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Regenerate QR'),
                            onPressed: () {
                              setState(() {
                                _secret = _totp.generateBase32Secret();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('New QR code generated')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.keyboard),
                            label: const Text('Manual Entry'),
                            onPressed: () => _showManualEntryDialog(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideTransition(
                    animation: _animation,
                    additionalOffset: 96,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('I Have Scanned the QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        // Navigate to verification page instead of completing setup
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TotpSetupVerifyPage(
                              email: widget.email,
                              secret: secret,
                            ),
                          ),
                        );
                        
                        if (!mounted) return;
                        
                        // If verification was successful, return to security setup
                        if (result == 'verified') {
                          Navigator.of(context).pop('enrolled');
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Entry Instructions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('If you cannot scan the QR code, manually enter these details in your authenticator app:'),
            const SizedBox(height: 16),
            _buildManualEntryItem('Account name', '${widget.email}'),
            _buildManualEntryItem('Secret key', _secret!),
            _buildManualEntryItem('Type', 'Time-based'),
            _buildManualEntryItem('Algorithm', 'SHA1'),
            _buildManualEntryItem('Digits', '6'),
            _buildManualEntryItem('Period', '30 seconds'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _secret!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Secret key copied to clipboard')),
              );
            },
            child: const Text('Copy Secret'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
