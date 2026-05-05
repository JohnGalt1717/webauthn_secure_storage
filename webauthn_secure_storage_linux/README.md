# webauthn_secure_storage

Federated Flutter plugin repository for `webauthn_secure_storage`.

The app-facing package combines:

- biometric-gated secure storage APIs
- WebAuthn / passkey DTOs for server challenge-response loops
- capability reporting for biometric storage, passkey authentication, and
    passkey PRF-backed storage

## Layout

- `webauthn_secure_storage/` — app-facing package, including the example app
- `webauthn_secure_storage_platform_interface/` — shared platform contract and types
- `webauthn_secure_storage_android/` — Android implementation
- `webauthn_secure_storage_darwin/` — iOS/macOS implementation
- `webauthn_secure_storage_linux/` — Linux implementation
- `webauthn_secure_storage_web/` — Web implementation
- `webauthn_secure_storage_windows/` — Windows implementation

The package you would publish and use directly lives in
`webauthn_secure_storage/`.

For package-specific usage and platform notes, see
`webauthn_secure_storage/README.md`.

## Notes

- This repository starts its independent changelog at `0.1.0`.
- Generated build output, lockfiles, and ephemeral Flutter artifacts are not
    kept in the repo.

## Acknowledgement

Thank you to the original `biometric_storage` package for the inspiration and
many of the code ideas that helped shape this fork.
