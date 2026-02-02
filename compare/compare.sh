#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: compare.sh [--rsc|--ssg] path/to/input.re

Options:
  --rsc    Compare RSC payload output (default)
  --ssg    Compare SSG/HTML output
EOF
}

mode="rsc"
input=""

while [ $# -gt 0 ]; do
  case "$1" in
    --rsc)
      mode="rsc"
      shift
      ;;
    --ssg)
      mode="ssg"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [ -z "$input" ]; then
        input="$1"
        shift
      else
        echo "Unexpected argument: $1"
        usage
        exit 1
      fi
      ;;
  esac
done

if [ -z "$input" ]; then
  usage
  exit 1
fi

if [ ! -f "$input" ]; then
  echo "Input file not found: $input"
  exit 1
fi

if [ "${input##*.}" != "re" ]; then
  echo "Input must be a .re file"
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
templates_dir="$repo_root/compare/templates"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1"
    exit 1
  fi
}

require_cmd opam
require_cmd dune
require_cmd bun
require_cmd diff

bold="\033[1m"
green="\033[32m"
red="\033[31m"
cyan="\033[36m"
reset="\033[0m"

print_header() {
  printf "%b\n" "${bold}${cyan}==> $1${reset}"
}

print_ok() {
  printf "%b\n" "${green}$1${reset}"
}

print_err() {
  printf "%b\n" "${red}$1${reset}"
}

node_modules_dir="$repo_root/arch/server/node_modules"
if [ ! -d "$node_modules_dir" ]; then
  print_err "Missing ${node_modules_dir}. Run: (cd arch/server && bun install)"
  exit 1
fi

workdir="$(mktemp -d -p "$repo_root/compare" srr-compare.XXXXXX)"
cleanup() {
  if [ "${SRR_COMPARE_KEEP:-}" = "1" ]; then
    printf "%b\n" "${cyan}Keeping workdir: $workdir${reset}"
    return
  fi
  rm -rf "$workdir"
}
trap cleanup EXIT

cp "$input" "$workdir/App_js.re"
cp "$input" "$workdir/App_native.re"

cat > "$workdir/Entry_js.re" <<'EOF'
let app = <App_js />;
EOF

cat > "$workdir/Entry_native.re" <<'EOF'
let app = <App_native />;
EOF

cat "$templates_dir/dune-melange.template" "$templates_dir/dune-native.template" > "$workdir/dune"

ln -s "$repo_root/arch/server/node_modules" "$workdir/node_modules"

if [ "$mode" = "rsc" ]; then
  cp "$templates_dir/rsc-runner.js.template" "$workdir/runner.js"
  cp "$templates_dir/rsc-runner.ml.template" "$workdir/runner.ml"
else
  cp "$templates_dir/ssg-runner.js.template" "$workdir/runner.js"
  cp "$templates_dir/ssg-runner.ml.template" "$workdir/runner.ml"
fi

rel_workdir="${workdir#$repo_root/}"
build_dir="$workdir/_build"
pushd "$repo_root" >/dev/null
eval "$(opam env --switch="$repo_root" --set-switch)"
dune build --build-dir "$build_dir" @melange "$rel_workdir/runner.exe"
popd >/dev/null

build_root="$build_dir/default/$rel_workdir"
js_entry="$build_root/output/$rel_workdir/Entry_js.re.js"
if [ ! -f "$js_entry" ]; then
  js_entry="$build_root/output/$rel_workdir/Entry_js.js"
fi
if [ ! -f "$js_entry" ]; then
  js_entry="$build_root/output/Entry_js.re.js"
fi
if [ ! -f "$js_entry" ]; then
  js_entry="$build_root/output/Entry_js.js"
fi
if [ ! -f "$js_entry" ]; then
  print_err "Could not find melange output for Entry"
  exit 1
fi

native_exe="$build_root/runner.exe"
if [ ! -f "$native_exe" ]; then
  print_err "Could not find native executable"
  exit 1
fi

js_output="$workdir/js.output"
native_output="$workdir/native.output"

print_header "React.js output (${mode})"
if [ "$mode" = "rsc" ]; then
  if ! (cd "$workdir" && bun --conditions react-server "$workdir/runner.js" "$js_entry" > "$js_output"); then
    print_err "React.js run failed"
    exit 1
  fi
else
  if ! (cd "$workdir" && bun "$workdir/runner.js" "$js_entry" > "$js_output"); then
    print_err "React.js run failed"
    exit 1
  fi
fi
cat "$js_output"
printf "\n"

print_header "server-reason-react output (${mode})"
if ! "$native_exe" > "$native_output"; then
  print_err "Native run failed"
  exit 1
fi
cat "$native_output"
printf "\n"

diff_output="$workdir/output.diff"
if diff -u "$js_output" "$native_output" > "$diff_output"; then
  print_ok "Outputs match"
  exit 0
else
  print_err "Outputs differ"
  cat "$diff_output"
  exit 1
fi
