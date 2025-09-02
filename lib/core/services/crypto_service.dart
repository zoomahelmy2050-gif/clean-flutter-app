import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class CryptoService {
  static const int defaultIterations = 200000; // adjust for performance
  static const int saltLength = 16;

  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: defaultIterations,
    bits: 256,
  );

  final Cipher _aesGcm = AesGcm.with256bits();

  Uint8List randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => rnd.nextInt(256)));
    }

  Future<Uint8List> deriveKey({
    required String password,
    required Uint8List salt,
    required int iterations,
  }) async {
    final algo = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    final secretKey = await algo.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }

  Future<String> computePasswordRecord(String password) async {
    final salt = randomBytes(saltLength);
    final key = await deriveKey(password: password, salt: salt, iterations: defaultIterations);
    // Use a verifier = HMAC-SHA256(salt, key)
    final macAlgo = Hmac.sha256();
    final mac = await macAlgo.calculateMac(key, secretKey: SecretKey(salt));
    final verifier = Uint8List.fromList(mac.bytes);
    return 'v2:${base64Encode(salt)}:$defaultIterations:${base64Encode(verifier)}';
  }

  Future<bool> verifyPassword(String candidate, String record) async {
    if (!record.startsWith('v2:')) return false;
    final parts = record.split(':');
    if (parts.length != 4) return false;
    final salt = Uint8List.fromList(base64Decode(parts[1]));
    final iters = int.tryParse(parts[2]) ?? defaultIterations;
    final expected = base64Decode(parts[3]);

    final key = await deriveKey(password: candidate, salt: salt, iterations: iters);
    final macAlgo = Hmac.sha256();
    final mac = await macAlgo.calculateMac(key, secretKey: SecretKey(salt));
    final got = mac.bytes;
    return _constantTimeEquals(Uint8List.fromList(expected), Uint8List.fromList(got));
  }

  Future<Map<String, String>> encryptJson({
    required Map<String, dynamic> json,
    required Uint8List key,
  }) async {
    final nonce = randomBytes(12);
    final secretKey = SecretKey(key);
    final data = utf8.encode(jsonEncode(json));
    final secretBox = await _aesGcm.encrypt(data, secretKey: secretKey, nonce: nonce);
    return {
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  Future<Map<String, dynamic>> decryptJson({
    required Map<String, String> payload,
    required Uint8List key,
  }) async {
    final nonce = base64Decode(payload['nonce'] ?? '');
    final cipherText = base64Decode(payload['ciphertext'] ?? '');
    final mac = Mac(base64Decode(payload['mac'] ?? ''));
    final secretKey = SecretKey(key);
    final plain = await _aesGcm.decrypt(
      SecretBox(cipherText, nonce: Uint8List.fromList(nonce), mac: mac),
      secretKey: secretKey,
    );
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  }

  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
