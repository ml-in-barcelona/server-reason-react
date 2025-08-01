Test cases on string interpolation, most of them imported from
https://github.com/melange-re/melange/blob/fb1466fed7d6e5aafd3ee266bbd4ec70c8fb857a/test/blackbox-tests/utf8-string-interp.t

  $ cat > input.ml <<EOF
  > let lola = "flores"
  > let () = print_endline {j| Hello, \$(lola)|j}
  > EOF
  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let lola = "flores"
  let () = print_endline (Stdlib.( ^ ) {js| Hello, |js} lola)
  $ ocaml output.ml
   Hello, flores

Variable that doesn't exist

  $ cat > input.ml <<EOF
  > let x = {j| Hello, \$(lola)|j}
  > EOF
  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let x = Stdlib.( ^ ) {js| Hello, |js} lola
The grepping is necessary because the error message is not consistent across OCaml versions from 5.1.1 to 5.2.0
  $ ocaml output.ml 2>&1 | grep "Error: Unbound value"
  [1]

Using invalid identifiers

  $ cat > input.ml <<EOF
  > let x = {j| Hello, \$()|j}
  > EOF
  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  File "input.ml", line 1, characters 19-22:
  1 | let x = {j| Hello, $()|j}
                         ^^^
  Error: `' is not a valid syntax of interpolated identifer

  $ cat > input.ml <<EOF
  > let x = {j| Hello, \$(   )|j}
  > EOF
  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  File "input.ml", line 1, characters 19-25:
  1 | let x = {j| Hello, $(   )|j}
                         ^^^^^^
  Error: `   ' is not a valid syntax of interpolated identifer

`{j| .. |j}` interpolation is strict about string arguments

  $ cat > input.ml <<EOF
  > let x =
  >   let y = 3 in
  >   {j| Hello, \$(y)|j}
  > EOF
  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let x =
    let y = 3 in
    Stdlib.( ^ ) {js| Hello, |js} y
The grepping is necessary because the error message is not consistent across OCaml versions from 5.1.1 to 5.2.0
  $ ocaml output.ml 2>&1 | grep "Error: This expression has type "
  [1]
