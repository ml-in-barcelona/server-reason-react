#!/usr/bin/env bash
# CPU-cycle profiler driver for SSR rendering.
#
# Orchestrates external profilers around perf_profile.exe and aggregates
# their output into a ranked site table. Parallel companion to the
# allocation-attribution output of alloc_profile.exe.
#
# Supported profilers:
#
#   callgrind   Valgrind's cache-and-call simulator. Deterministic
#               instruction counts attributed to source locations. Default,
#               because numbers are reproducible run-to-run — suitable for
#               deciding between two candidate fixes.
#
#   perf-stat   Linux hardware-counter totals (cycles:u, instructions:u,
#               branches:u, branch-misses:u, cache-references:u,
#               cache-misses:u). Fast, noisy. Good for confirming a
#               callgrind-predicted win on real hardware. Gated on
#               /proc/sys/kernel/perf_event_paranoid and kernel.perf_*
#               sysctls; silently skips counters that return zero.
#
#   perf-record Sampled call graph, useful for building flamegraphs.
#               Not ranked in the output table — the stackcollapse output
#               goes to a file the user can feed to flamegraph.pl.
#
# Usage:
#
#   ./benchmark/perf-work/perf_profile.sh [--tool TOOL] [--scenario NAME]
#                                         [--iters N] [--warmup N] [--out DIR]
#
#   TOOL: callgrind | perf-stat | perf-record | all    (default: callgrind)
#
# Exit: non-zero only on driver or build errors. A profiler being absent
# or a hardware counter being gated is reported and the remaining tools
# still run.

set -euo pipefail

# Some Linux environments (containers, sandboxes) inherit a very high
# RLIMIT_NOFILE from the init process. Valgrind asserts when the soft fd
# limit exceeds its compiled-in cap (see m_libcfile.c:vgPlain_safe_fd).
# Lower the soft limit before invoking valgrind. Harmless for perf.
# This is a well-known workaround documented in
# https://bugs.kde.org/show_bug.cgi?id=465000.
ulimit -n 1024 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
EXE_REL="_build/default/benchmark/perf-work/perf_profile.exe"
EXE="${REPO_ROOT}/${EXE_REL}"

TOOL="callgrind"
SCENARIO=""
ITERS=500
WARMUP=50
OUT_DIR="${REPO_ROOT}/benchmark/perf-work/cycles-out"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tool) TOOL="$2"; shift 2 ;;
        --scenario) SCENARIO="$2"; shift 2 ;;
        --iters) ITERS="$2"; shift 2 ;;
        --warmup) WARMUP="$2"; shift 2 ;;
        --out) OUT_DIR="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,40p' "$0"
            exit 0
            ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done

# ---------------------------------------------------------------------------
# Build

echo ">>> Building perf_profile.exe"
(cd "${REPO_ROOT}" && dune build "${EXE_REL}")
if [[ ! -x "${EXE}" ]]; then
    echo "Executable not found at ${EXE}" >&2
    exit 1
fi

mkdir -p "${OUT_DIR}"

# ---------------------------------------------------------------------------
# Scenario list

if [[ -n "${SCENARIO}" ]]; then
    SCENARIOS=("${SCENARIO}")
else
    # Read from the binary's own --list so the shell script and OCaml never
    # drift apart.
    mapfile -t SCENARIOS < <("${EXE}" --list)
fi

echo ">>> Tool: ${TOOL}   Scenarios: ${SCENARIOS[*]}"
echo ">>> iters=${ITERS} warmup=${WARMUP}"
echo ">>> Output directory: ${OUT_DIR}"

# ---------------------------------------------------------------------------
# callgrind driver
#
# --instr-atstart=no defers all instrumentation until we toggle on. The
# --toggle-collect glob matches every specialisation of the OCaml
# renderToStaticMarkup symbol — each iteration enters and exits the match,
# so warmup iterations are captured too. That's fine; warmup's share of
# total instructions is (warmup / (warmup+iters)), typically <10% of the
# steady state, and callgrind's absolute counts are more informative than
# per-iter averages for ranking hypotheses.
#
# --cache-sim=no: we only want call counts and Ir (instructions read),
# not cache simulation. Cache simulation triples runtime and the numbers
# are not meaningful on a virtualized host anyway.
#
# --collect-jumps=yes: branch-target attribution. Helpful later for
# locating where variant-dispatch branch-misses accumulate.
#
# callgrind_annotate post-processes into a flat source-location table.

