import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webauthn_secure_storage_platform_interface/webauthn_secure_storage_platform_interface.dart';

import 'src/default_webauthn_runtime.dart';
import 'src/webauthn_runtime.dart';
import 'src/web_plugin_registrar.dart';

export 'src/webauthn_runtime.dart' show WebAuthnRuntime, WebAuthnSupport;

class BiometricStorageWeb extends BiometricStoragePlatform {
  static const _storageKeyPrefix = 'webauthn_secure_storage_web:';

  @visibleForTesting
  static WebAuthnRuntime defaultRuntime = createDefaultWebAuthnRuntime();

  BiometricStorageWeb({WebAuthnRuntime? runtime})
      : _runtime = runtime ?? defaultRuntime;

  final WebAuthnRuntime _runtime;

  static void registerWith(WebPluginRegistrar registrar) {
    BiometricStoragePlatform.instance = BiometricStorageWeb();
  }

  Never _unsupported() => throw UnsupportedError(webAuthnUnsupportedMessage);

  String _storageKey(String name) => '$_storageKeyPrefix$name';

  Future<_StoredCredentialRecord?> _loadRecord(String name) async {
    final raw = _runtime.readRecord(_storageKey(name));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid web storage record format.');
    }

    return _StoredCredentialRecord.fromJson(decoded);
  }

  Future<void> _saveRecord(String name, _StoredCredentialRecord record) async {
    _runtime.writeRecord(_storageKey(name), jsonEncode(record.toJson()));
  }

  Uint8List _randomBytes(int length) => _runtime.randomBytes(length);

  Future<_StoredCredentialRecord> _ensureRecord(String name) async {
    final existing = await _loadRecord(name);
    if (existing != null) {
      return existing;
    }

    final prfSalt = _randomBytes(32);
    final credentialId = await _runtime.registerCredential(
      storageName: name,
      challenge: _randomBytes(32),
      userId: _randomBytes(32),
      prfSalt: prfSalt,
    );

    final record = _StoredCredentialRecord(
      version: 1,
      credentialIdBase64: _base64Encode(credentialId),
      prfSaltBase64: _base64Encode(prfSalt),
    );
    await _saveRecord(name, record);
    return record;
  }

  Future<Uint8List> _encrypt(Uint8List keyBytes, Uint8List plaintext) {
    return _runtime.encrypt(keyBytes: keyBytes, plaintext: plaintext);
  }

  Future<Uint8List> _decrypt(Uint8List keyBytes, Uint8List ciphertext) {
    return _runtime.decrypt(keyBytes: keyBytes, ciphertext: ciphertext);
  }

  String _base64Encode(Uint8List value) => base64UrlEncode(value);

  Uint8List _base64Decode(String value) =>
      Uint8List.fromList(base64Url.decode(value));

  Never _mapAuthError(Object error) {
    final name = _runtime.errorName(error);
    final message = _runtime.describeError(error);

    switch (name) {
      case 'NotAllowedError':
        throw AuthException(AuthExceptionCode.userCanceled, message);
      case 'AbortError':
      case 'InvalidStateError':
        throw AuthException(AuthExceptionCode.canceled, message);
      case 'SecurityError':
      case 'NotSupportedError':
        _unsupported();
      default:
        throw BiometricStorageException(message);
    }
  }

  @override
  Future<CanAuthenticateResponse> canAuthenticate({
    StorageFileInitOptions? options,
  }) async {
    final support = await _runtime.probeSupport();
    if (!support.isStorageSupported) {
      return CanAuthenticateResponse.unsupported;
    }
    if (!support.hasPlatformAuthenticator) {
      return CanAuthenticateResponse.errorNoHardware;
    }
    return CanAuthenticateResponse.success;
  }

  @override
  Future<PasskeyAvailability> getPasskeyAvailability() async {
    final support = await _runtime.probeSupport();
    return PasskeyAvailability(
      isSupported: support.isPasskeySupported,
      isAvailable:
          support.isPasskeySupported && support.hasPlatformAuthenticator,
      hasPlatformAuthenticator: support.hasPlatformAuthenticator,
      hasConditionalUi: support.hasConditionalUi,
      hasDiscoverableCredentials: support.hasConditionalUi,
      supportsPrfStorage: support.supportsPrf,
      isPrfStorageAvailable:
          support.supportsPrf && support.hasPlatformAuthenticator,
      metadata: <String, dynamic>{
        'isSecureContext': support.isSecureContext,
        'hasCredentialsApi': support.hasCredentialsApi,
        'hasPublicKeyCredential': support.hasPublicKeyCredential,
        'supportsPrf': support.supportsPrf,
      },
    );
  }

  @override
  Future<PublicKeyCredentialAttestationJson> registerPasskey(
    PublicKeyCredentialCreationOptionsJson options,
  ) async {
    final availability = await getPasskeyAvailability();
    if (!availability.isSupported) {
      _unsupported();
    }

    try {
      return await _runtime.registerPasskey(options);
    } catch (error) {
      if (error is AuthException ||
          error is UnsupportedError ||
          error is BiometricStorageException) {
        rethrow;
      }
      _mapAuthError(error);
    }
  }

  @override
  Future<PublicKeyCredentialAssertionJson> authenticateWithPasskey(
    PublicKeyCredentialRequestOptionsJson options,
  ) async {
    final availability = await getPasskeyAvailability();
    if (!availability.isSupported) {
      _unsupported();
    }

    try {
      return await _runtime.authenticateWithPasskey(options);
    } catch (error) {
      if (error is AuthException ||
          error is UnsupportedError ||
          error is BiometricStorageException) {
        rethrow;
      }
      _mapAuthError(error);
    }
  }

  @override
  Future<bool?> init(
    String name, {
    StorageFileInitOptions? options,
    bool forceInit = false,
  }) async {
    if (!await isSupported(options: options)) {
      return false;
    }

    if (forceInit) {
      _runtime.deleteRecord(_storageKey(name));
    }

    return true;
  }

  @override
  Future<bool> linuxCheckAppArmorError() async => false;

  @override
  Future<String?> read(
    String name,
    PromptInfo promptInfo, {
    bool forceBiometricAuthentication = false,
  }) async {
    final record = await _loadRecord(name);
    if (record == null || record.ciphertextBase64 == null) {
      return null;
    }

    if (!await isSupported()) {
      _unsupported();
    }

    try {
      final keyBytes = await _runtime.derivePrfSecret(
        credentialId: _base64Decode(record.credentialIdBase64),
        prfSalt: _base64Decode(record.prfSaltBase64),
        forceBiometricAuthentication: forceBiometricAuthentication,
      );
      final plaintext = await _decrypt(
        keyBytes,
        _base64Decode(record.ciphertextBase64!),
      );
      return utf8.decode(plaintext);
    } catch (error) {
      if (error is AuthException ||
          error is UnsupportedError ||
          error is BiometricStorageException) {
        rethrow;
      }
      _mapAuthError(error);
    }
  }

  @override
  Future<bool> exists(
    String name,
    PromptInfo promptInfo,
  ) async {
    final record = await _loadRecord(name);
    return record?.ciphertextBase64 != null;
  }

  @override
  Future<bool?> delete(
    String name,
    PromptInfo promptInfo,
  ) async {
    final existing = _runtime.readRecord(_storageKey(name));
    _runtime.deleteRecord(_storageKey(name));
    return existing != null;
  }

  @override
  Future<void> write(
    String name,
    String content,
    PromptInfo promptInfo, {
    bool forceBiometricAuthentication = false,
  }) async {
    if (!await isSupported()) {
      _unsupported();
    }

    final record = await _ensureRecord(name);

    try {
      final keyBytes = await _runtime.derivePrfSecret(
        credentialId: _base64Decode(record.credentialIdBase64),
        prfSalt: _base64Decode(record.prfSaltBase64),
        forceBiometricAuthentication: forceBiometricAuthentication,
      );
      final encrypted =
          await _encrypt(keyBytes, Uint8List.fromList(utf8.encode(content)));
      await _saveRecord(
        name,
        record.copyWith(
          ciphertextBase64: _base64Encode(encrypted),
        ),
      );
    } catch (error) {
      if (error is AuthException ||
          error is UnsupportedError ||
          error is BiometricStorageException) {
        rethrow;
      }
      _mapAuthError(error);
    }
  }

  @override
  Future<void> dispose(
    String name,
    PromptInfo promptInfo,
  ) async {}
}

class _StoredCredentialRecord {
  const _StoredCredentialRecord({
    required this.version,
    required this.credentialIdBase64,
    required this.prfSaltBase64,
    this.ciphertextBase64,
  });

  factory _StoredCredentialRecord.fromJson(Map<String, dynamic> json) {
    return _StoredCredentialRecord(
      version: json['version'] as int? ?? 1,
      credentialIdBase64: json['credentialIdBase64'] as String,
      prfSaltBase64: json['prfSaltBase64'] as String,
      ciphertextBase64: json['ciphertextBase64'] as String?,
    );
  }

  final int version;
  final String credentialIdBase64;
  final String prfSaltBase64;
  final String? ciphertextBase64;

  _StoredCredentialRecord copyWith({
    String? ciphertextBase64,
  }) {
    return _StoredCredentialRecord(
      version: version,
      credentialIdBase64: credentialIdBase64,
      prfSaltBase64: prfSaltBase64,
      ciphertextBase64: ciphertextBase64 ?? this.ciphertextBase64,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': version,
        'credentialIdBase64': credentialIdBase64,
        'prfSaltBase64': prfSaltBase64,
        'ciphertextBase64': ciphertextBase64,
      };
}
