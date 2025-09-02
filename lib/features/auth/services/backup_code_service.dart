import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupCodeService {
  static const _backupCodesKey = 'backup_codes_hashed';

  // Generates a single human-readable code in the format XXXX-XXXX
  String _generateSingleCode() {
    const chars = 'ABCDEFGHIJKLMNPQRSTUVWXYZ123456789';
    final rnd = Random();
    final part1 = String.fromCharCodes(Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    final part2 = String.fromCharCodes(Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return '$part1-$part2';
  }

  // Hashes a code using SHA256
  String _hash(String code) {
    final bytes = utf8.encode(code.toUpperCase()); // Store in a consistent case
    return sha256.convert(bytes).toString();
  }

  /// Generates 12 new codes, stores their hashes, and returns the plain codes.
  Future<List<String>> generateNewCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final plainCodes = List.generate(12, (_) => _generateSingleCode());
    final hashedCodes = plainCodes.map(_hash).toList();
    await prefs.setStringList(_backupCodesKey, hashedCodes);
    return plainCodes;
  }

  /// Validates a user-provided code. If valid, it's removed and can't be reused.
  Future<bool> validateAndUseCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final hashedCodes = prefs.getStringList(_backupCodesKey) ?? [];
    if (hashedCodes.isEmpty) return false;

    final hashedInput = _hash(code);
    if (hashedCodes.contains(hashedInput)) {
      // Code is valid, now remove it to prevent reuse
      final updatedCodes = hashedCodes.where((h) => h != hashedInput).toList();
      await prefs.setStringList(_backupCodesKey, updatedCodes);
      return true;
    }
    return false;
  }

  /// Returns the number of unused (stored) backup codes.
  Future<int> getUnusedCount() async {
    final prefs = await SharedPreferences.getInstance();
    final hashedCodes = prefs.getStringList(_backupCodesKey) ?? [];
    return hashedCodes.length;
  }

  /// Clears all stored backup codes (useful before regenerating in some flows).
  Future<void> clearCodes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backupCodesKey);
  }

  /// Checks if the user has generated backup codes.
  Future<bool> areBackupCodesActivated() async {
    final prefs = await SharedPreferences.getInstance();
    final codes = prefs.getStringList(_backupCodesKey) ?? [];
    return codes.isNotEmpty;
  }
}
