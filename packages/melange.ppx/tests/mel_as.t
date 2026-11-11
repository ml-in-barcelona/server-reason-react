mel.as attribute
  $ cat > input.ml << EOF
  > external get : t -> (_[@mel.as {json|{}|json}]) -> t = "get" [@@mel.send]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let get : t -> t = fun _ -> Runtime.fail_impossible_action_in_ssr "get"

mel.as as the first argument
  $ cat > input.ml << EOF
  > external first : (_[@mel.as "x"]) -> int -> unit = "first" [@@mel.send]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let first : int -> unit = fun _ -> Runtime.fail_impossible_action_in_ssr "first"

mel.as in the middle
  $ cat > input.ml << EOF
  > external middle : t -> (_[@mel.as 3]) -> int -> unit = "middle" [@@mel.send]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let middle : t -> int -> unit =
   fun _ _ -> Runtime.fail_impossible_action_in_ssr "middle"

mel.as as the last argument
  $ cat > input.ml << EOF
  > external last : t -> int -> (_[@mel.as "x"]) -> unit = "last" [@@mel.send]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let last : t -> int -> unit =
   fun _ _ -> Runtime.fail_impossible_action_in_ssr "last"

mel.as next to labelled arguments
  $ cat > input.ml << EOF
  > external labelled : x:int -> (_[@mel.as 3]) -> y:int -> unit -> unit = "labelled"
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let labelled : x:int -> y:int -> unit -> unit =
   fun ~x:_ ~y:_ _ -> Runtime.fail_impossible_action_in_ssr "labelled"

Labelled mel.as arguments are removed too
  $ cat > input.ml << EOF
  > external labelled_as : x:(_[@mel.as 3]) -> int -> unit = "labelled_as"
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let labelled_as : int -> unit =
   fun _ -> Runtime.fail_impossible_action_in_ssr "labelled_as"

Only mel.as arguments is an error
  $ cat > input.ml << EOF
  > external constants : (_[@mel.as "x"]) -> (_[@mel.as 3]) -> unit = "constants" [@@mel.send]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  [%%ocaml.error
  "[server-reason-react.melange_ppx] There's an external in native, which should \
   only happen in JavaScript. You need to conditionally discard it from the \
   native build, either by moving the external in a module only available in \
   native, or annotating it with [@melange_only]. More info at \
   https://github.com/ml-in-barcelona/ppx_platform"]

mel.as with mel.send.pipe
  $ cat > input.ml << EOF
  > external piped : (_[@mel.as "x"]) -> int -> unit = "piped" [@@mel.send.pipe: t]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let piped : int -> t -> unit =
   fun _ _ -> Runtime.fail_impossible_action_in_ssr "piped"
