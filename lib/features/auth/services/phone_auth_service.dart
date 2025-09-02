import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;
  
  PhoneAuthService() {
    developer.log('PhoneAuthService initialized with Firebase', name: 'PhoneAuthService');
  }
  
  // Send OTP to phone number using Firebase
  Future<bool> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function? onAutoVerify,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification
          if (onAutoVerify != null) {
            onAutoVerify();
          }
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = 'SMS quota exceeded';
          }
          onError(errorMessage);
          developer.log('Phone verification failed: ${e.code} - ${e.message}', 
              name: 'PhoneAuthService', error: e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          developer.log('Code sent. Verification ID: $verificationId', name: 'PhoneAuthService');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
      );
      return true;
    } catch (e) {
      onError('Failed to send OTP: $e');
      developer.log('Error sending OTP', name: 'PhoneAuthService', error: e);
      return false;
    }
  }
  
  // Verify OTP using Firebase
  Future<Map<String, dynamic>?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        return {
          'success': true,
          'user': {
            'uid': userCredential.user!.uid,
            'phoneNumber': userCredential.user!.phoneNumber,
          }
        };
      }
      return {'success': false, 'error': 'Failed to verify OTP'};
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Invalid verification code';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid verification code';
      } else if (e.code == 'invalid-verification-id') {
        errorMessage = 'Verification session expired. Please request a new code';
      }
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Verification failed: $e'};
    }
  }
  
  // Sign in with phone credential
  Future<Map<String, dynamic>?> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        return {
          'success': true,
          'user': {
            'uid': userCredential.user!.uid,
            'phoneNumber': userCredential.user!.phoneNumber,
            'emailVerified': userCredential.user!.emailVerified,
            'metadata': {
              'creationTime': userCredential.user!.metadata.creationTime?.toIso8601String(),
              'lastSignInTime': userCredential.user!.metadata.lastSignInTime?.toIso8601String(),
            }
          }
        };
      }
      return {'success': false, 'error': 'Sign in failed'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': 'Sign in failed: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Sign in failed: $e'};
    }
  }
  
  // Link phone to existing account
  Future<Map<String, dynamic>?> linkPhoneToAccount({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'No user signed in'};
      }
      
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await currentUser.linkWithCredential(credential);
      
      if (userCredential.user != null) {
        return {
          'success': true,
          'user': {
            'uid': userCredential.user!.uid,
            'phoneNumber': userCredential.user!.phoneNumber,
            'email': userCredential.user!.email,
          }
        };
      }
      return {'success': false, 'error': 'Failed to link phone number'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        return {'success': false, 'error': 'This phone number is already linked to another account'};
      }
      return {'success': false, 'error': 'Link failed: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'Link failed: $e'};
    }
  }
  
  // Resend OTP - mock implementation
  Future<bool> resendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    return await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }
  
  // Format phone number (add country code if missing)
  String formatPhoneNumber(String phoneNumber, {String countryCode = '+1'}) {
    String formatted = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (!formatted.startsWith('+')) {
      if (formatted.startsWith('0')) {
        formatted = formatted.substring(1);
      }
      formatted = countryCode + formatted;
    }
    
    return formatted;
  }
  
  // Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    final RegExp phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(phoneNumber);
  }
  
  // Sign out
  Future<void> signOut() async {
    _verificationId = null;
    _resendToken = null;
    await _auth.signOut();
    developer.log('User signed out', name: 'PhoneAuthService');
  }
  
  // Get current user
  Map<String, dynamic>? get currentUser {
    final user = _auth.currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'phoneNumber': user.phoneNumber,
        'email': user.email,
        'emailVerified': user.emailVerified,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
      };
    }
    return null;
  }
  
  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Check if phone number is already registered
  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      // Try to fetch sign-in methods for the phone number
      // Note: This is limited in Firebase for privacy reasons
      // You might need to implement this check on your backend
      return false; // Conservative default
    } catch (e) {
      developer.log('Error checking phone registration', name: 'PhoneAuthService', error: e);
      return false;
    }
  }
}
