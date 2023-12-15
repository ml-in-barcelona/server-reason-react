mel.as attribute

  $ cat > input.ml << EOF
  > type t
  > external document: t = "document"
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type t
  
  let (document : t) = Obj.magic ()

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml
