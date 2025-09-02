import 'dart:math';
import 'package:crypto/crypto.dart';

/// Minimal TOTP (RFC 6238) helper without external deps.
/// - HMAC-SHA1, 30s period, 6 digits
class TotpService {
  static const int period = 30;
  static const int digits = 6;

  /// Generate a new random Base32 secret suitable for TOTP.
  String generateBase32Secret({int length = 20}) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final rnd = Random.secure();
    return List.generate(length, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
  }

  /// Build an otpauth provisioning URI for QR.
  /// label example: app:user@example.com, issuer example: CleanFlutter
  String buildProvisioningUri({required String base32Secret, required String label, required String issuer}) {
    final encLabel = Uri.encodeComponent(label);
    final encIssuer = Uri.encodeComponent(issuer);
    return 'otpauth://totp/$encLabel?secret=$base32Secret&issuer=$encIssuer&algorithm=SHA1&digits=$digits&period=$period';
  }

  /// Generate current TOTP code for the given secret
  String generateCode(String base32Secret) {
    final secret = _base32Decode(base32Secret);
    final time = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final counter = time ~/ period;
    return _generateOtp(secret, counter);
  }

  /// Get remaining seconds for current TOTP window
  int getRemainingSeconds() {
    final time = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return period - (time % period).toInt();
  }

  /// Verify a provided TOTP code for the secret allowing small time drift ([-1,0,1] windows)
  bool verifyCode(String base32Secret, String code, {int allowedDriftWindows = 1}) {
    final normalized = code.replaceAll(RegExp(r'\s+'), '');
    if (normalized.length < 6 || !RegExp(r'^\d{6}$').hasMatch(normalized)) return false;

    final secret = _base32Decode(base32Secret);
    final time = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final counter = time ~/ period;
    for (int i = -allowedDriftWindows; i <= allowedDriftWindows; i++) {
      final otp = _generateOtp(secret, counter + i);
      if (otp == normalized) return true;
    }
    return false;
  }

  // --- internals ---
  String _generateOtp(List<int> key, int counter) {
    final counterBytes = _int2bytes(counter);
    final hmacSha1 = Hmac(sha1, key);
    final hash = hmacSha1.convert(counterBytes).bytes;
    final offset = hash.last & 0x0f;
    final binary = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);
    final otp = binary % 1000000;
    return otp.toString().padLeft(digits, '0');
  }

  List<int> _int2bytes(int val) {
    final bytes = List<int>.filled(8, 0);
    for (int i = 7; i >= 0; i--) {
      bytes[i] = val & 0xff;
      val >>= 8;
    }
    return bytes;
  }

  // Basic Base32 decode (RFC 4648, uppercase only)
  List<int> _base32Decode(String input) {
    final cleaned = input.toUpperCase().replaceAll('=', '');
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    int buffer = 0;
    int bitsLeft = 0;
    final out = <int>[];
    for (final c in cleaned.codeUnits) {
      final idx = alphabet.codeUnits.indexOf(c);
      if (idx < 0) continue;
      buffer = (buffer << 5) | idx;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        out.add((buffer >> bitsLeft) & 0xff);
      }
    }
    return out;
  }
}
