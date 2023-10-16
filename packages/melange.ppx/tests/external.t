mel.as attribute

  $ cat > input.ml << EOF
  > type t
  > external document: t = "document"
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type t
  
  let (document : t) =
    raise (Failure "called Melange external \"mel.\" from native")

  $ ocamlc output.ml
