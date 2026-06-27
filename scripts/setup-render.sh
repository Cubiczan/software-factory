#!/usr/bin/env bash
# Render + webhook setup for Software Factory
set -euo pipefail

cat <<'EOF'
Render setup (https://dashboard.render.com/)
==========================================

1. CREATE BLUEPRINT
   Dashboard → New → Blueprint → connect superplane-software-factory repo

2. ENABLE PR PREVIEWS (manual — saves credit)
   software-factory → Previews → Manual
   Factory PRs use [render preview] in the title.

3. RENDER API KEY
   Account Settings → API Keys → Create

4. SUPERPLANE RENDER INTEGRATION (recommended — auto webhooks)
   SuperPlane → Settings → Integrations → Render
   - Paste API key
   - Workspace plan: Professional (webhooks require Pro+)
   - Select service: software-factory

   SuperPlane auto-registers webhooks via the Render API.
   Verify at: https://dashboard.render.com/webhooks
   You should see a SuperPlane-managed webhook for deploy_ended.

5. CANVAS WEBHOOK PATH
   The Software Factory canvas includes:
   - On Render Deploy (render.onDeploy) trigger
   - Filters deploy_ended + status succeeded
   - Posts live preview URL on the factory PR

   Copy integration + service IDs to superplane/params.json:
     render_integration_id
     render_service_id
     render_service_name

6. MANUAL WEBHOOK (alternative)
   If you prefer dashboard.render.com/webhooks directly:
   a) Add a generic Webhook trigger node in SuperPlane (or use render.onDeploy)
   b) Copy the SuperPlane webhook URL
   c) Dashboard → Integrations → Webhooks → + Create Webhook
   d) Events: deploy_ended (and optionally build_ended)
   e) URL: SuperPlane webhook endpoint

   Note: Using BOTH SuperPlane Render integration AND a manual webhook
   to the same endpoint can duplicate events — pick one approach.

7. GITHUB SECRET (for PR lookup in webhook path)
   SuperPlane app secret: github-token → token
   (Used to find the factory PR from deploy commit SHA)

8. FALLBACK CI
   .github/workflows/render-preview.yml polls GitHub Deployments
   if webhooks are slow or unavailable.

Credit budget (~$50):
  - Starter base service ≈ $7/mo
  - PR previews prorated, deleted when PR closes
  - Manual PR previews only

Webhooks docs: https://render.com/docs/webhooks
Dashboard:      https://dashboard.render.com/webhooks

EOF
