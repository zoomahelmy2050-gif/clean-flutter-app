import 'dart:async';
import '../../features/auth/services/auth_service.dart';

class BackupCodesService {
  final AuthService _authService;

  BackupCodesService(this._authService);

  String? get _currentUserEmail => _authService.currentUser;

  Future<List<String>> generateBackupCodes() async {
    final email = _currentUserEmail;
    if (email == null) throw Exception('No user logged in');
    return await _authService.generateUserBackupCodes(email);
  }

  Future<bool> verifyBackupCode(String inputCode) async {
    final email = _currentUserEmail;
    if (email == null) throw Exception('No user logged in');
    return await _authService.verifyUserBackupCode(email, inputCode);
  }

  Future<bool> hasBackupCodes() async {
    final email = _currentUserEmail;
    if (email == null) return false;
    return _authService.hasUserBackupCodes(email);
  }

  Future<Map<String, dynamic>> getBackupCodesStatus() async {
    final email = _currentUserEmail;
    if (email == null) {
      return {
        'total': 0,
        'used': 0,
        'remaining': 0,
        'hasBackupCodes': false,
      };
    }
    return await _authService.getUserBackupCodesStatus(email);
  }

  Future<void> deleteBackupCodes() async {
    final email = _currentUserEmail;
    if (email == null) throw Exception('No user logged in');
    await _authService.deleteUserBackupCodes(email);
  }

  Future<List<String>> regenerateBackupCodes() async {
    final email = _currentUserEmail;
    if (email == null) throw Exception('No user logged in');
    await _authService.deleteUserBackupCodes(email);
    return await _authService.generateUserBackupCodes(email);
  }
}

