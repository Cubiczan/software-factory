# SuperPlane Software Factory

**Hackathon theme:** [Build Your Own Software Factory](https://docs.google.com/document/d/151kAyQbpLdWKggWLMBPtjABEOaIN4h4gsBHOwthCN_s/edit) — turn a vague idea or GitHub issue into a working PoC overnight, with minimal human involvement.

See **[HACKATHON.md](./HACKATHON.md)** for validation issues, demo script, and judging alignment.

## What it does

```
Vague idea / GitHub issue #5368
        ↓
   LLM generates spec  →  validate
        ↓
   Daytona sandbox + LLM writes code  →  build/test gate
        ↓
   TITO MAESTRO security scan  →  security gate
        ↓
   PR opened → Render PR preview → live URL on PR
```

Targets **[superplanehq/superplane](https://github.com/superplanehq/superplane)** — the five hackathon validation issues (#5368, #5366, #5164, #5704, #5705).

## Architecture

| Layer | Tool | Role |
|-------|------|------|
| Orchestration | [SuperPlane](https://docs.superplane.com/) | Full factory pipeline on the canvas |
| LLM | OpenAI integration | Spec + implementation generation |
| Execution | Daytona | Sandbox clone, build verify |
| Preview hosting | [Render](https://dashboard.render.com/) | PR previews (`[render preview]` in PR title) |
| Security | [TITO](https://github.com/Leathal1/TITO) + [MAESTRO](https://cloudsecurityalliance.org/blog/2026/02/11/applying-maestro-to-real-world-agentic-ai-threat-models-from-framework-to-ci-cd-pipeline) | Agentic AI threat gate before PR |

## Quick start

### 1. SuperPlane CLI

```bash
curl -fsSL https://install.superplane.com/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

superplane connect https://app.superplane.com YOUR_API_TOKEN
superplane whoami
```

App already created in org **Cubiczan** (`Software Factory`). Update the canvas:

```bash
superplane apps drafts create "Software Factory"
superplane apps canvas update --draft-id <draft-id> -f superplane/canvas.yaml
```

### 2. Connect integrations

**Settings → Integrations** in SuperPlane:

| Integration | Purpose |
|-------------|---------|
| GitHub | Issues, PRs, preview comments |
| OpenAI | LLM spec + code steps |
| Daytona | Sandbox + build verify |
| Render | PR preview hosting ($50 credit) |

Copy IDs into `superplane/params.json`:

```bash
superplane integrations list -o yaml
```

### 4. Render ($50 credit)

```bash
./scripts/setup-render.sh
```

1. [dashboard.render.com](https://dashboard.render.com/) → **New → Blueprint** → connect this repo
2. **software-factory** service → **Previews** → **Manual** PR previews
3. SuperPlane → Integrations → **Render** (API key; webhooks auto-register — see [docs/RENDER_WEBHOOKS.md](./docs/RENDER_WEBHOOKS.md))
4. Verify webhook at [dashboard.render.com/webhooks](https://dashboard.render.com/webhooks)

### 5. TITO locally (optional)

```bash
./scripts/run-tito-local.sh .
```

## Project layout

```
superplane/
  canvas.yaml              # Hackathon-aligned factory workflow
  console.yaml             # Dashboard with validation issues
  params.json              # Repo + integration IDs
  validation-issues.json   # The 5 judging issues
  scripts/                 # Sandbox bootstrap + apply helpers
.github/workflows/
  tito-maestro.yml         # CI MAESTRO gate on PRs
  render-preview.yml       # Posts Render PR preview URL
render.yaml                # Render Blueprint (starter plan)
HACKATHON.md               # Theme checklist + demo script
```

## References

- [Hackathon brief](https://docs.google.com/document/d/151kAyQbpLdWKggWLMBPtjABEOaIN4h4gsBHOwthCN_s/edit)
- [SuperPlane CLI](https://docs.superplane.com/cli/overview/)
- [TITO](https://github.com/Leathal1/TITO) · [MAESTRO blog](https://cloudsecurityalliance.org/blog/2026/02/11/applying-maestro-to-real-world-agentic-ai-threat-models-from-framework-to-ci-cd-pipeline)
