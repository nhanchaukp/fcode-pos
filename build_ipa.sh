#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo "==> Bump pub version (patch)"
pubversion patch

echo "==> Build Flutter IPA"
flutter build ipa

ARCHIVE_PRODUCTS_DIR="build/ios/archive/Runner.xcarchive/Products"
APPLICATIONS_DIR="$ARCHIVE_PRODUCTS_DIR/Applications"
PAYLOAD_DIR="$ARCHIVE_PRODUCTS_DIR/Payload"

if [[ ! -d "$APPLICATIONS_DIR" ]]; then
  echo "Khong tim thay thu muc: $APPLICATIONS_DIR"
  exit 1
fi

echo "==> Rename Applications -> Payload"
if [[ -d "$PAYLOAD_DIR" ]]; then
  rm -rf "$PAYLOAD_DIR"
fi
mv "$APPLICATIONS_DIR" "$PAYLOAD_DIR"

APP_VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
IPA_NAME="fcodepos.ipa"
IPA_TMP_ZIP="${IPA_NAME}.zip"

echo "==> Create IPA from Payload"
(
  cd "$ARCHIVE_PRODUCTS_DIR"
  zip -r "$IPA_TMP_ZIP" Payload >/dev/null
)

mv "$ARCHIVE_PRODUCTS_DIR/$IPA_TMP_ZIP" "$PROJECT_ROOT/$IPA_NAME"

echo "==> Done: $IPA_NAME"
