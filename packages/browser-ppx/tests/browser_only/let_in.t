The `let%browser_only x = ... in body` form transforms each binding's RHS
while preserving the body of the let-in unchanged.

  $ cat > input.ml << EOF
  > let make () =
  >   let%browser_only inner_handler arg = ignore arg in
  >   let%browser_only setup ~mode value = ignore (mode, value) in
  >   ignore (inner_handler, setup);
  >   ()
  > EOF

With -js, the bindings are preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let inner_handler arg = ignore arg in
    let setup ~mode value = ignore (mode, value) in
    ignore (inner_handler, setup);
    ()

Without -js, each binding's RHS is replaced with a let-chain + raise. The
body of the surrounding let-in is preserved untouched.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let make () =
    let inner_handler arg =
      let _ = arg in
      let _ = ignore in
      Runtime.fail_impossible_action_in_ssr "inner_handler"
        [@@alert "-browser_only"] [@@warning "-26-27-32-33"]
    in
    let setup ~mode value =
      let _ = mode in
      let _ = value in
      let _ = ignore in
      Runtime.fail_impossible_action_in_ssr "setup"
        [@@alert "-browser_only"] [@@warning "-26-27-32-33"]
    in
    ignore (inner_handler, setup);
    ()

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
