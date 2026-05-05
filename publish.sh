#!/bin/bash
set -e

packages=(
  "webauthn_secure_storage_platform_interface"
  "webauthn_secure_storage_android"
  "webauthn_secure_storage_darwin"
  "webauthn_secure_storage_linux"
  "webauthn_secure_storage_web"
  "webauthn_secure_storage_windows"
  "webauthn_secure_storage"
)

for pkg in "${packages[@]}"; do
  echo "🚀 Publishing $pkg..."
  cd "$pkg"
  dart pub publish --force
  cd ..
done

echo "✅ All packages published successfully!"
