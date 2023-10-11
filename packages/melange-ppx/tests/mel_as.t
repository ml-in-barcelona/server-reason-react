mel.as attribute
  $ cat > input.ml << EOF
  > external get : t -> (_[@mel.as {json|{}|json}]) -> t = "get" [@@mel.send]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (get : t -> (_[@mel.as {json|{}|json}]) -> t) =
   fun _ -> raise (Failure "called Melange external \"mel.\" from native")
