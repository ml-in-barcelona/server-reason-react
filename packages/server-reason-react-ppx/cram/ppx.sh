#!/bin/bash

set -eo pipefail

function usage() {
  echo "Usage: $(basename "$0") --output re [file.re]"
  echo "       $(basename "$0") --output ml [file.re]"
  echo "       $(basename "$0") --output re -js [file.re]"
  echo "       $(basename "$0") --output ml -js [file.re]"
}

js_flag=""
output_format=""
input_file=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --output)
      output_format="$2"
      shift 2
      ;;
    -js)
      js_flag="-js"
      shift
      ;;
    *)
      input_file="$1"
      shift
      ;;
  esac
done

# Check required arguments
if [ -z "$output_format" ] || [ -z "$input_file" ]; then
  usage
  exit 1
fi

refmt --parse re --print ml "$input_file" > output.ml
./../standalone.exe --impl output.ml $js_flag -o temp.ml

if [ "$output_format" == "ml" ]; then
  ocamlformat --enable-outside-detected-project --impl temp.ml -o temp.ml
  cat temp.ml
  exit
elif [ "$output_format" == "re" ]; then
  refmt --parse ml --print re temp.ml
  exit
else
  usage
  exit 1
fi
