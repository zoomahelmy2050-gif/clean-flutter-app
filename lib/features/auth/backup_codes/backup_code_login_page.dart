import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/backup_code_service.dart';
import '../../home/home_page.dart';
import 'dart:math' as math;
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';

class BackupCodeLoginPage extends StatefulWidget {
  const BackupCodeLoginPage({super.key});
  static const routeName = '/login-backup-code';

  @override
  State<BackupCodeLoginPage> createState() => _BackupCodeLoginPageState();
}

class _BackupCodeLoginPageState extends State<BackupCodeLoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _backupCodeService = BackupCodeService();
  bool _isLoading = false;
  int _remaining = 0;
  bool _credentialsVerified = false;

  // Segmented 8-character input (grouped 4-4)
  static const int _codeLength = 8;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  // Shake animation for invalid code
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _loadRemaining();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _loadRemaining() async {
    final rem = await _backupCodeService.getUnusedCount();
    if (!mounted) return;
    setState(() => _remaining = rem);
  }

  String _collectCode() {
    final raw = _controllers.map((c) => c.text.toUpperCase()).join();
    if (raw.length < _codeLength) return '';
    return raw.substring(0, 4) + '-' + raw.substring(4, 8);
  }

  bool get _isComplete => _controllers.every((c) => c.text.isNotEmpty);

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_credentialsVerified) {
      return;
    }
    if (!_isComplete) return;

    setState(() => _isLoading = true);

    final isValid = await _backupCodeService.validateAndUseCode(_collectCode());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isValid) {
      await _loadRemaining();
      Navigator.of(context).pushNamedAndRemoveUntil(HomePage.routeName, (route) => false);
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid backup code. Please try again.')),
      );
    }
  }

  Future<void> _verifyCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() => _isLoading = true);
    final auth = locator<AuthService>();
    final loginResult = await auth.login(email, password);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (loginResult['success'] == true) {
      setState(() => _credentialsVerified = true);
      HapticFeedback.lightImpact();
      FocusScope.of(context).unfocus();
    } else {
      HapticFeedback.heavyImpact();
      final error = loginResult['error'] ?? 'Invalid email or password';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final raw = (data?.text ?? '').toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (raw.isEmpty) return;
    for (var i = 0; i < _codeLength; i++) {
      _controllers[i].text = i < raw.length ? raw[i] : '';
    }
    // Move focus to end
    final firstEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
    final idx = firstEmpty == -1 ? _codeLength - 1 : firstEmpty;
    _focusNodes[idx].requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Use Backup Code'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final t = _shakeController.value;
                final dx = math.sin(t * math.pi * 8) * 10 * (1 - t);
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Card(
                    color: theme.colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.security_rounded, color: theme.colorScheme.onTertiaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Enter one of your single-use backup codes. Codes are 8 characters long.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Please enter your email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Please enter your password' : null,
                    enabled: !_credentialsVerified,
                  ),
                  const SizedBox(height: 16),
                  if (_credentialsVerified) ...[
                    _SegmentedCodeInput(
                      controllers: _controllers,
                      focusNodes: _focusNodes,
                      onPasteRequested: _pasteFromClipboard,
                      onAllFilled: () async {
                        if (!_credentialsVerified) return;
                        HapticFeedback.lightImpact();
                        if (_formKey.currentState!.validate() && !_isLoading) {
                          await _onLogin();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Format: XXXX-XXXX', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.confirmation_number_outlined, size: 16),
                            const SizedBox(width: 6),
                            Text('Remaining: $_remaining', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 24),
                  if (!_credentialsVerified)
                    FilledButton(
                      onPressed: _isLoading ? null : _verifyCredentials,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Continue'),
                    )
                  else
                    FilledButton(
                      onPressed: _isLoading || !_isComplete ? null : _onLogin,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Verify and Login'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedCodeInput extends StatelessWidget {
  const _SegmentedCodeInput({
    required this.controllers,
    required this.focusNodes,
    required this.onPasteRequested,
    required this.onAllFilled,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final Future<void> Function() onPasteRequested;
  final Future<void> Function() onAllFilled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(controllers.length, (i) {
            final isSpacerAfter = (i == 3);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OneCharBox(
                  controller: controllers[i],
                  focusNode: focusNodes[i],
                  onChanged: (val) {
                    final upper = val.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
                    if (controllers[i].text != upper) {
                      controllers[i].text = upper;
                      controllers[i].selection = TextSelection.collapsed(offset: upper.length);
                    }
                    if (upper.isNotEmpty && i < controllers.length - 1) {
                      focusNodes[i + 1].requestFocus();
                    }
                    if (upper.isNotEmpty) {
                      HapticFeedback.lightImpact();
                    }
                    // Auto-submit if all filled
                    if (controllers.every((c) => c.text.isNotEmpty)) {
                      onAllFilled();
                    }
                  },
                  onBackspaceOnEmpty: () {
                    if (i > 0) focusNodes[i - 1].requestFocus();
                  },
                ),
                if (isSpacerAfter) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('-', style: theme.textTheme.titleMedium),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onPasteRequested,
            icon: const Icon(Icons.paste),
            label: const Text('Paste'),
          ),
        ),
      ],
    );
  }
}

class _OneCharBox extends StatefulWidget {
  const _OneCharBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspaceOnEmpty,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceOnEmpty;

  @override
  State<_OneCharBox> createState() => _OneCharBoxState();
}

class _OneCharBoxState extends State<_OneCharBox> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.backspace): const BackspaceIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            BackspaceIntent: CallbackAction<BackspaceIntent>(
              onInvoke: (intent) {
                if (widget.controller.text.isEmpty) {
                  widget.onBackspaceOnEmpty();
                }
                return null;
              },
            ),
          },
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            textAlign: TextAlign.center,
            maxLength: 1,
            decoration: const InputDecoration(
              counterText: '',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              UpperCaseTextFormatter(),
            ],
            onChanged: widget.onChanged,
            keyboardType: TextInputType.visiblePassword,
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class BackspaceIntent extends Intent {
  const BackspaceIntent();
}
