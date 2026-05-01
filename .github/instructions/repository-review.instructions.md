# Repository review instructions

This repository is a Flutter federated plugin workspace for `webauthn_secure_storage`.

## Review priorities

- Review the whole federated plugin family together, not as isolated packages.
- Treat package metadata, docs, platform implementations, and tests as one release surface.
- Prefer pointing out inconsistencies across packages over hyper-local style nits.
- Ignore generated artifacts and focus on committed source, package metadata, native plugin code, tests, and docs.

## Naming and compatibility guidance

- The package family has been rebranded from `biometric_storage` to `webauthn_secure_storage`.
- Snake_case package/module names should consistently use `webauthn_secure_storage`.
- Public Dart API names still intentionally use `BiometricStorage*` for compatibility unless a change explicitly introduces a migration path.
- Do not recommend renaming public Dart API symbols unless the review clearly calls out migration impact and compatibility strategy.
- Native plugin class names and pluginClass values must stay aligned across Dart pubspec metadata and native implementations.

## Platform expectations

- Android, Darwin, Linux, Windows, and Web implementations should stay behaviorally aligned where possible.
- Watch for leftover upstream branding in storage key prefixes, method channel names, namespaces, package names, podspecs, and README snippets.
- Be especially alert to publishing metadata (`homepage`, `publish_to`, versions, plugin declarations) drifting across packages.

## Validation expectations

When suggesting fixes, prefer recommendations that can be validated with the existing package-level commands used in this repo, especially:

- `flutter analyze` on touched packages
- `flutter test` for `webauthn_secure_storage`
- `flutter test` for `webauthn_secure_storage_web`

## Release-readiness lens

Prioritize feedback about:

- branding consistency
- API compatibility and migration risk
- publishing readiness
- native plugin wiring correctness
- platform-specific storage/security regressions
- documentation accuracy
