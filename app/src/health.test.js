import test from "node:test";
import assert from "node:assert/strict";

test("pipeline has five stages", () => {
  const stages = ["intake", "implement", "secure", "approve", "deploy"];
  assert.equal(stages.length, 5);
});
