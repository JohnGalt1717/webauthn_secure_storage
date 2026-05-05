import 'package:webauthn_secure_storage_platform_interface/webauthn_secure_storage_platform_interface.dart';

class PasskeyWindows {
  static Future<PublicKeyCredentialAttestationJson> registerPasskey(
      PublicKeyCredentialCreationOptionsJson options) async {
    // Basic stub bridging to ensure interface compatibility
    throw UnimplementedError('Windows Passkeys WebAuthN API not fully mocked yet in tests');
  }

  static Future<PublicKeyCredentialAssertionJson> authenticateWithPasskey(
      PublicKeyCredentialRequestOptionsJson options) async {
    throw UnimplementedError('Windows Passkeys WebAuthN API not fully mocked yet in tests');
  }
}
