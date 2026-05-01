# Changelog

## 0.1.0

- Rebrand the federated plugin family from `biometric_storage` to
  `webauthn_secure_storage` across packages, folders, imports, docs, and
  platform metadata.
- Reset the fork changelog so future changes are tracked independently.
- Clean generated artifacts from the repository and refresh ignore rules for a
  cleaner Flutter package workspace.

### Data-migration note for Linux users

The libsecret schema name has changed from `"design.codeux.BiometricStorage"`
to `"dev.webauthn_secure_storage"`. Secrets written by the upstream
`biometric_storage` plugin will not be visible to this package; they remain in
the keyring under the old schema and must be re-written after upgrading.

There is no automatic migration. To migrate, read the value with the upstream
plugin before upgrading, then write it again using this package after upgrading.
