#!/usr/bin/env bash
# Verify the canvas target repo is reachable by the SuperPlane GitHub integration.
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PARAMS="$ROOT/superplane/params.json"

if ! command -v superplane &>/dev/null; then
  echo "SuperPlane CLI not found."
  exit 1
fi

TARGET=$(python3 -c "import json; print(json.load(open('$PARAMS'))['target_repository'])")
GITHUB_ID=$(superplane integrations list -o json | python3 -c "
import json, sys
for i in json.load(sys.stdin):
    if (i.get('metadata', {}).get('integrationName') or '').lower() == 'github':
        print(i['metadata']['id'])
        break
")

echo "Canvas target repository: $TARGET"
echo "GitHub integration id:    $GITHUB_ID"
echo ""

TARGET_REPO="$TARGET"
REPOS=$(superplane integrations list-resources --id "$GITHUB_ID" --type repository -o json)
export TARGET_REPO REPOS
python3 <<PY
import json, os, sys
target = os.environ["TARGET_REPO"]
repos = json.loads(os.environ["REPOS"])
names = {r.get("name") or r.get("value") for r in repos}
owner, _, name = target.partition("/")
short = name or target
if short in names:
    print(f"OK: '{target}' is in the GitHub app allowlist as '{short}' ({len(names)} repos).")
else:
    print(f"ERROR: '{target}' is NOT in the GitHub app allowlist (looked for resource name '{short}').")
    print()
    print("SuperPlane marks GitHub nodes as 'not connected' when the repository")
    print("on the node is outside the installed GitHub App's repository list —")
    print("even if the integration shows green in Settings.")
    print()
    print("Fix (pick one):")
    print("  1. Fork superplanehq/superplane to icohangar-ops/superplane, then add it at:")
    print("     https://github.com/settings/installations/142966808")
    print("     Update superplane/params.json → target_repository: icohangar-ops/superplane")
    print("  2. Ask superplanehq to install the SuperPlane GitHub app on their org")
    print("     and grant access to superplanehq/superplane.")
    print()
    print("Then re-run: ./scripts/push-superplane-draft.sh")
    sys.exit(1)
PY
