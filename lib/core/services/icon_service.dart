import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class IconService extends ChangeNotifier {
  static const String _customIconsKey = 'custom_icons';
  static const String _iconMappingsKey = 'icon_mappings';
  
  Map<String, String> _customIcons = {}; // itemId -> iconPath
  Map<String, IconData> _builtInIcons = {};
  
  Map<String, String> get customIcons => Map.unmodifiable(_customIcons);
  
  IconService() {
    _initializeBuiltInIcons();
    _loadCustomIcons();
  }

  /// Initialize built-in service icons
  void _initializeBuiltInIcons() {
    _builtInIcons = {
      'google': Icons.g_mobiledata,
      'microsoft': Icons.business,
      'apple': Icons.apple,
      'facebook': Icons.facebook,
      'twitter': Icons.alternate_email,
      'instagram': Icons.camera_alt,
      'linkedin': Icons.business,
      'github': Icons.code,
      'gitlab': Icons.code,
      'bitbucket': Icons.code,
      'amazon': Icons.shopping_cart,
      'aws': Icons.cloud,
      'azure': Icons.cloud,
      'dropbox': Icons.cloud_upload,
      'onedrive': Icons.cloud_upload,
      'icloud': Icons.cloud_upload,
      'gmail': Icons.email,
      'outlook': Icons.email,
      'yahoo': Icons.email,
      'discord': Icons.chat,
      'slack': Icons.chat,
      'teams': Icons.video_call,
      'zoom': Icons.video_call,
      'netflix': Icons.play_circle,
      'spotify': Icons.music_note,
      'youtube': Icons.play_arrow,
      'twitch': Icons.live_tv,
      'steam': Icons.games,
      'epic': Icons.games,
      'playstation': Icons.sports_esports,
      'xbox': Icons.sports_esports,
      'nintendo': Icons.sports_esports,
      'paypal': Icons.payment,
      'stripe': Icons.payment,
      'visa': Icons.credit_card,
      'mastercard': Icons.credit_card,
      'bank': Icons.account_balance,
      'coinbase': Icons.currency_bitcoin,
      'binance': Icons.currency_bitcoin,
      'reddit': Icons.forum,
      'pinterest': Icons.image,
      'snapchat': Icons.camera,
      'tiktok': Icons.video_library,
      'whatsapp': Icons.message,
      'telegram': Icons.message,
      'signal': Icons.message,
      'default': Icons.security,
    };
  }

  /// Load custom icons from storage
  Future<void> _loadCustomIcons() async {
    final prefs = await SharedPreferences.getInstance();
    final iconsJson = prefs.getString(_customIconsKey);
    
    if (iconsJson != null) {
      final decoded = jsonDecode(iconsJson) as Map<String, dynamic>;
      _customIcons = decoded.cast<String, String>();
      notifyListeners();
    }
  }

  /// Save custom icons to storage
  Future<void> _saveCustomIcons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customIconsKey, jsonEncode(_customIcons));
  }

  /// Get icon for service/item
  IconData getIcon(String itemId, {String? serviceName}) {
    // Check if there's a custom icon
    if (_customIcons.containsKey(itemId)) {
      return Icons.image; // Custom image icon
    }
    
    // Try to match by service name
    if (serviceName != null) {
      final normalizedName = serviceName.toLowerCase().trim();
      for (final entry in _builtInIcons.entries) {
        if (normalizedName.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    
    // Try to match by item ID
    final normalizedId = itemId.toLowerCase();
    for (final entry in _builtInIcons.entries) {
      if (normalizedId.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return _builtInIcons['default']!;
  }

  /// Get custom icon path
  String? getCustomIconPath(String itemId) {
    return _customIcons[itemId];
  }

  /// Set custom icon for item
  Future<void> setCustomIcon(String itemId, Uint8List imageBytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final iconsDir = Directory('${directory.path}/custom_icons');
      
      if (!await iconsDir.exists()) {
        await iconsDir.create(recursive: true);
      }
      
      // Generate unique filename
      final hash = sha256.convert(imageBytes).toString();
      final fileName = '${itemId}_$hash.png';
      final filePath = '${iconsDir.path}/$fileName';
      
      // Save image file
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      
      // Update mapping
      _customIcons[itemId] = filePath;
      await _saveCustomIcons();
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to save custom icon: $e');
    }
  }

  /// Remove custom icon
  Future<void> removeCustomIcon(String itemId) async {
    final iconPath = _customIcons[itemId];
    if (iconPath != null) {
      try {
        final file = File(iconPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore file deletion errors
      }
      
      _customIcons.remove(itemId);
      await _saveCustomIcons();
      notifyListeners();
    }
  }

  /// Check if item has custom icon
  bool hasCustomIcon(String itemId) {
    return _customIcons.containsKey(itemId);
  }

  /// Get all available built-in icons
  Map<String, IconData> getBuiltInIcons() {
    return Map.unmodifiable(_builtInIcons);
  }

  /// Search built-in icons
  Map<String, IconData> searchBuiltInIcons(String query) {
    if (query.isEmpty) return _builtInIcons;
    
    final lowerQuery = query.toLowerCase();
    return Map.fromEntries(
      _builtInIcons.entries.where((entry) =>
        entry.key.toLowerCase().contains(lowerQuery)
      ),
    );
  }

  /// Get icon suggestions based on service name
  List<MapEntry<String, IconData>> getIconSuggestions(String serviceName) {
    final normalized = serviceName.toLowerCase();
    final suggestions = <MapEntry<String, IconData>>[];
    
    // Exact matches first
    for (final entry in _builtInIcons.entries) {
      if (normalized.contains(entry.key)) {
        suggestions.add(entry);
      }
    }
    
    // Partial matches
    for (final entry in _builtInIcons.entries) {
      if (entry.key.contains(normalized) && !suggestions.contains(entry)) {
        suggestions.add(entry);
      }
    }
    
    return suggestions.take(5).toList();
  }

  /// Clean up unused custom icons
  Future<void> cleanupUnusedIcons(List<String> activeItemIds) async {
    final unusedIcons = <String>[];
    
    for (final itemId in _customIcons.keys) {
      if (!activeItemIds.contains(itemId)) {
        unusedIcons.add(itemId);
      }
    }
    
    for (final itemId in unusedIcons) {
      await removeCustomIcon(itemId);
    }
  }

  /// Get custom icons directory size
  Future<int> getCustomIconsSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final iconsDir = Directory('${directory.path}/custom_icons');
      
      if (!await iconsDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in iconsDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Export custom icons
  Future<Map<String, dynamic>> exportCustomIcons() async {
    final exportData = <String, dynamic>{};
    
    for (final entry in _customIcons.entries) {
      try {
        final file = File(entry.value);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          exportData[entry.key] = base64Encode(bytes);
        }
      } catch (e) {
        // Skip failed exports
      }
    }
    
    return {
      'icons': exportData,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Import custom icons
  Future<void> importCustomIcons(Map<String, dynamic> data) async {
    try {
      final iconsData = data['icons'] as Map<String, dynamic>?;
      if (iconsData == null) return;
      
      for (final entry in iconsData.entries) {
        final itemId = entry.key;
        final base64Data = entry.value as String;
        final bytes = base64Decode(base64Data);
        
        await setCustomIcon(itemId, bytes);
      }
    } catch (e) {
      throw Exception('Failed to import custom icons: $e');
    }
  }
}
