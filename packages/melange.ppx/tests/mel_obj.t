Transform mel.obj into OCaml object literals

  $ cat > input.ml << EOF
  > let a = [%mel.obj { lola = 33; cositas = "hola"}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    object
      method cositas = "hola"
      method lola = 33
    end

  $ ocamlc -c output.ml

Transform nested mel.obj into OCaml object literals

  $ cat > input.ml << EOF
  > let a = [%mel.obj { lola = 33; cositas = [%mel.obj { value = "hola" }]}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    object
      method cositas =
        object
          method value = "hola"
        end
  
      method lola = 33
    end

  $ ocamlc -c output.ml


Fail if the object is not a record

  $ cat > input.ml << EOF
  > let a = [%mel.obj "hola"]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    [%ocaml.error
      "[server-reason-react.melange_ppx] Js.t objects requires a record literal"]

  $ ocamlc -c output.ml
  File "output.ml", line 2, characters 4-15:
  2 |   [%ocaml.error
          ^^^^^^^^^^^
  Error: [server-reason-react.melange_ppx] Js.t objects requires a record
         literal
  [2]

Fail if the object is not a record

  $ cat > input.ml << EOF
  > let a = [%mel.obj { Lola.cositas = "hola"}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let a =
    [%ocaml.error
      "[server-reason-react.melange_ppx] Js.t objects only support labels as keys"]

  $ ocamlc -c output.ml
  File "output.ml", line 2, characters 4-15:
  2 |   [%ocaml.error
          ^^^^^^^^^^^
  Error: [server-reason-react.melange_ppx] Js.t objects only support labels as
         keys
  [2]
