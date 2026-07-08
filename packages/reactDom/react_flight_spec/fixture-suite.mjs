// Check/write loop shared by generate.mjs and reply/generate-reply.mjs.
//
// Each generator provides:
//   cases:        [{ name, ... }]
//   fixturePath:  (case) => absolute path of the committed fixture
//   produce:      async (case) => fixture contents (string, trailing newline)
//   printDiff:    (case, committed, produced) => void — mismatch details
//   label:        human name for the summary line (e.g. "cases", "reply cases")
//   regenCommand: printed when --check finds stale fixtures
export async function runFixtureSuite({ cases, fixturePath, produce, printDiff, label, regenCommand, check }) {
  const fs = await import("node:fs");
  const path = await import("node:path");

  let failures = 0;
  let count = 0;

  for (const kase of cases) {
    count += 1;
    const file = fixturePath(kase);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    const produced = await produce(kase);

    if (check) {
      if (!fs.existsSync(file)) {
        console.error(`FAIL ${kase.name}: fixture missing (${file})`);
        failures += 1;
        continue;
      }
      const committed = fs.readFileSync(file, "utf8");
      if (committed !== produced) {
        failures += 1;
        console.error(`FAIL ${kase.name}: fixture out of date`);
        printDiff(kase, committed, produced);
      } else {
        console.log(`ok   ${kase.name}`);
      }
    } else {
      fs.writeFileSync(file, produced);
      console.log(`wrote ${path.relative(process.cwd(), file)}`);
    }
  }

  if (check && failures > 0) {
    console.error(`\n${failures}/${count} fixtures out of date. Run: ${regenCommand}`);
    process.exit(1);
  }
  console.log(`\n${count} ${label} ${check ? "checked" : "generated"} against react-server-dom-webpack.`);
}
