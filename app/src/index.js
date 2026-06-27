import { createServer } from "node:http";

const PORT = Number(process.env.PORT || 3000);
const FACTORY_NAME = process.env.FACTORY_NAME || "Software Factory";

const pipeline = [
  { stage: "intake", label: "Feature Intake", tool: "SuperPlane" },
  { stage: "implement", label: "Implementation", tool: "Coding Agent / PR" },
  { stage: "secure", label: "MAESTRO Threat Model", tool: "TITO" },
  { stage: "approve", label: "Human Approval", tool: "SuperPlane" },
  { stage: "deploy", label: "Production Deploy", tool: "Render" },
];

function html() {
  const rows = pipeline
    .map(
      (s) =>
        `<tr><td>${s.stage}</td><td>${s.label}</td><td><code>${s.tool}</code></td></tr>`,
    )
    .join("");

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${FACTORY_NAME}</title>
  <style>
    :root { font-family: system-ui, sans-serif; background: #0f1419; color: #e7ecf3; }
    body { max-width: 720px; margin: 2rem auto; padding: 0 1rem; }
    h1 { font-size: 1.5rem; }
    table { width: 100%; border-collapse: collapse; margin-top: 1.5rem; }
    th, td { text-align: left; padding: 0.6rem; border-bottom: 1px solid #2a3441; }
    code { background: #1a2332; padding: 0.15rem 0.4rem; border-radius: 4px; }
    .badge { display: inline-block; margin-top: 1rem; padding: 0.25rem 0.6rem;
      background: #1d4ed8; border-radius: 999px; font-size: 0.85rem; }
  </style>
</head>
<body>
  <h1>${FACTORY_NAME}</h1>
  <p>Automated feature production — SuperPlane orchestration, TITO/MAESTRO security, Render deploy.</p>
  <span class="badge">Hackathon demo</span>
  <table>
    <thead><tr><th>Stage</th><th>Step</th><th>Tool</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>
</body>
</html>`;
}

const server = createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok", factory: FACTORY_NAME }));
    return;
  }

  if (req.url === "/api/pipeline") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ name: FACTORY_NAME, pipeline }));
    return;
  }

  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(html());
});

server.listen(PORT, () => {
  console.log(`${FACTORY_NAME} listening on :${PORT}`);
});
