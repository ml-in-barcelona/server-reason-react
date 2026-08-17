#!/bin/bash
set -euo pipefail

root=$(git rev-parse --show-toplevel)
results=$(mktemp)
trap 'rm -f "$results"' EXIT

opam exec -- dune build --profile=release benchmark/streaming_payload_bench.exe
for _ in 1 2 3; do
  "$root/_build/default/benchmark/streaming_payload_bench.exe" >> "$results"
done

python3 - "$results" <<'PY'
import math
import statistics
import sys

samples = {}
with open(sys.argv[1], encoding="utf-8") as handle:
    for line in handle:
        if not line.startswith("METRIC "):
            continue
        name, value = line.removeprefix("METRIC ").strip().split("=", 1)
        samples.setdefault(name, []).append(float(value))

medians = {name: statistics.median(values) for name, values in samples.items()}
expected = {
    "ssr_sync_ops_per_sec",
    "ssr_async_ops_per_sec",
    "rsc_model_ops_per_sec",
    "rsc_html_async_ops_per_sec",
}
if medians.keys() != expected or any(len(values) != 3 for values in samples.values()):
    raise SystemExit(f"incomplete benchmark output: {samples}")

geomean = math.exp(sum(math.log(value) for value in medians.values()) / len(medians))
print(f"METRIC streaming_geomean_ops_per_sec={geomean:.2f}")
for name in sorted(medians):
    print(f"METRIC {name}={medians[name]:.2f}")
PY
