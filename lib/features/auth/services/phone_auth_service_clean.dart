// Custom phone authentication service - no Firebase dependencies
import 'dart:developer' as developer;

class PhoneAuthService {
  String? _verificationId;
  
  PhoneAuthService() {
    developer.log('PhoneAuthService initialized for custom backend', name: 'PhoneAuthService');
  }
  
  // Send OTP to phone number - mock implementation
  Future<bool> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function? onAutoVerify,
  }) async {
    try {
      // Mock verification ID
      _verificationId = 'mock_verification_${DateTime.now().millisecondsSinceEpoch}';
      onCodeSent(_verificationId!);
      return true;
    } catch (e) {
      onError('Failed to send OTP: $e');
      return false;
    }
  }
  
  // Verify OTP - mock implementation
  Future<Map<String, dynamic>?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      if (verificationId == _verificationId && smsCode == '123456') {
        return {
          'success': true,
          'user': {
            'uid': 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
            'phoneNumber': '+1234567890',
          }
        };
      }
      return {'success': false, 'error': 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'error': 'Verification failed: $e'};
    }
  }
  
  // Sign in with credential - mock implementation
  Future<Map<String, dynamic>?> signInWithCredential(Map<String, dynamic> credential) async {
    try {
      return {
        'success': true,
        'user': {
          'uid': 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
          'phoneNumber': credential['phoneNumber'] ?? '+1234567890',
        }
      };
    } catch (e) {
      return {'success': false, 'error': 'Sign in failed: $e'};
    }
  }
  
  // Link phone to account - mock implementation
  Future<Map<String, dynamic>?> linkPhoneToAccount({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      if (verificationId == _verificationId && smsCode == '123456') {
        return {
          'success': true,
          'user': {
            'uid': 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
            'phoneNumber': '+1234567890',
          }
        };
      }
      return {'success': false, 'error': 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'error': 'Link failed: $e'};
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _verificationId = null;
    developer.log('User signed out', name: 'PhoneAuthService');
  }
  
  // Get current user - mock implementation
  Map<String, dynamic>? get currentUser => null; // No persistent user in mock
}
