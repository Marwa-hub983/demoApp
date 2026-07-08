import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CacheService {
  final FlutterSecureStorage _secureStorage;
  late final Box _encryptedBox;
  late final Box _normalBox;

  CacheService(this._secureStorage);

  Future<void> init() async {
    await Hive.initFlutter();

    // 1. Get/Create encryption key
    const secureKeyName = 'hive_encryption_key';
    var containsKey = await _secureStorage.containsKey(key: secureKeyName);
    List<int> encryptionKey;

    if (!containsKey) {
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: secureKeyName,
        value: base64UrlEncode(key),
      );
      encryptionKey = key;
    } else {
      final base64Key = await _secureStorage.read(key: secureKeyName);
      encryptionKey = base64Url.decode(base64Key!);

    }

    // 2. Open boxes
    _encryptedBox = await Hive.openBox(
      'secure_cache',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    _normalBox = await Hive.openBox('general_cache');
  }

  // Generic methods
  Future<void> saveSecure(String key, dynamic value) async {
    await _encryptedBox.put(key, value);
  }

  dynamic readSecure(String key) {
    return _encryptedBox.get(key);
  }

  Future<void> deleteSecure(String key) async {
    await _encryptedBox.delete(key);
  }

  Future<void> save(String key, dynamic value) async {
    await _normalBox.put(key, value);
  }

  dynamic read(String key) {
    return _normalBox.get(key);
  }

  Future<void> delete(String key) async {
    await _normalBox.delete(key);
  }

  Future<void> clearAll() async {
    await _encryptedBox.clear();
    await _normalBox.clear();
  }
}
