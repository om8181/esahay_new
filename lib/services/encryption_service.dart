import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  final _storage = const FlutterSecureStorage();

  Future<Key> getUserKey(String userId) async {
    String? keyString = await _storage.read(key: "key_$userId");

    if (keyString == null) {
      final key = Key.fromSecureRandom(32);

      await _storage.write(
        key: "key_$userId",
        value: key.base64,
      );

      return key;
    }

    return Key.fromBase64(keyString);
  }
}