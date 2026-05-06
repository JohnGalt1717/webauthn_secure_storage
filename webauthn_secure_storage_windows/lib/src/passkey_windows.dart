import 'package:webauthn_secure_storage_platform_interface/webauthn_secure_storage_platform_interface.dart';

class PasskeyWindows {
  Future<PublicKeyCredentialJson> registerPasskey(PublicKeyCredentialCreationOptionsJson options) async {
    throw UnsupportedError('Passkeys are not supported on Windows yet.');
  }

  Future<PublicKeyCredentialJson> authenticateWithPasskey(PublicKeyCredentialRequestOptionsJson options) async {
    throw UnsupportedError('Passkeys are not supported on Windows yet.');
  }
}
