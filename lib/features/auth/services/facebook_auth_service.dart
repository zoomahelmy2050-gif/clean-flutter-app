import 'dart:developer' as developer;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';

class FacebookAuthService {
  static final FacebookAuthService _instance = FacebookAuthService._internal();
  factory FacebookAuthService() => _instance;
  FacebookAuthService._internal();

  /// Initialize Facebook SDK
  Future<void> initialize() async {
    try {
      // Facebook SDK is automatically initialized
      developer.log('Facebook Auth Service initialized', name: 'FacebookAuth');
    } catch (e) {
      developer.log('Failed to initialize Facebook Auth: $e', name: 'FacebookAuth');
    }
  }

  /// Sign in with Facebook
  Future<Map<String, dynamic>> signIn() async {
    try {
      developer.log('Starting Facebook Sign-In...', name: 'FacebookAuth');
      
      // Request Facebook login with email permission
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Get user data
        final userData = await FacebookAuth.instance.getUserData();
        
        final email = userData['email'] as String?;
        final name = userData['name'] as String?;
        final id = userData['id'] as String?;
        final picture = userData['picture']?['data']?['url'] as String?;

        if (email == null || email.isEmpty) {
          throw Exception('No email found in Facebook account');
        }

        developer.log('Facebook Sign-In success for: $email', name: 'FacebookAuth');
        
        return {
          'success': true,
          'email': email,
          'name': name,
          'id': id,
          'picture': picture,
          'accessToken': result.accessToken?.token,
        };
      } else if (result.status == LoginStatus.cancelled) {
        developer.log('Facebook Sign-In cancelled by user', name: 'FacebookAuth');
        return {
          'success': false,
          'error': 'Sign-in was cancelled',
          'cancelled': true,
        };
      } else {
        developer.log('Facebook Sign-In failed: ${result.message}', name: 'FacebookAuth');
        return {
          'success': false,
          'error': result.message ?? 'Facebook sign-in failed',
        };
      }
    } catch (e) {
      developer.log('Facebook Sign-In error: $e', name: 'FacebookAuth');
      return {
        'success': false,
        'error': 'Facebook sign-in failed: $e',
      };
    }
  }

  /// Sign out from Facebook
  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
      developer.log('Facebook Sign-Out successful', name: 'FacebookAuth');
    } catch (e) {
      developer.log('Facebook Sign-Out error: $e', name: 'FacebookAuth');
    }
  }

  /// Check if user is currently logged in to Facebook
  Future<bool> isLoggedIn() async {
    try {
      final AccessToken? accessToken = await FacebookAuth.instance.accessToken;
      return accessToken != null && !accessToken.isExpired;
    } catch (e) {
      developer.log('Error checking Facebook login status: $e', name: 'FacebookAuth');
      return false;
    }
  }

  /// Get current Facebook user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      if (await isLoggedIn()) {
        return await FacebookAuth.instance.getUserData();
      }
      return null;
    } catch (e) {
      developer.log('Error getting Facebook user data: $e', name: 'FacebookAuth');
      return null;
    }
  }

  /// Get Facebook access token
  Future<String?> getAccessToken() async {
    try {
      final AccessToken? accessToken = await FacebookAuth.instance.accessToken;
      return accessToken?.token;
    } catch (e) {
      developer.log('Error getting Facebook access token: $e', name: 'FacebookAuth');
      return null;
    }
  }
}
