# webauthn_secure_storage

[![Pub](https://img.shields.io/pub/v/webauthn_secure_storage?color=green)](https://pub.dev/packages/webauthn_secure_storage/)

Encrypted file store, **optionally** secured by biometric lock,
plus standards-based WebAuthn / passkey APIs for challenge-response
authentication flows.

Meant as a way to store small data in a hardware encrypted fashion. E.g. to
store passwords, secret keys, etc. but not massive amounts
of data.

- Android: Uses androidx with KeyStore.
- iOS and MacOS: LocalAuthentication with KeyChain.
- Linux: Stores values in Keyring using libsecret. (No biometric authentication support).
- Windows: Uses [wincreds.h to store into read/write into credential store](https://docs.microsoft.com/en-us/windows/win32/api/wincred/).
- Web: Uses WebAuthn for passkey authentication and WebAuthn PRF for local
  secret storage only when the browser can prove PRF support at runtime.
  Unsupported PRF browsers cleanly report storage support as unavailable
  instead of falling back to weaker storage.

## Web support and security

This package is intended to unlock secrets on-device using platform security
primitives such as Android Keystore and Apple Keychain, optionally gated by
biometrics.

The app-facing API now has two related surfaces:

- biometric / secure-storage APIs for local secret protection
- standards-based WebAuthn / passkey DTO APIs for server-driven
  registration/authentication flows

On the web, the federated implementation is intentionally stricter than a plain `localStorage` wrapper:

- passkey authentication only requires a secure context plus browser WebAuthn
  support
- it requires a secure context (`https:` or equivalent localhost secure context)
- secure local secret storage additionally requires runtime-advertised support
  for the PRF extension
- both flows require a user-verifying platform authenticator (Touch ID, Face ID, Android device unlock, etc.)
- PRF-backed storage stores only encrypted ciphertext plus WebAuthn credential metadata in browser storage

If the browser cannot honestly prove PRF support — for example, many
Windows/browser combinations today still do not expose it —
`isSupported()` returns `false` and `canAuthenticate()` returns
`unsupported` for the storage surface even though passkey authentication may
still be available.

## Passkeys and secure-access capabilities

Use `BiometricStorage().getCapabilities()` or the newer capability helpers when
you need to distinguish:

- biometric-backed local secret storage
- passkey authentication support
- passkey PRF-backed local secret storage

```dart
final biometricStorage = BiometricStorage();
final capabilities = await biometricStorage.getCapabilities();

if (capabilities.isCapabilityAvailable(
  SecureAccessCapability.passkeyAuthentication,
)) {
  // Offer passkey login.
}

if (capabilities.isCapabilityAvailable(
  SecureAccessCapability.passkeyPrfStorage,
)) {
  // Offer passkey-backed local secret unlock.
} else if (capabilities.isCapabilityAvailable(
  SecureAccessCapability.biometricStorage,
)) {
  // Fall back to biometric local secret unlock.
}
```

For passkey challenge-response flows, pass the standard server options straight
through the package and post the results back to your server:

```dart
final registration = await biometricStorage.registerPasskey(serverOptions);
final assertion = await biometricStorage.authenticateWithPasskey(requestOptions);
```

The DTOs are standards-based and designed to round-trip cleanly with server
platforms such as ASP.NET Core or Next.js ecosystems without bespoke field
mapping.

### What this means in practice

- Web support is capability-gated, not assumed.
- A storage handle can still be created without prompting the user.
- The first `write()` creates the WebAuthn credential when the user opts in.
- A later `read()` prompts the platform authenticator only if a stored credential already exists.

### Recommended approach for web

For web applications, prefer:

- server-backed session tokens with short lifetimes
- passkeys / WebAuthn for authentication
- keeping the most sensitive bearer secrets off the browser when possible

If you need a browser login flow, this package can participate through the
passkey APIs when WebAuthn is available. For local secret storage or unlock,
PRF support is still required. When PRF is not available, the intended fallback
remains your regular web login/session design or a non-PRF secure access path.

## Getting Started

### Supported vs available right now

This package intentionally distinguishes between:

- **supported**: the platform can use biometric-backed storage APIs at all
- **available right now**: the platform authenticator can actually be used at
  this moment

That distinction matters in real apps.

For example on macOS, Touch ID storage can still be **supported** while
biometrics are **temporarily unavailable** because:

- the Mac is in closed clamshell mode
- biometrics are locked out temporarily
- no biometric enrollment is present
- the device requires passcode / credential setup first

In those cases:

- `isSupported()` may still return `true`
- `canAuthenticate()` reports the current runtime state
- `canAuthenticateWithBiometrics()` returns whether you should offer biometric
  login **right now**

Use this rule of thumb:

- use `isSupported()` to decide whether the app can ever offer biometric-backed
  storage on this platform
- use `canAuthenticate()`, `canAuthenticateWithBiometrics()`, or
  `getCapabilities().isBiometricStorageAvailable` to decide whether to show or
  auto-start biometric login right now

Do **not** gate your biometric-login button only on `isSupported()` or on
whether `getStorageIfSupported()` returns a handle. A storage handle can exist
even when the authenticator is temporarily unavailable.

### Installation and project configuration

This package is federated. Your Flutter app usually depends only on
`webauthn_secure_storage`, but the project hosting it must still be configured
correctly per platform.

### Platform quick-reference

| Platform | Local secret storage | Biometric gate | Passkey APIs in this release | Project setup required |
| --- | --- | --- | --- | --- |
| Android | Yes | Yes | No | Yes |
| iOS | Yes | Yes | No | Yes |
| macOS | Yes | Yes | No | Yes |
| Linux | Yes | No | No | Sometimes |
| Windows | Yes | No current biometric gate | No | Minimal |
| Web | PRF-capable browsers only | WebAuthn user verification | Yes | Yes |

### Android

Requirements:

- Android API level >= 23 (`minSdkVersion 23`)
- a current Kotlin/AGP/Flutter toolchain
- `MainActivity` must extend `FlutterFragmentActivity`
- the hosting activity theme should inherit from an AppCompat theme on older
  Android versions

The example app uses:

- `Theme.AppCompat.NoActionBar` in `android/app/src/main/res/values/styles.xml`
- `FlutterFragmentActivity` in `MainActivity.kt`

Typical checklist:

1. Ensure `minSdkVersion` is at least `23`.
2. Make your activity extend `FlutterFragmentActivity` instead of
   `FlutterActivity`.
3. Use an AppCompat-based launch/activity theme.
4. Keep release signing configured normally for your app; this package does not
   require special Android permissions in `AndroidManifest.xml`.

Example activity base class:

```kotlin
class MainActivity : FlutterFragmentActivity()
```

Example theme inheritance:

```xml
<style name="LaunchTheme" parent="Theme.AppCompat.NoActionBar">
```

What to expect:

- `isSupported()` can be `true` on supported Android hardware
- `canAuthenticate()` reports runtime state such as no enrollment or temporary
  hardware unavailability
- passkey APIs are not currently implemented natively on Android in this first
  release

Helpful references:

- <https://developer.android.com/topic/security/data>
- <https://developer.android.com/topic/security/best-practices>

### iOS

Current plugin baseline:

- iOS deployment target: `13.0+`

Required project settings:

1. Add `NSFaceIDUsageDescription` to `ios/Runner/Info.plist` with a user-facing
   explanation.
2. Run normal CocoaPods installation (`flutter pub get`, then `pod install` as
   needed by Flutter tooling).
3. Sign the app normally for device testing and release builds.

Example `Info.plist` entry:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to unlock your encrypted local secrets.</string>
```

Notes:

- iOS uses LocalAuthentication + Keychain.
- No extra entitlement is required just to use this package’s biometric-backed
  storage in a standard iOS app.
- On iOS, apps should not expect a separate Keychain access consent dialog;
  protected operations use the normal LocalAuthentication prompt instead.
- Since iOS 15, simulator local-auth behavior is limited and often not
  representative of real devices.
- passkey APIs are not currently implemented natively on iOS in this first
  release, so you do **not** need to add Associated Domains just for this
  package today.

Apple reference:

- <https://developer.apple.com/documentation/localauthentication/logging_a_user_into_your_app_with_face_id_or_touch_id>
- <https://developer.apple.com/forums/thread/685773>

### macOS

Current plugin baseline:

- macOS deployment target: `10.15+`

Required project settings:

1. Add `NSFaceIDUsageDescription` to `macos/Runner/Info.plist`.
2. Enable code signing for normal app builds.
3. If your app uses the App Sandbox, add a `keychain-access-groups`
   entitlement.
4. Ensure your entitlements are present in both debug/profile and release
   configurations.

The example app demonstrates this in:

- `macos/Runner/Info.plist`
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

Example `Info.plist` entry:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Use Touch ID / Face ID to unlock encrypted local secrets.</string>
```

Example entitlement shape when sandboxed:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>keychain-access-groups</key>
<array>
  <string>$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)</string>
</array>
```

Important macOS notes:

- this package uses LocalAuthentication + Keychain
- a signed app with correct entitlements is the reliable path for device
  testing and distribution
- closed clamshell mode can make Touch ID unavailable **temporarily** even when
  biometric-backed storage is still supported on that Mac
- gate UI on `canAuthenticate()` / `canAuthenticateWithBiometrics()`, not only
  on `isSupported()`
- passkey APIs are not currently implemented natively on macOS in this first
  release, so Associated Domains are not required for this package today

#### What to do if you get a prompt for Keychain access

On macOS, the intended experience for protected items is the **system
authentication prompt** (Touch ID / password), not the classic Keychain Access
dialog asking whether to allow the app to access an item.

If you see the classic Keychain Access prompt, it usually means macOS does not
see your app as the same trusted/signed app identity that originally created
the item.

Most common fixes:

1. **Make sure the app is signed consistently**
   - in Xcode, select the macOS Runner target
   - enable automatic signing or otherwise use a stable signing identity
   - keep the same Team ID between runs
2. **Keep the bundle identifier stable**
   - changing the bundle ID can make a later build look like a different app to
     Keychain
3. **Keep entitlements aligned across configurations**
   - if you use the App Sandbox, include `keychain-access-groups`
   - make sure both debug/profile and release builds point at valid
     entitlements files
   - the example app includes this in both
     `macos/Runner/DebugProfile.entitlements` and
     `macos/Runner/Release.entitlements`
4. **Clean out stale development state after signing changes**
   - if you previously ran unsigned builds, changed teams, or changed bundle
     identifiers, delete the old app from your machine
   - remove old test items for the app from Keychain Access if they were created
     under the wrong identity
   - then rebuild and run the newly signed app

What your entitlements should look like in a sandboxed app:

- `com.apple.security.app-sandbox = true`
- `keychain-access-groups` containing your app identifier prefix + bundle ID

Example shape:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>keychain-access-groups</key>
<array>
  <string>$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)</string>
</array>
```

If you still get the classic Keychain dialog after fixing signing and
entitlements, treat that as an app configuration problem first, not as the
expected runtime UX of this package.

### Linux

Linux support is intentionally narrower:

- secure local storage uses `libsecret` / the desktop keyring
- biometric authentication is **not** supported on Linux in this package

Project/runtime expectations:

1. The target system needs a working Secret Service / keyring implementation.
2. Snap-packaged apps may need the password-manager interface connected.
3. Treat Linux as secure storage without a biometric gate.

For Snap environments, the example app surfaces the common fix:

```text
snap connect <your-snap-name>:password-manager-service
```

If you want to diagnose that case at runtime, use:

```dart
final denied = await BiometricStorage().linuxCheckAppArmorError();
```

### Windows

Windows support in this first release uses Windows Credential Manager for local
secret storage.

What this means:

- local secret storage works
- biometric prompting is not currently implemented as a runtime gate in the
  Windows federated implementation
- passkey APIs are not currently implemented natively on Windows in this first
  release

Project setup is minimal:

- no extra `Info.plist`/entitlement-style step exists on Windows
- normal Flutter Windows build setup is sufficient
- you should still gate any biometric-specific UI on
  `canAuthenticateWithBiometrics()`, which is expected to be `false` on the
  current Windows implementation

### Web

Web support is the most capability-sensitive platform.

Requirements:

1. Serve the app from a secure context (`https:` or localhost secure context).
2. Use browsers with WebAuthn support for passkey APIs.
3. Use browsers that expose the PRF extension if you want local secure-storage
   support on the web.
4. Ensure your server-provided WebAuthn options use an RP ID / origin that
   actually matches your deployed site.

Important behavior:

- passkey authentication is implemented on web in this release
- PRF-backed local secret storage is stricter than plain browser storage and is
  only available when runtime PRF support is proven
- `isSupported()` may be `false` for storage on browsers where passkey login is
  still available

Practical checklist:

1. Deploy over HTTPS.
2. Configure your backend WebAuthn relying-party settings to match your real
   host name.
3. Use `getCapabilities()` if you need to distinguish passkey login from
   PRF-backed local secret storage.
4. Expect local development on `localhost` to behave differently from random
   insecure LAN origins.

### Flutter / CocoaPods / generated files

For Apple platforms, let Flutter manage generated pod settings unless you have a
strong reason not to.

Typical recovery steps when platform integration gets weird:

1. `flutter pub get`
2. let Flutter regenerate iOS/macOS ephemeral files
3. run CocoaPods install/update through the normal Flutter workflow
4. clean/rebuild if Xcode still shows stale signing or entitlement state

This package does not require custom pod edits beyond the normal Flutter iOS and
macOS project setup.

### Usage

> You basically only need 4 methods.

1. Check whether the package is supported on this platform

```dart
final storage = BiometricStorage();
if (!await storage.isSupported()) {
  // Skip biometrics entirely and fall back to regular login.
  return;
}
```

1. Check whether biometric authentication is available right now

```dart
final response = await storage.canAuthenticate();
if (response.shouldFallbackToRegularLogin) {
  // Show regular login. You can still inspect response to see if the user
  // needs to enroll biometrics, enable a passcode, etc.
  return;
}
```

If you only need a bool for startup auth, you can use:

```dart
final canAutoPrompt = await storage.canAuthenticateWithBiometrics();
```

1. Create the access object

```dart
final store = await storage.getStorageIfSupported('mystorage');
if (store == null) {
  // Unsupported platform: skip without throwing.
  return;
}
```

`getStorageIfSupported()` only checks platform/package support. It does **not**
mean biometric authentication is currently available. Use it after you have
already decided which login path to offer.

1. Read data

```dart
final data = await store.read();
```

1. Write data

```dart
const myNewData = 'Hello World';
await store.write(myNewData);
```

### Suggested login flow

For the UX described above:

- On app start:
  - call `isSupported()`
  - if `false`, go straight to regular login
  - if `true`, call `canAuthenticate()` or `canAuthenticateWithBiometrics()`
  - if biometrics are available, read from the protected store and let the
    platform prompt automatically
  - otherwise, fall back to regular login without error
- After regular login success:
  - if `isSupported()` is `true`, show a “Use biometrics next time” toggle
  - when enabled, write the login token / small secret to a biometric-backed
    store for next launch

### Example: correct startup gating

```dart
final storage = BiometricStorage();

if (!await storage.isSupported(options: authOptions)) {
  // This platform cannot use biometric-backed storage at all.
  await showRegularLogin();
  return;
}

final authState = await storage.canAuthenticate(options: authOptions);
if (!authState.canAuthenticateWithBiometrics) {
  // Supported, but unavailable right now.
  // Example: macOS closed clamshell mode can land here.
  await showRegularLogin();
  return;
}

final store = await storage.getStorageIfSupported(
  'auth-token',
  options: authOptions,
);

final token = await store?.read();
if (token != null) {
  await signInWithStoredToken(token);
} else {
  await showRegularLogin();
}
```

### Example: opt-in after password login

```dart
final storage = BiometricStorage();

if (await storage.isSupported(options: authOptions)) {
  // Show a toggle such as "Use Touch ID / Face ID next time".
  final enabled = await askUserToEnableBiometricLogin();
  if (enabled) {
    final store = await storage.getStorage(
      'auth-token',
      options: authOptions,
    );
    await store.write(tokenFromSuccessfulPasswordLogin);
  }
}
```

This workflow avoids a common integration bug:

- `isSupported() == true` means “this device/platform can use the feature”
- `canAuthenticateWithBiometrics() == true` means “you can offer the biometric
  login path right now”

See also the API documentation:
<https://pub.dev/documentation/webauthn_secure_storage/latest/webauthn_secure_storage/BiometricStorageFile-class.html#instance-methods>
