import 'package:webauthn_secure_storage_platform_interface/webauthn_secure_storage_platform_interface.dart';

class PasskeyWindows {
  static Future<PublicKeyCredentialAttestationJson> registerPasskey(
      PublicKeyCredentialCreationOptionsJson options) async {
    throw UnsupportedError('Passkeys are not supported on Windows yet.');
  }

  static Future<PublicKeyCredentialAssertionJson> authenticateWithPasskey(
      PublicKeyCredentialRequestOptionsJson options) async {
    throw UnsupportedError('Passkeys are not supported on Windows yet.');
  }
}
