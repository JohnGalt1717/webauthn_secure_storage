import 'package:webauthn_secure_storage_platform_interface/webauthn_secure_storage_platform_interface.dart';

class WebauthnSecureStorageLinux extends BiometricStoragePlatform {
  /// Registers this class as the default instance of [BiometricStoragePlatform].
  static void registerWith() {
    BiometricStoragePlatform.instance = WebauthnSecureStorageLinux();
  }

  @override
  Future<CanAuthenticateResponse> checkSupported() async {
    return CanAuthenticateResponse.unsupported;
  }

  @override
  Future<String?> read({required String name, required StorageOptions options}) async {
    throw UnsupportedError('Storage is not supported on Linux yet.');
  }

  @override
  Future<void> write({required String name, required String content, required StorageOptions options}) async {
    throw UnsupportedError('Storage is not supported on Linux yet.');
  }

  @override
  Future<void> delete({required String name, required StorageOptions options}) async {
    throw UnsupportedError('Storage is not supported on Linux yet.');
  }

  @override
  Future<PublicKeyCredentialJson> registerPasskey(PublicKeyCredentialCreationOptionsJson options) async {
    throw UnsupportedError('Passkeys are not supported on Linux yet.');
  }

  @override
  Future<PublicKeyCredentialJson> authenticateWithPasskey(PublicKeyCredentialRequestOptionsJson options) async {
    throw UnsupportedError('Passkeys are not supported on Linux yet.');
  }
}
