  $ cat > input.ml << EOF
  > include struct
  >   type t = Js.Json.t
  > end [@@platform js]
  > 
  > include struct
  >   type t = string
  > end [@@platform native]
  > EOF

With -js flag it picks the block with `[@@platform js]`

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  include struct
    type t = Js.Json.t
  end [@@platform js]

Without -js flag, it picks the block with `[@@platform native]`

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  include struct
    type t = string
  end [@@platform native]
