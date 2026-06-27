#!/usr/bin/env bash
# Agent implementation step — reads SPEC_JSON env var, applies changes, runs verification.
set -euo pipefail

cd "${REPO_DIR:-/home/daytona/workspace}"
SPEC_FILE="${SPEC_FILE:-/tmp/factory-spec.json}"

if [ ! -f "$SPEC_FILE" ]; then
  echo "SPEC_MISSING"
  exit 1
fi

BRANCH=$(node -e "const s=require('$SPEC_FILE'); console.log(s.branch || 'factory/poc')")
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# Agent writes files listed in spec.files — placeholder for LLM-generated patch step
node /tmp/factory-apply-spec.js "$SPEC_FILE" || {
  echo "APPLY_FAILED"
  exit 1
}

echo "==> Running verification"
if [ -f Makefile ] && grep -q '^test:' Makefile; then
  make test
elif [ -f package.json ]; then
  npm test --if-present
elif [ -f go.mod ]; then
  go test ./... -count=1
else
  echo "No test runner found — skipping"
fi

echo "VERIFY_OK"
