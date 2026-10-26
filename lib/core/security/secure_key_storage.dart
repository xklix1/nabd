import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages encryption keys backed exclusively by Android Keystore and iOS Keychain.
/// Zero plain-text storage in SharedPreferences or UserDefaults.
class SecureKeyStorage {
  static const String _dbKeyAlias = 'nabd_sqlcipher_master_key';

  final FlutterSecureStorage _storage;

  SecureKeyStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: false,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
                synchronizable: false,
              ),
            );

  /// Retrieves the existing AES-256 database passphrase or creates a cryptographically secure 256-bit key.
  Future<String> getOrCreateDatabaseEncryptionKey() async {
    final existingKey = await _storage.read(key: _dbKeyAlias);
    if (existingKey != null && existingKey.isNotEmpty) {
      return existingKey;
    }

    final newKey = _generateCryptographicKey();
    await _storage.write(key: _dbKeyAlias, value: newKey);
    return newKey;
  }

  /// Generates 32 cryptographically secure random bytes (256-bit) encoded as hex.
  String _generateCryptographicKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// Securely stores user authentication token or PIN if cloud sync is activated.
  Future<void> saveSecureToken(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Reads secure token.
  Future<String?> readSecureToken(String key) async {
    return _storage.read(key: key);
  }

  /// Deletes key on explicit user profile wipe.
  Future<void> deleteKey(String key) async {
    await _storage.delete(key: key);
  }
}
