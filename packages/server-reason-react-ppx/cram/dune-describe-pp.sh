#!/bin/sh
set -eu

dune describe pp "$@" | awk '
  body { print; next }
  skip { if ($0 ~ /^[[:space:]]*(\];|\}\])/) { skip = 0; body = 1 }; next }
  NR == 1 && /^[[:space:]]*\[@(@@)?ocaml\.ppx\.context/ { skip = 1; next }
  { body = 1; print }
'
