# AGENTS.md — Software Factory

## Mission

Software Factory is a Node.js (>=20, zero-build) service that coordinates a
software delivery pipeline: its `app/` surface runs directly from source with
`node --watch`. Agents working here must keep the runtime dependency surface
near zero, keep tests runnable with the Node test runner only, and never ship
a step that cannot run offline in CI.

## Architecture

| Layer | Role | Do | Don't |
|-------|------|----|-------|
| `app/src/` | Service source + colocated `*.test.js` | Test with `node --test` | Add a build/transpile step |
| `app/` | Deployable service | Keep `npm start`/`npm run dev` working from source | Commit generated artifacts |
| `docs/` | Stack and webhook documentation | Update when behavior changes | Let docs drift from code |

## Engineering rules

### Non-negotiables

1. **Zero-build runtime** — the service runs from source on stock Node >=20;
   no transpiler, no bundler in the serve path.
2. **Node test runner only** — tests are `node --test src/**/*.test.js`;
   do not introduce a second test framework.
3. **Docs match behavior** — `docs/CUBICZAN_STACK.md` and
   `docs/RENDER_WEBHOOKS.md` must describe the code as it is.

### Propagation Matrix — Wave C rows

- **Row 21 (executable contracts) — adopted.** This file compiles under
  agent-conductor: the checklist below matches the parser's gate section and
  its commands execute as gates.
- **Row 23 (supply-chain discipline) — pending carrier.** The
  receipts/skills-lock/bundle-manifest kit extension lives in the archived
  `_cubiczan-shared` repo (push blocked); delivery waits on the
  owner-designated live `chp init` carrier. This file's contract + gates are
  the row-21 half, delivered now.

## Code change checklist

```bash
cd app && npm test
```
