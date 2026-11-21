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

echo ">>> Building perf_profile.exe"
(cd "${REPO_ROOT}" && dune build "${EXE_REL}")
if [[ ! -x "${EXE}" ]]; then
    echo "Executable not found at ${EXE}" >&2
    exit 1
fi

mkdir -p "${OUT_DIR}"

if [[ -n "${SCENARIO}" ]]; then
    SCENARIOS=("${SCENARIO}")
else
    mapfile -t SCENARIOS < <("${EXE}" --list)
fi

echo ">>> Tool: ${TOOL}   Scenarios: ${SCENARIOS[*]}"
echo ">>> iters=${ITERS} warmup=${WARMUP}"
echo ">>> Output directory: ${OUT_DIR}"

run_callgrind() {
    local name="$1"
    local out="${OUT_DIR}/callgrind-${name}.out"
    local annot="${OUT_DIR}/callgrind-${name}.txt"
    echo ""
    echo "--- callgrind: ${name} ---"
    rm -f "${out}" "${annot}"
    valgrind --tool=callgrind \
        --callgrind-out-file="${out}" \
        --cache-sim=no \
        --collect-jumps=yes \
        --collect-systime=no \
        "${EXE}" --scenario "${name}" --warmup "${WARMUP}" --iters "${ITERS}" \
        > "${OUT_DIR}/callgrind-${name}.stdout" 2> "${OUT_DIR}/callgrind-${name}.stderr"

    callgrind_annotate \
        --threshold=99 \
        --auto=no \
        --context=0 \
        "${out}" > "${annot}" 2> "${OUT_DIR}/callgrind-${name}.annotate.stderr" || true

    echo ""
    echo "  Top 30 functions by Ir (instructions read):"
    awk '
        /^Ir[[:space:]]+file:function/ { in_fn = 1; next }
        in_fn && /^-+$/ { next }
        in_fn && NF == 0 { in_fn = 0; next }
        in_fn { print "  " $0 }
    ' "${annot}" | head -n 30
}

run_perf_stat() {
    local name="$1"
    local out="${OUT_DIR}/perf-stat-${name}.txt"
    echo ""
    echo "--- perf stat: ${name} ---"
    perf stat -r 3 \
        -e task-clock:u,cycles:u,instructions:u,branches:u,branch-misses:u,cache-references:u,cache-misses:u \
        "${EXE}" --scenario "${name}" --warmup "${WARMUP}" --iters "${ITERS}" \
        > "${OUT_DIR}/perf-stat-${name}.stdout" 2> "${out}" || true
    tail -n 20 "${out}"
}

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
