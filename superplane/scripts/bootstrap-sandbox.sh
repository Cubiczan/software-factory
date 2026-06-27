#!/usr/bin/env bash
# Bootstrap script run inside Daytona sandbox after cloning the target repo.
set -euo pipefail

cd "${REPO_DIR:-/home/daytona/workspace}"

echo "==> Installing toolchain dependencies"
if [ -f package.json ]; then
  npm ci --ignore-scripts 2>/dev/null || npm install --ignore-scripts 2>/dev/null || true
fi

if command -v go >/dev/null 2>&1 && [ -f go.mod ]; then
  go mod download 2>/dev/null || true
fi

echo "BOOTSTRAP_OK"
