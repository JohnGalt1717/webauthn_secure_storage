# Changelog

## 0.1.0

- Rebrand the federated plugin family from `biometric_storage` to
  `webauthn_secure_storage` across packages, folders, imports, docs, and
  platform metadata.
- Reset the fork changelog so future changes are tracked independently.
- Clean generated artifacts from the repository and refresh ignore rules for a
  cleaner Flutter package workspace.

### Data-migration note for Linux users

The libsecret schema name for new writes is now `"dev.webauthn_secure_storage"`.
To preserve upgrade compatibility, reads, existence checks, and deletes also
fall back to the upstream schema `"design.codeux.BiometricStorage"` and the
legacy key prefix when needed.

Existing Linux secrets remain readable after upgrade. They will continue to use
the legacy schema until they are re-written with this package.

### Data-migration note for Apple platforms

New writes now use the keychain service `"flutter_webauthn_secure_storage"`.
To preserve upgrade compatibility, reads, existence checks, and deletes also
fall back to the upstream keychain service `"flutter_biometric_storage"` when
needed.

Existing iOS and macOS secrets remain readable after upgrade. They will move to
the new service only after being re-written with this package.
