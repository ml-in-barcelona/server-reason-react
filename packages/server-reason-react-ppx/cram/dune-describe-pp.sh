#!/bin/sh
set -eu

# Strip the leading [@ocaml.ppx.context ...] (Reason syntax, terminated by
# "];") or [@@@ocaml.ppx.context ...] (OCaml syntax, terminated by "}]")
# attribute block that "dune describe pp" prepends to its output.

dune describe pp "$@" | awk '
  body { print; next }
  skip { if ($0 ~ /^[[:space:]]*(\];|\}\])/) { skip = 0; body = 1 }; next }
  NR == 1 && /^[[:space:]]*\[@(@@)?ocaml\.ppx\.context/ { skip = 1; next }
  { body = 1; print }
'
