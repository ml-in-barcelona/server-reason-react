  $ cat > input.ml << EOF
  > type keycloak
  > external keycloak : string -> keycloak = "default" [@@mel.module]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type keycloak
  
  let (keycloak : string -> keycloak) =
   fun _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "keycloak")

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Multiple args with optional

  $ cat > input.ml << EOF
  > type keycloak
  > external keycloak : ?z:int -> int -> foo:string -> keycloak = "default" [@@mel.module]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type keycloak
  
  let (keycloak : ?z:int -> int -> foo:string -> keycloak) =
   fun ?z:_ _ ~foo:_ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "keycloak")

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml

Single type (invalid OCaml, but valid in Melange)

  $ cat > input.ml << EOF
  > type keycloak
  > external keycloak : keycloak = "default" [@@mel.module "keycloak-js"]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type keycloak
  
  let ((keycloak : keycloak)
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
    Obj.magic ()

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml
