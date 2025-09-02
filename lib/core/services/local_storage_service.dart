import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for development - replaces backend during app development
class LocalStorageService {
  static const String _usersKey = 'local_users';
  static const String _currentUserKey = 'current_user';
  static const String _userDataPrefix = 'user_data_';
  
  /// Register user locally
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing users
      final usersJson = prefs.getString(_usersKey) ?? '{}';
      final users = Map<String, dynamic>.from(jsonDecode(usersJson));
      
      // Check if user already exists
      if (users.containsKey(email)) {
        return {'error': 'User already exists'};
      }
      
      // Add new user (in production, password would be properly hashed)
      users[email] = {
        'email': email,
        'password': password, // For development only - never store plain passwords in production!
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Save users
      await prefs.setString(_usersKey, jsonEncode(users));
      
      return {'success': true, 'message': 'User registered successfully'};
    } catch (e) {
      return {'error': 'Registration failed: $e'};
    }
  }
  
  /// Login user locally
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing users
      final usersJson = prefs.getString(_usersKey) ?? '{}';
      final users = Map<String, dynamic>.from(jsonDecode(usersJson));
      
      // Check if user exists and password matches
      if (!users.containsKey(email)) {
        return {'error': 'User not found'};
      }
      
      final user = users[email];
      if (user['password'] != password) {
        return {'error': 'Invalid password'};
      }
      
      // Set current user
      await prefs.setString(_currentUserKey, email);
      
      return {
        'success': true,
        'access_token': 'local_token_$email', // Mock token for development
        'user': user,
      };
    } catch (e) {
      return {'error': 'Login failed: $e'};
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey) != null;
  }
  
  /// Get current user email
  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }
  
  /// Store user data (like TOTP secrets, settings, etc.)
  Future<bool> storeUserData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = await getCurrentUser();
      
      if (currentUser == null) {
        return false;
      }
      
      final userDataKey = '$_userDataPrefix${currentUser}_$key';
      await prefs.setString(userDataKey, jsonEncode(data));
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Retrieve user data
  Future<Map<String, dynamic>?> getUserData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = await getCurrentUser();
      
      if (currentUser == null) {
        return null;
      }
      
      final userDataKey = '$_userDataPrefix${currentUser}_$key';
      final dataJson = prefs.getString(userDataKey);
      
      if (dataJson == null) {
        return null;
      }
      
      return Map<String, dynamic>.from(jsonDecode(dataJson));
    } catch (e) {
      return null;
    }
  }
  
  /// Store simple text data
  Future<bool> storeText(String key, String text) async {
    return await storeUserData(key, {'text': text, 'timestamp': DateTime.now().toIso8601String()});
  }
  
  /// Retrieve simple text data
  Future<String?> getText(String key) async {
    final data = await getUserData(key);
    return data?['text'];
  }
  
  /// Health check (always returns true for local storage)
  Future<bool> healthCheck() async {
    return true;
  }
  
  /// Get all users (for development/debugging)
  Future<List<String>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(jsonDecode(usersJson));
    return users.keys.toList();
  }
  
  /// Clear all local data (for development/testing)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
