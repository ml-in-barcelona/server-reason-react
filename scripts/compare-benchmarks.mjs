// Render a markdown comparison between the current benchmark run and the
// cached baseline from main (github-action-benchmark external data format).
//
// Usage: node scripts/compare-benchmarks.mjs <bench_results.json> <benchmark-data.json>

import fs from 'node:fs';

const BENCHMARK_NAME = 'server-reason-react Benchmarks';
const NOISE_THRESHOLD = 5; // percent

const [currentPath, baselinePath] = process.argv.slice(2);

const current = JSON.parse(fs.readFileSync(currentPath, 'utf8'));

let baseline = null;
let baselineCommit = null;
if (baselinePath && fs.existsSync(baselinePath)) {
  const data = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
  const entries = data.entries?.[BENCHMARK_NAME];
  if (entries && entries.length > 0) {
    const last = entries[entries.length - 1];
    baseline = new Map(last.benches.map((b) => [b.name, b]));
    baselineCommit = last.commit?.id?.slice(0, 7);
  }
}

const formatValue = (value) =>
  value >= 1000
    ? Math.round(value).toLocaleString('en-US')
    : value.toLocaleString('en-US', { maximumFractionDigits: 2 });

const lines = ['## Benchmarks', ''];

if (!baseline) {
  lines.push('No baseline from `main` available yet, showing absolute values only.', '');
  lines.push('| Benchmark | ops/sec |');
  lines.push('| --- | ---: |');
  for (const bench of current) {
    lines.push(`| ${bench.name} | ${formatValue(bench.value)} |`);
  }
} else {
  lines.push(`Comparison against \`main\` (${baselineCommit ?? 'unknown'}). Higher is better.`, '');
  lines.push('| Benchmark | main (ops/sec) | PR (ops/sec) | Change |');
  lines.push('| --- | ---: | ---: | ---: |');
  for (const bench of current) {
    const base = baseline.get(bench.name);
    if (!base) {
      lines.push(`| ${bench.name} | – | ${formatValue(bench.value)} | new |`);
      continue;
    }
    const change = ((bench.value - base.value) / base.value) * 100;
    const marker =
      change >= NOISE_THRESHOLD ? '🟢' : change <= -NOISE_THRESHOLD ? '🔴' : '';
    const sign = change >= 0 ? '+' : '';
    lines.push(
      `| ${bench.name} | ${formatValue(base.value)} | ${formatValue(bench.value)} | ${sign}${change.toFixed(1)}% ${marker} |`,
    );
  }
  lines.push('');
  lines.push(
    `<sub>Changes within ±${NOISE_THRESHOLD}% are likely noise from the CI runner.</sub>`,
  );
}

process.stdout.write(lines.join('\n') + '\n');
