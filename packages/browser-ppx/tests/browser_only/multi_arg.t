All function arguments are preserved on native, and each is referenced via
`let _ = arg` to silence warning 27 (unused argument). This is the core fix:
previously only the first argument survived.

  $ cat > input.ml << EOF
  > let%browser_only fetch_with url options headers callback =
  >   Webapi.Dom.fetch url options headers callback
  > EOF

With -js, all four args are preserved unchanged.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let fetch_with url options headers callback =
    Webapi.Dom.fetch url options headers callback

Without -js, all four args are still preserved (this is the core fix), each
referenced by the let-chain.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let (fetch_with
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun url options headers callback ->
    let _ = url in
    let _ = options in
    let _ = headers in
    let _ = callback in
    Runtime.fail_impossible_action_in_ssr "fetch_with")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

The generated code compiles cleanly.

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
