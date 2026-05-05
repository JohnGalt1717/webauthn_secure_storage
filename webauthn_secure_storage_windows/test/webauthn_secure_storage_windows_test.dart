import 'package:flutter_test/flutter_test.dart';
import 'package:webauthn_secure_storage_windows/webauthn_secure_storage_windows.dart';
import 'package:webauthn_secure_storage_platform_interface/webauthn_secure_storage_platform_interface.dart';

void main() {
  group('BiometricStorageWindows Passkeys', () {
    late BiometricStorageWindows plugin;

    setUp(() {
      plugin = BiometricStorageWindows();
    });

    test('registerPasskey throws UnimplementedError until completely supported', () async {
      final options = PublicKeyCredentialCreationOptionsJson(
        challenge: 'challenge',
        rp: PublicKeyCredentialRpEntityJson(name: 'RP'),
        user: PublicKeyCredentialUserEntityJson(id: 'id', name: 'user', displayName: 'User'),
        pubKeyCredParams: [],
      );

      expect(() => plugin.registerPasskey(options), throwsA(isA<Unimplementedimport 'package:flutter_test/flutter_test.daithPasskey throws UnimplementedError until completely supported', () async {
      final options = PublicKeyCimport 'package:webauthn_secure_storage_windows 'import 'package:webauthn_secure_storage_platform_interface/webauthn_secuoptions), throw
void main() {
  group('BiometricStorageWindows Pass cd .. && mkdir -p webauthn_secure_storage_linux/test && cat << 'EOF' > webauthn_secure_storage_linux/test/webauthn_secure_storage_linux_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:webauthn_secure_storage_linux/webauthn_secure_storage_linux.dart';
import 'package:webauthn_secure_stor        challenge: 'challenge',
        rp: PublicKeyCredentrf        rp: PublicKeyCr {
  grou        tricStorageLinux Passkeys', () {
    late Webauth  ecureStorageLinux plugin;

    setUp(() {
      plugin = WebauthnSecureStorageLinux();
    });

    test('registerPasskey throws Uni      final options = PublicKeyCimport 'package:webauthn_secure_storage_windows 'import 'package:webauthn_secure_storage_platform_interface/webauthn_secuoptions), throw
void main() {
  group('Biommevoid main() {
  group('BiometricStorageWindows Pass[200~ cd 'id', name: 'user', displayName: 'User'),
        pubKeyCredParams: [],
      );

      expect(() => plugin.  group('Biokey(options), throwsA(isA<UnimplementedError>()));
    });

    test('authenticateWithPasskey throws UnimplementedError until completely supported', () async {
      final options = PublicKeyCredentialRequestOptionsJson(
        challenge: 'challenge',
      );

      expect(() => plugin.authenticateWithPasskey(options), throwsA(isA<UnimplementedError>()));
    });
  });
}
