Labelled args with @@mel.send
  $ cat > input.ml << EOF
  > external init : string -> param:int -> string = "init" [@@mel.send]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (init : string -> param:int -> string) =
   fun _ ~param:_ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "init")

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Labelled and unlabelled args with @@mel.obj

  $ cat > input.ml << EOF
  > external makeInitParam : onLoad:string -> unit -> string = "" [@@mel.obj]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (makeInitParam : onLoad:string -> unit -> string) =
   fun ~onLoad:_ _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "makeInitParam")

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml


mel.send

  $ cat > input.ml << EOF
  > type t
  > external fillStyle : t -> 'a = "fillStyle" [@@mel.send]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type t
  
  let (fillStyle : t -> 'a) =
   fun _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "fillStyle")

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml
