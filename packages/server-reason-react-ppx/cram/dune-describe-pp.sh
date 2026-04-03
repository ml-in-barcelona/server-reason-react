#!/bin/bash

set -euo pipefail

dune describe pp "$@" | perl -0pe 's/\A\s*\[\@(?:\@\@)?ocaml\.ppx\.context\b.*?(?:\n\s*\];|\n\s*\}\])\n?//ms'
