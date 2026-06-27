#!/usr/bin/env bash
# Audit the live SuperPlane canvas for configuration errors.
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_ID="${APP_ID:-3c84e82e-e008-49f1-aff1-aaefbfe2033e}"
PARAMS="$ROOT/superplane/params.json"

if ! command -v superplane &>/dev/null; then
  echo "SuperPlane CLI not found."
  exit 1
fi

superplane apps active "$APP_ID" >/dev/null
CANVAS_JSON=$(superplane apps canvas get -o json)
INTEGRATIONS=$(superplane integrations list -o json)
TARGET=$(python3 -c "import json; print(json.load(open('$PARAMS')).get('target_repository',''))")

export CANVAS_JSON INTEGRATIONS TARGET
python3 <<'PY'
import json, os, subprocess

canvas = json.loads(os.environ["CANVAS_JSON"])
integrations = json.loads(os.environ["INTEGRATIONS"])
target = os.environ.get("TARGET", "")
nodes = canvas.get("spec", {}).get("nodes", [])
edges = canvas.get("spec", {}).get("edges", [])
by_id = {i["metadata"]["id"]: i for i in integrations}

def list_resources(integ_id, rtype):
    r = subprocess.run(
        ["superplane", "integrations", "list-resources", "--id", integ_id, "--type", rtype, "-o", "json"],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        return []
    data = json.loads(r.stdout)
    return data if isinstance(data, list) else data.get("items", data.get("resources", []))

github = next((i for i in integrations if i["metadata"]["integrationName"] == "github"), None)
render = next((i for i in integrations if i["metadata"]["integrationName"] == "render"), None)
gh_repos = set()
render_services = []
if github:
    gh_repos = {r.get("name") or r.get("value") for r in list_resources(github["metadata"]["id"], "repository")}
if render:
    render_services = list_resources(render["metadata"]["id"], "service")

print("=" * 70)
print("SUPERPLANE CANVAS DEBUG REPORT")
print("=" * 70)
print(f"App: {canvas['metadata'].get('name')} ({canvas['metadata'].get('id')})")
print(f"Nodes: {len(nodes)}  Edges: {len(edges)}")
print(f"params.json target_repository: {target or '(not set)'}")
print()

print("## Integrations (Settings → Integrations)")
for i in integrations:
    m, st = i["metadata"], i.get("status", {})
    print(f"  {m.get('integrationName','?'):10}  state={st.get('state','?')}  id={m['id']}")
print()

issues = []
print("## Node errors (what the canvas UI is complaining about)")
found = False
for n in nodes:
    comp = n.get("component", "")
    cfg = n.get("configuration") or {}
    integ = (n.get("integration") or {}).get("id")
    node_issues = []

    if "github." in comp:
        repo = cfg.get("repository", "")
        short = repo.rsplit("/", 1)[-1] if repo else ""
        if not repo:
            node_issues.append("repository not set")
        elif short not in gh_repos:
            node_issues.append(
                f"repository '{repo}' not in GitHub App allowlist "
                f"({len(gh_repos)} repos on icohangar-ops) — UI shows 'GitHub not connected'"
            )

    if "render." in comp:
        svc = cfg.get("service")
        if not svc:
            node_issues.append("service id empty — set srv-... from Render dashboard")

    for e in cfg.get("environment") or []:
        if e.get("valueSource") == "secret":
            sec = (e.get("secret") or {}).get("secret")
            node_issues.append(f"needs SuperPlane secret '{sec}' at runtime (App → Secrets)")

    if node_issues:
        found = True
        issues.extend(node_issues)
        print(f"  ✗ {n.get('name')}  [{comp}]")
        print(f"    node id: {n.get('id')}")
        for msg in node_issues:
            print(f"    → {msg}")
        print()

if not found:
    print("  No issues detected by this audit.")
    print()

print("## Edge sanity")
node_ids = {n["id"] for n in nodes}
bad = [e for e in edges if e["sourceId"] not in node_ids or e["targetId"] not in node_ids]
if bad:
    for e in bad:
        print(f"  ✗ broken edge: {e}")
else:
    print("  ✓ all 28 edges reference valid nodes")
print()

print("## Fix checklist")
gh_bad = sum(
    1 for n in nodes
    if "github." in n.get("component", "")
    and (n.get("configuration") or {}).get("repository", "").rsplit("/", 1)[-1] not in gh_repos
)
render_bad = sum(1 for n in nodes if "render." in n.get("component", "") and not (n.get("configuration") or {}).get("service"))
print(f"  [{ ' ' if gh_bad else 'x'}] GitHub: {gh_bad}/4 nodes — fork + allowlist OR use a repo already on the app")
print(f"       https://github.com/settings/installations/142966808")
print(f"  [{ ' ' if render_bad else 'x'}] Render: {render_bad}/3 nodes — deploy render.yaml, copy srv-... to params.json")
print(f"  [ ] Secret: App → Secrets → github-token (for Lookup factory PR webhook path)")
if render_services:
    print()
    print("  Render services available:")
    for s in render_services:
        sid = s.get("id") or s.get("value") or "?"
        name = s.get("name") or sid
        print(f"    {name}  →  {sid}")
else:
    print("  (no Render services in integration yet — deploy Blueprint first)")
print()
print(f"Re-run after fixes: ./scripts/push-superplane-draft.sh")
PY
