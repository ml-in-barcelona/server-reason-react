Transform mel.obj into OCaml object literals

  $ cat > input.ml << EOF
  > let a = [%mel.obj { lola = 33; cositas = "hola"}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    object
      method lola = 33
      method cositas = "hola"
    end

  $ ocamlc -c output.ml

Fail if the object is not a record

  $ cat > input.ml << EOF
  > let a = [%mel.obj "hola"]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a = [%ocaml.error "%%mel.obj requires a record literal"]

  $ ocamlc -c output.ml
  File "output.ml", line 1, characters 10-21:
  1 | let a = [%ocaml.error "%%mel.obj requires a record literal"]
                ^^^^^^^^^^^
  Error: %%mel.obj requires a record literal
  [2]

Fail if the object is not a record

  $ cat > input.ml << EOF
  > let a = [%mel.obj { Lola.cositas = "hola"}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  File "input.ml", line 1, characters 18-42:
  1 | let a = [%mel.obj { Lola.cositas = "hola"}]
                        ^^^^^^^^^^^^^^^^^^^^^^^^
  Error: `%mel.obj' literals only support labels

  $ ocamlc -c output.ml
