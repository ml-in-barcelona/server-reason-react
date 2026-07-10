#!/bin/sh
# Generates a per-function compatibility README for a universal-stdlib package
# (packages/Js or packages/Belt) by merging three inputs:
#
#   1. melange-surface.tsv — Melange's API surface (see extract_melange_surface.sh)
#   2. the package sources — which functions exist, and which are raising stubs
#      (detected mechanically via `notImplemented`)
#   3. status.tsv — hand-maintained annotations:
#        <Module.fn | Module.*> \t <green|orange|wontfix|planned> \t <note>
#      green   = implemented and verified by tests whose expectations cite a JS
#                source (melange test suite, test262, documented JS output)
#      orange  = implemented with a known behavioral divergence (note required)
#      wontfix = raising stub kept by design (note required)
#      planned = raising stub with a specific plan (note replaces "Planned.")
#
# The script hard-fails on contradictions between status.tsv and the code, so
# the generated table cannot lie about what raises.
#
# Usage: generate_status_readme.sh <Js|Belt> <src-subdir>   (run from the package dir)
# Output: README.md content on stdout.

set -eu
export LC_ALL=C

pkg="$1"
srcdir="$2"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- module name from file basename --------------------------------------
module_of_file() {
  base="$1"
  case "$pkg" in
    Js)
      case "$base" in
        Js) echo "Js"; return ;;
        Js_internal) echo ""; return ;;
      esac
      m=$(echo "$base" | sed 's/^Js_//')
      case "$m" in
        weakmap) m=WeakMap ;;
        weakset) m=WeakSet ;;
        formdata) m=FormData ;;
        typed_array) m=Typed_array ;;
        typed_array2) m=TypedArray2 ;;
        *) m=$(echo "$m" | awk '{ print toupper(substr($0,1,1)) substr($0,2) }') ;;
      esac
      echo "Js.$m"
      ;;
    Belt)
      case "$base" in
        Belt) echo "Belt"; return ;;
        Belt_internal*) echo ""; return ;;
      esac
      echo "$base" | sed \
        -e 's/^Belt_//' \
        -e 's/^\(HashMap\|HashSet\|MutableMap\|MutableSet\|SortArray\|Map\|Set\)\(Int\|String\|Dict\)$/\1.\2/' \
        -e 's/^/Belt./'
      ;;
  esac
}

