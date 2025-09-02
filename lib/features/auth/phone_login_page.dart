import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Firebase auth removed - using standalone authentication
import 'package:clean_flutter/features/auth/services/phone_auth_service.dart';
import 'package:clean_flutter/features/auth/otp_verification_page.dart';
import 'package:clean_flutter/locator.dart';
import 'package:clean_flutter/features/auth/services/auth_service.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final PhoneAuthService _phoneAuthService = PhoneAuthService();
  final AuthService _authService = locator<AuthService>();
  
  bool _isLoading = false;
  String _selectedCountryCode = '+1';
  String? _errorMessage;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'country': 'US/CA', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+86', 'country': 'China', 'flag': '🇨🇳'},
    {'code': '+49', 'country': 'Germany', 'flag': '🇩🇪'},
    {'code': '+33', 'country': 'France', 'flag': '🇫🇷'},
    {'code': '+81', 'country': 'Japan', 'flag': '🇯🇵'},
    {'code': '+82', 'country': 'S.Korea', 'flag': '🇰🇷'},
    {'code': '+61', 'country': 'Australia', 'flag': '🇦🇺'},
    {'code': '+55', 'country': 'Brazil', 'flag': '🇧🇷'},
    {'code': '+20', 'country': 'Egypt', 'flag': '🇪🇬'},
    {'code': '+966', 'country': 'Saudi', 'flag': '🇸🇦'},
    {'code': '+971', 'country': 'UAE', 'flag': '🇦🇪'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
      });
      return;
    }

    final String fullPhoneNumber = _phoneAuthService.formatPhoneNumber(
      _phoneController.text.trim(),
      countryCode: _selectedCountryCode,
    );

    if (!_phoneAuthService.isValidPhoneNumber(fullPhoneNumber)) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _phoneAuthService.sendOTP(
      phoneNumber: fullPhoneNumber,
      onCodeSent: (verificationId) {
        setState(() {
          _isLoading = false;
        });
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              phoneNumber: fullPhoneNumber,
              verificationId: verificationId,
            ),
          ),
        );
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      },
      onAutoVerify: (credential) async {
        try {
          final result = await _phoneAuthService.signInWithCredential(credential);
          if (result != null && result['success'] == true && mounted) {
            final user = result['user'] as Map<String, dynamic>;
            // Register user in local auth service
            await _authService.register(user['phoneNumber'] as String, 'phone_auth');
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Auto-verification failed: $e';
          });
        }
      },
    );

    if (!success) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Sign In'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              
              // Header
              Icon(
                Icons.phone_android,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              
              Text(
                'Enter Your Phone Number',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                'We\'ll send you a verification code via SMS',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Phone number input
              Row(
                children: [
                  // Country code dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        items: _countryCodes.map((country) {
                          return DropdownMenuItem<String>(
                            value: country['code'],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(country['flag']!),
                                const SizedBox(width: 8),
                                Text(country['code']!),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCountryCode = value;
                              _errorMessage = null;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Phone number field
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                        errorText: _errorMessage,
                      ),
                      onChanged: (value) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                      onSubmitted: (_) => _sendOTP(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Send OTP button
              FilledButton(
                onPressed: _isLoading ? null : _sendOTP,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send OTP'),
              ),
              const SizedBox(height: 24),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Standard messaging rates may apply. We use Firebase Authentication for secure verification.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Back to other sign-in options
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Sign In Options'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
