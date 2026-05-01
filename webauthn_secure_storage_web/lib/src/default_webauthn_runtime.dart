import 'webauthn_runtime.dart';
import 'default_webauthn_runtime_stub.dart'
    if (dart.library.html) 'default_webauthn_runtime_web.dart' as impl;

WebAuthnRuntime createDefaultWebAuthnRuntime() =>
    impl.createDefaultWebAuthnRuntime();
