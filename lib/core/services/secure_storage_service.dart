import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecureStorageService {
  static const _masterKeyName = 'e2ee_master_key_v1';

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  SecureStorageService({FlutterSecureStorage? storage})
      : _secureStorage = storage ?? const FlutterSecureStorage();

  Future<Uint8List> getOrCreateMasterKey() async {
    final existing = await _secureStorage.read(key: _masterKeyName);
    if (existing != null && existing.isNotEmpty) {
      return Uint8List.fromList(base64Decode(existing));
    }
    final rnd = Random.secure();
    final key = Uint8List.fromList(List<int>.generate(32, (_) => rnd.nextInt(256)));
    await _secureStorage.write(key: _masterKeyName, value: base64Encode(key));
    return key;
  }

  @visibleForTesting
  Future<void> resetMasterKey() async {
    await _secureStorage.delete(key: _masterKeyName);
  }

  Future<bool> authenticate({String reason = 'Authenticate to unlock secure data'}) async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canCheck) return false;
      final didAuth = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      return didAuth;
    } catch (_) {
      return false;
    }
  }
}
