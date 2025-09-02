import 'package:flutter/material.dart';

enum PasswordStrength {
  weak,
  fair,
  good,
  strong,
  veryStrong,
}

class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  final bool showLabel;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.showLabel = true,
  });

  PasswordStrength _calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;

    // Length check
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1; // lowercase
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1; // uppercase
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1; // numbers
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1; // special chars

    // Bonus points for very long passwords
    if (password.length >= 20) score += 1;

    // Penalty for common patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) score -= 1; // repeated chars
    if (RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde|def)').hasMatch(password.toLowerCase())) {
      score -= 1; // sequential chars
    }

    // Map score to strength
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.fair;
    if (score <= 6) return PasswordStrength.good;
    if (score <= 7) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.yellow[700]!;
      case PasswordStrength.strong:
        return Colors.lightGreen;
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }

  String _getStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  double _getStrengthValue(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.2;
      case PasswordStrength.fair:
        return 0.4;
      case PasswordStrength.good:
        return 0.6;
      case PasswordStrength.strong:
        return 0.8;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }

  List<String> _getPasswordTips(String password) {
    final tips = <String>[];
    
    if (password.length < 8) {
      tips.add('Use at least 8 characters');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      tips.add('Add lowercase letters');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      tips.add('Add uppercase letters');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      tips.add('Add numbers');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      tips.add('Add special characters');
    }
    if (password.length < 12) {
      tips.add('Consider using 12+ characters');
    }
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      tips.add('Avoid repeated characters');
    }

    return tips;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = _calculateStrength(password);
    final color = _getStrengthColor(strength);
    final label = _getStrengthLabel(strength);
    final value = _getStrengthValue(strength);
    final tips = _getPasswordTips(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        if (tips.isNotEmpty && strength != PasswordStrength.veryStrong) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 14, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Password Tips:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(left: 18, top: 2),
                  child: Text(
                    '• $tip',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[600],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PasswordStrengthService {
  static PasswordStrength calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;

    // Length scoring
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;

    // Character variety
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1;

    // Bonus for very long passwords
    if (password.length >= 20) score += 1;

    // Penalties
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) score -= 1;
    if (RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde|def)').hasMatch(password.toLowerCase())) {
      score -= 1;
    }

    // Common passwords check (basic)
    final commonPasswords = ['password', '123456', 'qwerty', 'admin', 'letmein'];
    if (commonPasswords.contains(password.toLowerCase())) {
      score -= 2;
    }

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.fair;
    if (score <= 6) return PasswordStrength.good;
    if (score <= 7) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  static bool isPasswordStrong(String password) {
    final strength = calculateStrength(password);
    return strength == PasswordStrength.strong || strength == PasswordStrength.veryStrong;
  }

  static List<String> getPasswordRequirements() {
    return [
      'At least 8 characters long',
      'Contains lowercase letters (a-z)',
      'Contains uppercase letters (A-Z)',
      'Contains numbers (0-9)',
      'Contains special characters (!@#\$%^&*)',
      'Avoid common passwords',
      'Avoid repeated characters',
    ];
  }
}
