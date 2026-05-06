import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webauthn_secure_storage_android/webauthn_secure_storage_android.dart';
import 'package:webauthn_secure_storage_platform_interface/webauthn_secure_storage_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricStorageAndroid Passkeys', () {
    late BiometricStorageAndroid plugin;
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      plugin = BiometricStorageAndroid();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannelBiometricStoragePlatform.channel,
            (MethodCall methodCall) async {
              log.add(methodCall);
              if (methodCall.method == 'registerPasskey') {
                return {
                  'id': 'test-id',
                  'rawId': 'test-raw-id',
                  'type': 'public-key',
                  'response': {
                    'clientDataJSON': 'YQ==',
                    'attestationObject': 'YQ==',
                  },
                };
              } else if (methodCall.method == 'authenticateWithPasskey') {
                return {
                  'id': 'test-id',
                  'rawId': 'test-raw-id',
                  'type': 'public-key',
                  'response': {
                    'clientDataJSON': 'YQ==',
                    'authenticatorData': 'YQ==',
                    'signature': 'YQ==',
                    'userHandle': 'YQ==',
                  },
                };
              }
              return null;
            },
          );
    });

    tearDown(() {
      log.clear();
    });

    test('registerPasskey calls method channel correctly', () async {
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

      final result = await plugin.registerPasskey(options);

      expect(log, hasLength(1));
      expect(log.first.method, 'registerPasskey');
      expect(result.id, 'test-id');
    });

    test('authenticateWithPasskey calls method channel correctly', () async {
      final options = PublicKeyCredentialRequestOptionsJson(
        challenge: 'challenge',
      );

      final result = await plugin.authenticateWithPasskey(options);

      expect(log, hasLength(1));
      expect(log.first.method, 'authenticateWithPasskey');
      expect(result.id, 'test-id');
    });
  });
}
