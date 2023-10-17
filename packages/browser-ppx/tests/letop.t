  $ cat > input.ml << EOF
  > [%%browser_only let ( let+ ) = (fun p f -> map f p : ('a, 'b) t -> ('a -> 'c) -> ('c, 'b) t)]
  > EOF

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let ( let+ ) = (fun p f -> map f p : ('a, 'b) t -> ('a -> 'c) -> ('c, 'b) t)
  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let ( let+ ) = (fun p f -> map f p : ('a, 'b) t -> ('a -> 'c) -> ('c, 'b) t)
