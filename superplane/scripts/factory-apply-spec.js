#!/usr/bin/env node
/**
 * Minimal spec applier — expects spec.files[] with path + content.
 * Real runs use LLM output parsed in the SuperPlane runnerJS node.
 */
import fs from "node:fs";

const specPath = process.argv[2];
if (!specPath) {
  console.error("Usage: factory-apply-spec.js <spec.json>");
  process.exit(1);
}

const spec = JSON.parse(fs.readFileSync(specPath, "utf8"));
const files = spec.files || [];

if (files.length === 0) {
  console.error("No files in spec — LLM must produce at least one file change");
  process.exit(1);
}

for (const file of files) {
  if (!file.path || typeof file.content !== "string") continue;
  fs.mkdirSync(file.path.split("/").slice(0, -1).join("/") || ".", { recursive: true });
  fs.writeFileSync(file.path, file.content);
  console.log("wrote", file.path);
}

console.log("APPLY_OK");
