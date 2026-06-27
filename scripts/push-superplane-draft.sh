#!/usr/bin/env bash
# Patch integration IDs into canvas.yaml and push to SuperPlane draft.
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CANVAS="$ROOT/superplane/canvas.yaml"
DRAFT_ID="${DRAFT_ID:-0c627973-632f-49af-844a-6c47722ce356}"
APP_ID="${APP_ID:-3c84e82e-e008-49f1-aff1-aaefbfe2033e}"

if ! command -v superplane &>/dev/null; then
  echo "SuperPlane CLI not found. Install: curl -fsSL https://install.superplane.com/install.sh | sh"
  exit 1
fi

echo "Fetching integrations..."
INTEGRATIONS=$(superplane integrations list -o json)

get_id() {
  local provider="$1"
  python3 -c "
import json, sys
items = json.loads('''$INTEGRATIONS''')
for i in items:
    p = (i.get('metadata', {}).get('integrationName') or i.get('integrationName') or i.get('provider') or i.get('name') or '').lower()
    if '$provider' in p:
        print(i.get('metadata', {}).get('id') or i.get('id', ''))
        break
"
}

GITHUB_ID=$(get_id github)
OPENAI_ID=$(get_id openai)
DAYTONA_ID=$(get_id daytona)
RENDER_ID=$(get_id render)

missing=0
for name in GITHUB OPENAI DAYTONA; do
  val_var="${name}_ID"
  val="${!val_var:-}"
  if [[ -z "$val" ]]; then
    echo "MISSING: $name integration — connect in SuperPlane UI → Settings → Integrations"
    missing=1
  else
    echo "OK $name: $val"
  fi
done

if [[ $missing -eq 1 ]]; then
  echo ""
  echo "Connect GitHub, OpenAI, and Daytona then re-run this script."
  exit 1
fi

RENDER_SERVICE_ID="${RENDER_SERVICE_ID:-$(python3 -c "import json; print(json.load(open('$ROOT/superplane/params.json')).get('render_service_id',''))")}"
TARGET_REPO=$(python3 -c "import json; print(json.load(open('$ROOT/superplane/params.json'))['target_repository'])")
UPSTREAM_REPO=$(python3 -c "import json; print(json.load(open('$ROOT/superplane/params.json')).get('upstream_repository','superplanehq/superplane'))")

echo "Checking GitHub repo access for: $TARGET_REPO"
GITHUB_REPOS=$(superplane integrations list-resources --id "$GITHUB_ID" --type repository -o json)
export TARGET_REPO GITHUB_REPOS
if ! python3 -c "
import json, os, sys
target = os.environ['TARGET_REPO']
repos = json.loads(os.environ['GITHUB_REPOS'])
names = {r.get('name') or r.get('value') for r in repos}
_, _, name = target.partition('/')
short = name or target
if short not in names:
    print('GitHub integration cannot access', target, '(resource name:', short + ')', file=sys.stderr)
    print('Run: ./scripts/check-github-canvas-repo.sh', file=sys.stderr)
    sys.exit(1)
"; then
  exit 1
fi

cp "$CANVAS" "$CANVAS.bak"
python3 <<PY
from pathlib import Path
import json
p = Path("$CANVAS")
text = p.read_text()
params = json.load(open("$ROOT/superplane/params.json"))
target = params["target_repository"]
fork_short = target.rsplit("/", 1)[-1]
render_svc = "$RENDER_SERVICE_ID"
repl = {
    "{{ install_params.github_integration_id }}": "$GITHUB_ID",
    "{{ install_params.openai_integration_id }}": "$OPENAI_ID",
    "{{ install_params.daytona_integration_id }}": "$DAYTONA_ID",
    "{{ install_params.render_integration_id }}": "$RENDER_ID",
    "{{ install_params.render_service_id }}": render_svc,
    "https://github.com/superplanehq/superplane.git": f"https://github.com/{target}.git",
}
if render_svc:
    text = text.replace('service: ""', f'service: "{render_svc}"')
for k, v in repl.items():
    text = text.replace(k, v)
p.write_text(text)
PY

echo "Pushing canvas..."
superplane apps active "$APP_ID"
DRAFT_JSON=$(superplane apps drafts list -o json 2>/dev/null || echo "null")
DRAFT_ID_LIVE=$(python3 -c "import json,sys; d=json.load(sys.stdin); print((d[0].get('metadata') or {}).get('id','') if isinstance(d,list) and d else '')" <<<"$DRAFT_JSON")
if [[ -n "$DRAFT_ID_LIVE" ]]; then
  echo "Updating draft $DRAFT_ID_LIVE..."
  superplane apps canvas update --draft-id "$DRAFT_ID_LIVE" -f "$CANVAS"
  DRAFT_ID="$DRAFT_ID_LIVE"
else
  echo "No draft found — updating live canvas."
  superplane apps canvas update -f "$CANVAS"
  DRAFT_ID=""
fi

echo "Pushing console..."
if [[ -n "${DRAFT_ID:-}" ]]; then
  superplane apps console set --file "$ROOT/superplane/console.yaml" --draft-id "$DRAFT_ID" || echo "Console upload skipped"
else
  superplane apps console set --file "$ROOT/superplane/console.yaml" || echo "Console upload skipped"
fi

echo ""
echo "Done. Open SuperPlane → Software Factory → Draft #1"
echo "Review node errors, then publish the draft."
