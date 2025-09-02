import 'package:flutter/foundation.dart';
import 'api_service.dart';

class UserProfileService extends ChangeNotifier {
  final ApiService _apiService;
  UserProfile? _currentProfile;
  bool _isLoading = false;
  String? _error;

  UserProfileService(this._apiService);

  UserProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> loadUserProfile(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.get<Map<String, dynamic>>('/api/users/$userId/profile');
      
      if (response.isSuccess && response.data != null) {
        _currentProfile = UserProfile.fromJson(response.data!);
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to load profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/api/users/${_currentProfile?.id}/profile',
        body: profileData,
      );
      
      if (response.isSuccess && response.data != null) {
        _currentProfile = UserProfile.fromJson(response.data!);
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to update profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadProfileImage(String imagePath) async {
    _setLoading(true);
    _error = null;

    try {
      // For now, simulate upload - in real implementation, use multipart upload
      await Future.delayed(const Duration(seconds: 2));
      
      final response = await _apiService.put<Map<String, dynamic>>(
        '/api/users/${_currentProfile?.id}/profile-image',
        body: {'imagePath': imagePath},
      );
      
      if (response.isSuccess && response.data != null) {
        _currentProfile = UserProfile.fromJson(response.data!);
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to upload image';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Upload error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.delete('/api/users/${_currentProfile?.id}');
      
      if (response.isSuccess) {
        _currentProfile = null;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to delete account';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
