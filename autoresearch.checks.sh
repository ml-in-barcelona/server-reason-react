#!/bin/bash
set -euo pipefail

opam exec -- dune runtest packages/reactDom >/dev/null