run_callgrind() {
    local name="$1"
    local out="${OUT_DIR}/callgrind-${name}.out"
    local annot="${OUT_DIR}/callgrind-${name}.txt"
    echo ""
    echo "--- callgrind: ${name} ---"
    rm -f "${out}" "${annot}"
    # Flag rationale:
    #   --collect-atstart=no + --toggle-collect=SYMBOL gates *collection*
    #   to the render entry point. (--instr-atstart=no would skip
    #   instrumentation entirely, which also skips the symbol-name lookup
    #   that drives --toggle-collect, resulting in zero events — a subtle
    #   valgrind gotcha.)
    #   --cache-sim=no keeps runtime manageable; Ir alone is enough to rank.
    #   --collect-jumps=yes attributes branch-target data, useful for
    #   locating variant-dispatch cost later.
    valgrind --tool=callgrind \
        --callgrind-out-file="${out}" \
        --collect-atstart=no \
        --toggle-collect='camlReactDOM.renderToStaticMarkup_*' \
        --cache-sim=no \
        --collect-jumps=yes \
        --collect-systime=no \
        "${EXE}" --scenario "${name}" --warmup "${WARMUP}" --iters "${ITERS}" \
        > "${OUT_DIR}/callgrind-${name}.stdout" 2> "${OUT_DIR}/callgrind-${name}.stderr"

    # callgrind_annotate reads the most recent callgrind.out.<pid> if we don't
    # pass the file name; with an explicit name we point it at our output.
    callgrind_annotate \
        --threshold=99 \
        --auto=no \
        --context=0 \
        "${out}" > "${annot}" 2> "${OUT_DIR}/callgrind-${name}.annotate.stderr" || true

    # Extract the flat function-level attribution. callgrind_annotate emits
    # two tables: PROGRAM TOTALS, then "file:function". We want the second.
    # Locate the header line [Ir ... file:function] and print the
    # subsequent rows until the first blank line.
    echo ""
    echo "  Top 30 functions by Ir (instructions read):"
    awk '
        /^Ir[[:space:]]+file:function/ { in_fn = 1; next }
        in_fn && /^-+$/ { next }
        in_fn && NF == 0 { in_fn = 0; next }
        in_fn { print "  " $0 }
    ' "${annot}" | head -n 30
}

# ---------------------------------------------------------------------------
# perf stat driver
#
# We query user-space hardware counters. In containers with paranoid>=2,
# many counters are gated. perf prints "<not supported>" or zeros; we
# report that verbatim rather than hiding it — the user should know the
# ranking is degraded.
#
# -r 3: three runs, perf reports mean ± stddev. Three is a balance between
# signal (more runs = tighter CI) and the wall-clock cost of running every
# scenario. Raise with --perf-runs (future work).

run_perf_stat() {
    local name="$1"
    local out="${OUT_DIR}/perf-stat-${name}.txt"
    echo ""
    echo "--- perf stat: ${name} ---"
    perf stat -r 3 \
        -e task-clock:u,cycles:u,instructions:u,branches:u,branch-misses:u,cache-references:u,cache-misses:u \
        "${EXE}" --scenario "${name}" --warmup "${WARMUP}" --iters "${ITERS}" \
        > "${OUT_DIR}/perf-stat-${name}.stdout" 2> "${out}" || true
    # perf stat writes its counter table to stderr. Echo the tail of the
    # report for immediate feedback; the full run (with the 3-run stddev)
    # is in the file.
    tail -n 20 "${out}"
}

# ---------------------------------------------------------------------------
# perf record driver (sampled call graph)
#
# -F 997: sample at 997Hz (prime; avoids aliasing with the 1kHz scheduler
# tick). -g fp: frame-pointer call graph. OCaml compiled with the
# toolchain's default config keeps frame pointers on native amd64.
#
# We emit a perf.data and a scripted text dump so a flamegraph can be
# built later without re-running. We do NOT generate the flamegraph here
# — that would require stackcollapse-perf.pl + flamegraph.pl which are
# Perl scripts the user may or may not have installed.

run_perf_record() {
    local name="$1"
    local out="${OUT_DIR}/perf-record-${name}.data"
    local script="${OUT_DIR}/perf-record-${name}.script"
    echo ""
    echo "--- perf record: ${name} ---"
    perf record -F 997 -g --call-graph fp -o "${out}" \
        "${EXE}" --scenario "${name}" --warmup "${WARMUP}" --iters "${ITERS}" \
        > "${OUT_DIR}/perf-record-${name}.stdout" 2> "${OUT_DIR}/perf-record-${name}.stderr" || true
    perf script -i "${out}" > "${script}" 2>/dev/null || true
    echo "  data: ${out}"
    echo "  script: ${script}"
    echo "  (feed to stackcollapse-perf.pl + flamegraph.pl)"
}

# ---------------------------------------------------------------------------
# Dispatch

case "${TOOL}" in
    callgrind)
        command -v valgrind >/dev/null || { echo "valgrind not installed" >&2; exit 1; }
        command -v callgrind_annotate >/dev/null || { echo "callgrind_annotate not installed" >&2; exit 1; }
        for s in "${SCENARIOS[@]}"; do run_callgrind "$s"; done
        ;;
    perf-stat)
        command -v perf >/dev/null || { echo "perf not installed" >&2; exit 1; }
        for s in "${SCENARIOS[@]}"; do run_perf_stat "$s"; done
        ;;
    perf-record)
        command -v perf >/dev/null || { echo "perf not installed" >&2; exit 1; }
        for s in "${SCENARIOS[@]}"; do run_perf_record "$s"; done
        ;;
    all)
        for s in "${SCENARIOS[@]}"; do
            command -v valgrind >/dev/null && run_callgrind "$s" || echo "(callgrind skipped: valgrind not installed)"
            command -v perf >/dev/null && run_perf_stat "$s" || echo "(perf-stat skipped: perf not installed)"
        done
        ;;
    *)
        echo "Unknown tool: ${TOOL}" >&2
        echo "Supported: callgrind, perf-stat, perf-record, all" >&2
        exit 2
        ;;
esac

echo ""
echo ">>> Done. Output in ${OUT_DIR}"
