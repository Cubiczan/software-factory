#!/usr/bin/env bash
# Create the github-token SuperPlane secret (required for upstream cross-fork PRs).
#
# Preferred: SuperPlane UI → Organization Settings → Secrets → Create
#   Name: github-token
#   Key:  token
#   Value: a GitHub PAT with `repo` scope (or `gh auth token` if scopes are sufficient)
#
# CLI format (provider enum varies by SuperPlane version — use UI if this fails):
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "Create secret 'github-token' with key 'token' in SuperPlane UI:"
echo "  Settings → Secrets → Create → name: github-token"
echo ""
echo "Generate a token:"
echo "  gh auth token   # if your gh session has repo scope"
echo "  # or: https://github.com/settings/tokens → Fine-grained → repo access"
echo ""
echo "Cross-fork PRs need permission to open PRs on superplanehq/superplane"
echo "from icohangar-ops/superplane branches (public fork → upstream)."
