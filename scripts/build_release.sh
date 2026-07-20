#!/usr/bin/env bash
#
# Builds obfuscated release artifacts for JobAway (Flutter).
#
# Runs `flutter build` for APK and App Bundle (and optionally iOS) with Dart
# obfuscation enabled. Debug symbols are written to build/symbols/<version> so
# crash reports can later be de-symbolicated.
#
# IMPORTANT: the generated symbols (build/symbols/**) MUST be archived in a
# SAFE, PRIVATE location. They are required to de-obfuscate crash stack traces.
# They must NEVER be committed to a public repository. See docs/OBFUSCATION.md.
#
# Usage:
#   ./scripts/build_release.sh                 # apk + appbundle
#   ./scripts/build_release.sh apk appbundle ios
#   FLAVOR=prod ./scripts/build_release.sh apk
#
set -euo pipefail

# Resolve project root (parent of this scripts/ folder) and move there.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

TARGETS=("$@")
if [ ${#TARGETS[@]} -eq 0 ]; then
  TARGETS=(apk appbundle)
fi

# Read `version: x.y.z+n` from pubspec.yaml.
VERSION="$(grep -E '^[[:space:]]*version:' pubspec.yaml | head -1 | sed -E 's/^[[:space:]]*version:[[:space:]]*//' | tr -d '\r' || true)"
VERSION="${VERSION:-unknown}"

SYMBOLS_DIR="$PROJECT_ROOT/build/symbols/$VERSION"
mkdir -p "$SYMBOLS_DIR"

echo "========================================================="
echo " JobAway - Obfuscated release build"
echo " Version  : $VERSION"
echo " Targets  : ${TARGETS[*]}"
echo " Symbols  : $SYMBOLS_DIR"
echo "========================================================="

FLAVOR_ARGS=()
if [ -n "${FLAVOR:-}" ]; then
  FLAVOR_ARGS=(--flavor "$FLAVOR")
fi

COMMON=(--release --obfuscate "--split-debug-info=$SYMBOLS_DIR" "${FLAVOR_ARGS[@]}")

for target in "${TARGETS[@]}"; do
  echo ""
  echo "--> flutter build $target ${COMMON[*]}"
  flutter build "$target" "${COMMON[@]}"
done

echo ""
echo "========================================================="
echo " BUILD OK"
echo " Symbols written to: $SYMBOLS_DIR"
echo ""
echo " >>> ARCHIVE THESE SYMBOLS SAFELY (private storage). <<<"
echo "     They are needed to de-symbolicate crash reports."
echo "     Do NOT commit them to a public repo. See docs/OBFUSCATION.md"
echo "========================================================="
