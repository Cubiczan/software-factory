#!/usr/bin/env bash
set -euo pipefail

# Run TITO locally with MAESTRO classification.
# Requires Go: go install github.com/Leathal1/TITO/v2/cmd/tito@latest

REPO="${1:-.}"
OUTPUT="${2:-threat-model.html}"

if ! command -v tito &>/dev/null; then
  echo "Installing TITO..."
  go install github.com/Leathal1/TITO/v2/cmd/tito@latest
fi

echo "Running TITO MAESTRO scan on $REPO ..."
tito scan \
  --repo "$REPO" \
  --maestro \
  --mitre \
  --attack-paths \
  --output "$OUTPUT"

echo "Report: $OUTPUT"
