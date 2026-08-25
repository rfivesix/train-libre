// lib/util/encryption_util.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Utility for performing secure data encryption and decryption.
///
/// Uses AES-GCM 256-bit encryption with PBKDF2 key derivation for strong security.
class EncryptionUtil {
  static final _algo = AesGcm.with256bits();

  /// Legacy version of the encryption wrapper format (150,000 iterations).
  static const wrapperVersionV1 = 'LWENC-1';

  /// Current version of the encryption wrapper format (600,000 iterations).
  static const wrapperVersionV2 = 'LWENC-2';

  /// Encrypts [plaintext] using a [passphrase].
  ///
  /// Returns a map containing the version, salt, nonce, cipher text, and MAC.
  static Future<Map<String, dynamic>> encryptString(
    String plaintext,
    String passphrase,
  ) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    // Use 600,000 iterations for new encryptions
    final key = await _deriveKey(passphrase, salt, iterations: 600000);
    final box = await _algo.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    return {
      'enc': wrapperVersionV2, // Use new version format
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'cipher': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  static Future<String> decryptToString(
    Map<String, dynamic> wrapper,
    String passphrase,
  ) async {
    final String version = wrapper['enc'] as String? ?? wrapperVersionV1;
    if (version != wrapperVersionV1 && version != wrapperVersionV2) {
      throw ArgumentError('Unknown encryption wrapper: $version');
    }

    // Determine the number of iterations based on the wrapper version
    final int iterations = (version == wrapperVersionV2) ? 600000 : 150000;

    final salt = base64Decode(wrapper['salt'] as String);
    final nonce = base64Decode(wrapper['nonce'] as String);
    final cipher = base64Decode(wrapper['cipher'] as String);
    final mac = Mac(base64Decode(wrapper['mac'] as String));
    final key = await _deriveKey(passphrase, salt, iterations: iterations);
    final clear = await _algo.decrypt(
      SecretBox(cipher, nonce: nonce, mac: mac),
      secretKey: key,
    );
    return utf8.decode(clear);
  }

  /// A key derived once and reused for every entry of one backup archive.
  ///
  /// [encryptString] derives its own key per call, which is right for a single
  /// document but unusable for an archive: at 600,000 PBKDF2 iterations each,
  /// a backup carrying a few hundred meal previews would spend minutes doing
  /// nothing but key derivation. One derivation with a fresh nonce per entry
  /// gives the same protection — reusing a *nonce* would be the dangerous part,
  /// and every entry gets its own.
  static Future<BackupCipher> newCipher(String passphrase) async {
    final salt = _randomBytes(16);
    return BackupCipher._(
      await _deriveKey(passphrase, salt, iterations: 600000),
      salt,
    );
  }

  /// Rebuilds the cipher of an existing archive from its stored header.
  static Future<BackupCipher> cipherFromHeader(
    Map<String, dynamic> header,
    String passphrase,
  ) async {
    final version = header['enc'] as String? ?? wrapperVersionV1;
    if (version != wrapperVersionV1 && version != wrapperVersionV2) {
      throw ArgumentError('Unknown encryption wrapper: $version');
    }
    final iterations = version == wrapperVersionV2 ? 600000 : 150000;
    final salt = base64Decode(header['salt'] as String);
    return BackupCipher._(
      await _deriveKey(passphrase, salt, iterations: iterations),
      salt,
    );
  }

  static Future<SecretKey> _deriveKey(
    String passphrase,
    List<int> salt, {
    int iterations = 150000,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  /// A fresh nonce for one archive entry.
  static List<int> randomNonce(int length) => _randomBytes(length);

  static List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}

/// Encrypts the entries of one backup archive under a single derived key.
///
/// Each entry is stored as `nonce || ciphertext || mac`; the key derivation
/// itself is described by [header], which travels in the archive in the clear.
class BackupCipher {
  BackupCipher._(this._key, this._salt);

  final SecretKey _key;
  final List<int> _salt;

  static final _algo = AesGcm.with256bits();
  static const _nonceLength = 12;
  static const _macLength = 16;

  /// Everything a reader needs to derive the same key from the passphrase.
  Map<String, dynamic> get header => {
        'enc': EncryptionUtil.wrapperVersionV2,
        'salt': base64Encode(_salt),
      };

  Future<Uint8List> encrypt(List<int> data) async {
    final nonce = EncryptionUtil.randomNonce(_nonceLength);
    final box = await _algo.encrypt(data, secretKey: _key, nonce: nonce);
    return Uint8List.fromList([...nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  Future<Uint8List> decrypt(List<int> data) async {
    if (data.length < _nonceLength + _macLength) {
      throw ArgumentError('Encrypted entry is too short to be valid');
    }
    final nonce = data.sublist(0, _nonceLength);
    final cipher = data.sublist(_nonceLength, data.length - _macLength);
    final mac = Mac(data.sublist(data.length - _macLength));
    final clear = await _algo.decrypt(
      SecretBox(cipher, nonce: nonce, mac: mac),
      secretKey: _key,
    );
    return Uint8List.fromList(clear);
  }
}
