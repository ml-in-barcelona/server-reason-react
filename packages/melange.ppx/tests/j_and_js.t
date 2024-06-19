Error out when finding `j` and `js` quoted strings (not supported in native)

  $ cat > input.ml << EOF
  > let a = {j|Foo|j}
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    [%ocaml.error
      "[server-reason-react.melange_ppx] `j` and `js` quoted strings are not \
       supported. Try to rewrite them as plain strings or alternatively use \
       Printf.sprintf (note this will increase the final JavaScript bundle size \
       on the Melange build)"]

  $ ocamlc -c output.ml
  File "output.ml", line 2, characters 4-15:
  2 |   [%ocaml.error
          ^^^^^^^^^^^
  Error: [server-reason-react.melange_ppx] `j` and `js` quoted strings are not
         supported. Try to rewrite them as plain strings or alternatively use
         Printf.sprintf (note this will increase the final JavaScript bundle
         size on the Melange build)
  [2]

  $ cat > input.ml << EOF
  > let a = {js|Foo|js}
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    [%ocaml.error
      "[server-reason-react.melange_ppx] `j` and `js` quoted strings are not \
       supported. Try to rewrite them as plain strings or alternatively use \
       Printf.sprintf (note this will increase the final JavaScript bundle size \
       on the Melange build)"]

  $ ocamlc -c output.ml
  File "output.ml", line 2, characters 4-15:
  2 |   [%ocaml.error
          ^^^^^^^^^^^
  Error: [server-reason-react.melange_ppx] `j` and `js` quoted strings are not
         supported. Try to rewrite them as plain strings or alternatively use
         Printf.sprintf (note this will increase the final JavaScript bundle
         size on the Melange build)
  [2]
