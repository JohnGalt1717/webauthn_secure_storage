import 'package:webauthn_secure_storage_platform_interface/webauthn_secure_storage_platform_interface.dart';

class WebauthnSecureStorageLinux extends MethodChannelBiometricStoragePlatform {
  static void registerWith() {
    BiometricStoragePlatform.instance = WebauthnSecureStorageLinux();
  }

  @override
  Future<CanAuthenticateResponse> canAuthenticate({
    StorageFileInitOptions? options,
  }) async {
    final response = await MethodChannelBiometricStoragePlatform.channel
        .invokeMethod<String>(
      'canAuthenticate',
      <String, dynamic>{
        'options': options?.toJson() ?? StorageFileInitOptions().toJson(),
      },
    );
    return mapCanAuthenticateResponse(response);
  }

  @override
  Map<String, dynamic> buildPromptInfoArguments(PromptInfo promptInfo) =>
      <String, dynamic>{};

  @override
  Future<bool> linuxCheckAppArmorError() async {
    await init(
      'appArmorCheck',
      options: StorageFileInitOptions(authenticationRequired: false),
    );
    try {
      await read('appArmorCheck', PromptInfo.defaultValues);
      return false;
    } on AuthException catch (e) {
      if (e.code == AuthExceptionCode.linuxAppArmorDenied) {
        return true;
      }
      rethrow;
    }
  }

  @override
  Future<void> dispose(String name, PromptInfo promptInfo) async {}
}
