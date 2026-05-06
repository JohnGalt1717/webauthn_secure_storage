import 'package:flutter_test/flutter_test.dart';
import 'package:webauthn_secure_storage_linux/webauthn_secure_storage_linux.dart';
import 'package:webauthn_secure_storage_platform_interface/webauthn_secure_storage_platform_interface.dart';

void main() {
  group('BiometricStorageLinux Passkeys', () {
    late WebauthnSecureStorageLinux plugin;

    setUp(() {
      plugin = WebauthnSecureStorageLinux();
    });

    test(
      'registerPasskey throws UnimplementedError until completely supported',
      () async {
        final options = PublicKeyCredentialCreationOptionsJson(
          challenge: 'challenge',
          rp: PublicKeyCredentialRpEntityJson(name: 'RP'),
          user: PublicKeyCredentialUserEntityJson(
            id: 'id',
            name: 'user',
            displayName: 'User',
          ),
          pubKeyCredParams: [],
        );

        expect(
          () => plugin.registerPasskey(options),
          throwsA(isA<UnimplementedError>()),
        );
      },
    );

    test(
      'authenticateWithPasskey throws UnimplementedError until completely supported',
      () async {
        final options = PublicKeyCredentialRequestOptionsJson(
          challenge: 'challenge',
        );

        expect(
          () => plugin.authenticateWithPasskey(options),
          throwsA(isA<UnimplementedError>()),
        );
      },
    );
  });
}
