import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RealPhoneAuthService {
  static const String _verifyBaseUrl = 'https://verify.twilio.com/v2';
  
  late String _accountSid;
  late String _authToken;
  late String _verifyServiceSid;
  
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    // Load Twilio credentials from environment or secure storage
    final prefs = await SharedPreferences.getInstance();
    _accountSid = prefs.getString('twilio_account_sid') ?? '';
    _authToken = prefs.getString('twilio_auth_token') ?? '';
    _verifyServiceSid = prefs.getString('twilio_verify_service_sid') ?? '';
    
    if (_accountSid.isEmpty || _authToken.isEmpty || _verifyServiceSid.isEmpty) {
      developer.log('Twilio credentials not configured', name: 'RealPhoneAuthService');
      return;
    }
    
    _isInitialized = true;
    developer.log('Twilio phone auth service initialized', name: 'RealPhoneAuthService');
  }

  String get _basicAuth {
    final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
    return 'Basic $credentials';
  }

  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    if (!_isInitialized) {
      return {'success': false, 'error': 'Service not initialized'};
    }

    try {
      // Format phone number to E.164 format
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      final response = await http.post(
        Uri.parse('$_verifyBaseUrl/Services/$_verifyServiceSid/Verifications'),
        headers: {
          'Authorization': _basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': formattedPhone,
          'Channel': 'sms',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        developer.log('OTP sent successfully to $formattedPhone', name: 'RealPhoneAuthService');
        return {
          'success': true,
          'sid': data['sid'],
          'status': data['status'],
          'message': 'OTP sent successfully'
        };
      } else {
        developer.log('Failed to send OTP: ${data['message']}', name: 'RealPhoneAuthService');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to send OTP'
        };
      }
    } catch (e) {
      developer.log('Error sending OTP: $e', name: 'RealPhoneAuthService');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otp) async {
    if (!_isInitialized) {
      return {'success': false, 'error': 'Service not initialized'};
    }

    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      final response = await http.post(
        Uri.parse('$_verifyBaseUrl/Services/$_verifyServiceSid/VerificationCheck'),
        headers: {
          'Authorization': _basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': formattedPhone,
          'Code': otp,
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final isValid = data['status'] == 'approved';
        developer.log('OTP verification result: $isValid', name: 'RealPhoneAuthService');
        
        return {
          'success': true,
          'verified': isValid,
          'status': data['status'],
        };
      } else {
        developer.log('Failed to verify OTP: ${data['message']}', name: 'RealPhoneAuthService');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to verify OTP'
        };
      }
    } catch (e) {
      developer.log('Error verifying OTP: $e', name: 'RealPhoneAuthService');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> sendVoiceOTP(String phoneNumber) async {
    if (!_isInitialized) {
      return {'success': false, 'error': 'Service not initialized'};
    }

    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      final response = await http.post(
        Uri.parse('$_verifyBaseUrl/Services/$_verifyServiceSid/Verifications'),
        headers: {
          'Authorization': _basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': formattedPhone,
          'Channel': 'call',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        developer.log('Voice OTP sent successfully to $formattedPhone', name: 'RealPhoneAuthService');
        return {
          'success': true,
          'sid': data['sid'],
          'status': data['status'],
          'message': 'Voice OTP sent successfully'
        };
      } else {
        developer.log('Failed to send voice OTP: ${data['message']}', name: 'RealPhoneAuthService');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to send voice OTP'
        };
      }
    } catch (e) {
      developer.log('Error sending voice OTP: $e', name: 'RealPhoneAuthService');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getVerificationStatus(String phoneNumber) async {
    if (!_isInitialized) {
      return {'success': false, 'error': 'Service not initialized'};
    }

    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      final response = await http.get(
        Uri.parse('$_verifyBaseUrl/Services/$_verifyServiceSid/Verifications/$formattedPhone'),
        headers: {
          'Authorization': _basicAuth,
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'status': data['status'],
          'dateCreated': data['date_created'],
          'dateUpdated': data['date_updated'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to get verification status'
        };
      }
    } catch (e) {
      developer.log('Error getting verification status: $e', name: 'RealPhoneAuthService');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add country code if not present (assuming US/Canada +1)
    if (cleaned.length == 10) {
      cleaned = '1$cleaned';
    }
    
    // Add + prefix for E.164 format
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    
    return cleaned;
  }

  Future<void> setCredentials({
    required String accountSid,
    required String authToken,
    required String verifyServiceSid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('twilio_account_sid', accountSid);
    await prefs.setString('twilio_auth_token', authToken);
    await prefs.setString('twilio_verify_service_sid', verifyServiceSid);
    
    _accountSid = accountSid;
    _authToken = authToken;
    _verifyServiceSid = verifyServiceSid;
    _isInitialized = true;
    
    developer.log('Twilio credentials updated', name: 'RealPhoneAuthService');
  }

  bool get isConfigured => _isInitialized;
}
