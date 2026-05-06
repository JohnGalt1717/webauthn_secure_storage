import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webauthn_secure_storage_darwin/webauthn_secure_storage_darwin.dart';
import 'package:webauthn_secure_storage_platform_interface/webauthn_secure_storage_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricStorageDarwin Passkeys', () {
    late BiometricStorageDarwin plugin;
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      plugin = BiometricStorageDarwin();
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
                    'clientDataJSON': 'Y2xpZW50RGF0YUpTT04=',
                    'attestationObject': 'YXR0ZXN0YXRpb25PYmplY3Q=',
                  },
                };
              } else if (methodCall.method == 'authenticateWithPasskey') {
                return {
                  'id': 'test-id',
                  'rawId': 'test-raw-id',
                  'type': 'public-key',
                  'response': {
                    'clientDataJSON': 'Y2xpZW50RGF0YUpTT04=',
                    'authenticatorData': 'YXV0aGVudGljYXRvckRhdGE=',
                    'signature': 'c2lnbmF0dXJl',
                    'userHandle': 'dXNlckhhbmRsZQ==',
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