# --- our surface: <Module>\t<fn> from .mli files --------------------------
: >"$tmp/ours.tsv"
for f in "$srcdir"/*.mli; do
  case "$f" in *.pp.mli) continue ;; esac
  mod=$(module_of_file "$(basename "$f" .mli)")
  [ -z "$mod" ] && continue
  awk -v mod="$mod" '
    {
      if (depth == 0 && $0 ~ /^(val|external)[ \t]/) {
        name = $2
        sub(/[:=(].*$/, "", name)
        if (name ~ /^[a-z_][a-zA-Z0-9_'\'']*$/ && name != "_") printf "%s\t%s\n", mod, name
      }
      line = $0
      while (match(line, /\(\*|\*\)/)) {
        if (substr(line, RSTART, 2) == "(*") depth++
        else if (depth > 0) depth--
        line = substr(line, RSTART + 2)
      }
    }
  ' "$f" >>"$tmp/ours.tsv"
done

# --- stubs: <Module>\t<fn> for top-level bindings that raise --------------
: >"$tmp/stubs.tsv"
for f in "$srcdir"/*.ml; do
  case "$f" in *.pp.ml) continue ;; esac
  mod=$(module_of_file "$(basename "$f" .ml)")
  [ -z "$mod" ] && continue
  awk -v mod="$mod" '
    {
      if (depth == 0 && $0 ~ /^(let|external)[ \t]/) {
        name = $2
        if (name == "rec") name = $3
        sub(/[:=(].*$/, "", name)
        current = (name ~ /^[a-z_][a-zA-Z0-9_'\'']*$/ && name != "_") ? name : ""
      }
      if (depth == 0 && $0 ~ /notImplemented/ && current != "") {
        printf "%s\t%s\n", mod, current
        current = ""
      }
      line = $0
      while (match(line, /\(\*|\*\)/)) {
        if (substr(line, RSTART, 2) == "(*") depth++
        else if (depth > 0) depth--
        line = substr(line, RSTART + 2)
      }
    }
  ' "$f" >>"$tmp/stubs.tsv"
done

# --- merge + validate -> rows --------------------------------------------
awk -F'\t' -v pkg="$pkg" '
  FILENAME ~ /melange-surface/ {
    if ($0 ~ /^#/) { if (match($0, /melange [^ ]+/)) mel_version = substr($0, RSTART + 8, RLENGTH - 8); next }
    melange[$1 SUBSEP $2] = 1
    if ($2 != "(module)") melange_fns[$1] = 1
    mods[$1] = 1; next
  }
  FILENAME ~ /ours\.tsv/   { ours[$1 SUBSEP $2] = 1; ours_mod[$1] = 1; mods[$1] = 1; next }
  FILENAME ~ /stubs\.tsv/  { stub[$1 SUBSEP $2] = 1; next }
  FILENAME ~ /status\.tsv/ {
    if ($0 ~ /^#/ || $0 == "") next
    if (NF < 2) { printf "error: status.tsv line %d: expected <key>\\t<status>[\\t<note>]\n", FNR > "/dev/stderr"; bad = 1; next }
    key = $1; st = $2; note = (NF >= 3) ? $3 : ""
    if (st != "green" && st != "orange" && st != "wontfix" && st != "planned") {
      printf "error: status.tsv: unknown status %s for %s\n", st, key > "/dev/stderr"; bad = 1; next
    }
    if ((st == "orange" || st == "wontfix") && note == "") {
      printf "error: status.tsv: %s entries require a note (%s)\n", st, key > "/dev/stderr"; bad = 1; next
    }
    ann_status[key] = st; ann_note[key] = note; ann_used[key] = 0; next
  }
  END {
    if (bad) exit 1
    print "@version\t" mel_version
    for (k in melange) { split(k, p, SUBSEP); emit(p[1], p[2]) }
    for (k in ours)    { split(k, p, SUBSEP); if (!(k in melange)) emit(p[1], p[2]) }
    for (key in ann_used)
      if (!ann_used[key]) {
        printf "error: status.tsv: %s does not match any known function or module\n", key > "/dev/stderr"
        err = 1
      }
    if (err) exit 1
  }
  function annotation(mod, fn,   key) {
    key = mod "." fn
    if (key in ann_status) { ann_used[key] = 1; note = ann_note[key]; return ann_status[key] }
    key = mod ".*"
    if (key in ann_status) { ann_used[key] = 1; note = ann_note[key]; return ann_status[key] }
    note = ""
    return ""
  }
  function emit(mod, fn,   k, st, in_mel, in_ours, is_stub, status, extra) {
    if (fn == "(module)") return
    k = mod SUBSEP fn
    in_mel = (k in melange); in_ours = (k in ours); is_stub = (k in stub)
    st = annotation(mod, fn)
    extra = in_mel ? "" : "Not in Melange " mel_version "."
    if (!in_ours && !is_stub) {
      if (st != "") {
        printf "error: status.tsv: %s.%s is not present in the sources\n", mod, fn > "/dev/stderr"; err = 1; return
      }
      printf "%s\t%s\t➖ missing\t\n", mod, fn
      return
    }
    if (is_stub) {
      if (st == "green" || st == "orange") {
        printf "error: status.tsv: %s.%s marked %s but it is a raising stub\n", mod, fn, st > "/dev/stderr"; err = 1; return
      }
      if (st == "wontfix") status = "🔴 raises by design"
      else { status = "🔴 stub"; note = (note == "" ? "Planned." : note) }
    } else {
      if (st == "wontfix" || st == "planned") {
        printf "error: status.tsv: %s.%s marked %s but it is implemented\n", mod, fn, st > "/dev/stderr"; err = 1; return
      }
      if (st == "green") status = "🟢"
      else if (st == "orange") status = "🟠"
      else status = "⚪️"
    }
    if (note != "" && extra != "") extra = " " extra
    printf "%s\t%s\t%s\t%s%s\n", mod, fn, status, note, extra
  }
' melange-surface.tsv "$tmp/ours.tsv" "$tmp/stubs.tsv" status.tsv >"$tmp/rows.tsv"

version=$(awk -F'\t' '$1 == "@version" { print $2; exit }' "$tmp/rows.tsv")
grep -v "^@version" "$tmp/rows.tsv" | sort -t "$(printf '\t')" -k1,1 -k2,2 >"$tmp/sorted.tsv"

# --- render ----------------------------------------------------------------
awk -F'\t' -v pkg="$pkg" -v version="$version" '
  BEGIN {
    lib = (pkg == "Js") ? "server-reason-react.js" : "server-reason-react.belt"
    print "# `" lib "` — `" pkg "` compatibility status"
    print ""
    print "<!-- Generated by scripts/status/generate_status_readme.sh via dune; do not edit. -->"
    print ""
    print "Per-function status of the native `" pkg "` implementation against Melange " version "."
    print ""
    print "| Status | Meaning |"
    print "| --- | --- |"
    print "| 🟢 | Implemented, verified by tests whose expectations cite a JS source (Melange test suite, test262, or documented JS output). |"
    print "| ⚪️ | Implemented, not yet verified against JS behavior. |"
    print "| 🟠 | Implemented with a known behavioral divergence (see note). |"
    print "| 🔴 stub | Raises `Impossible_in_ssr` at runtime. Planned unless noted otherwise. |"
    print "| 🔴 raises by design | Intentionally unsupported on the server (see note). |"
    print "| ➖ missing | Present in Melange, absent here. |"
    print ""
  }
  { rows[NR] = $0; count[$1]++ }
  END {
    # summary
    print "## Summary"
    print ""
    print "| Module | 🟢 | ⚪️ | 🟠 | 🔴 | ➖ |"
    print "| --- | --- | --- | --- | --- | --- |"
    for (i = 1; i <= NR; i++) {
      split(rows[i], f, "\t")
      mod = f[1]; s = f[3]
      if (s == "🟢") g[mod]++
      else if (s == "⚪️") w[mod]++
      else if (s == "🟠") o[mod]++
      else if (s ~ /^🔴/) r[mod]++
      else m[mod]++
      if (!(mod in seen)) { order[++n] = mod; seen[mod] = 1 }
    }
    for (i = 1; i <= n; i++) {
      mod = order[i]
      printf "| [%s](#%s) | %d | %d | %d | %d | %d |\n", mod, anchor(mod), g[mod], w[mod], o[mod], r[mod], m[mod]
    }
    print ""
    # per-module tables
    prev = ""
    for (i = 1; i <= NR; i++) {
      split(rows[i], f, "\t")
      if (f[1] != prev) {
        print "## " f[1]
        print ""
        print "| Function | Status | Notes |"
        print "| --- | --- | --- |"
        prev = f[1]
      }
      printf "| `%s` | %s | %s |\n", f[2], f[3], f[4]
      if (i == NR || substr(rows[i + 1], 1, length(f[1]) + 1) != f[1] "\t") print ""
    }
  }
  function anchor(s) { gsub(/\./, "", s); return tolower(s) }
' "$tmp/sorted.tsv"
