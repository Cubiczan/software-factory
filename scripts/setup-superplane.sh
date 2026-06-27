#!/usr/bin/env bash
set -euo pipefail

# Connect SuperPlane CLI and deploy the Software Factory app.
# Usage: ./scripts/setup-superplane.sh <API_TOKEN> [ORG_URL]

TOKEN="${1:-}"
URL="${2:-https://app.superplane.com}"

if [[ -z "$TOKEN" ]]; then
  echo "Usage: $0 <SUPERPLANE_API_TOKEN> [SUPERPLANE_URL]"
  echo ""
  echo "Get your token: SuperPlane UI → Profile → API token"
  echo "Account: sam@cubiczan.com"
  exit 1
fi

export PATH="$HOME/.local/bin:$PATH"

if ! command -v superplane &>/dev/null; then
  echo "Installing SuperPlane CLI..."
  curl -fsSL https://install.superplane.com/install.sh | sh
fi

echo "Connecting to SuperPlane..."
superplane connect "$URL" "$TOKEN"
superplane whoami

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Creating Software Factory app..."
superplane apps create \
  --canvas-file "$ROOT/superplane/canvas.yaml" \
  --name "Software Factory"

APP_ID=$(superplane apps list -o json | node -e "
  const apps = JSON.parse(require('fs').readFileSync(0,'utf8'));
  const app = apps.find(a => a.name === 'Software Factory') || apps[apps.length-1];
  console.log(app?.id || app?.name || '');
")

if [[ -z "$APP_ID" ]]; then
  echo "Could not resolve app id. List apps manually: superplane apps list"
  exit 1
fi

superplane apps active "$APP_ID"

echo "Setting console..."
superplane apps console set "$APP_ID" --file "$ROOT/superplane/console.yaml" || true

echo ""
echo "Done. Open your app in SuperPlane:"
echo "  $URL → Apps → Software Factory"
echo ""
echo "Next steps:"
echo "  1. Connect GitHub integration in SuperPlane UI"
echo "Update superplane/params.json with integration IDs from:"
echo "  superplane integrations list -o yaml"
echo ""
echo "Required: GitHub, OpenAI, Daytona"
echo "Target repo: superplanehq/superplane (hackathon validation issues)"
