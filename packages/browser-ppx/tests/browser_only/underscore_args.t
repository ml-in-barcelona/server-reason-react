Arguments whose names start with `_` are skipped from the let-chain because
underscore-prefixed names are idiomatically "intentionally unused" in OCaml
and don't trigger warning 27.

  $ cat > input.ml << EOF
  > let%browser_only handler _event _options regular_arg =
  >   ignore regular_arg
  > EOF

With -js, the args are preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let handler _event _options regular_arg = ignore regular_arg

Without -js, only `regular_arg` is referenced; underscore-prefixed args
are skipped.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let (handler
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun _event _options regular_arg ->
    let _ = regular_arg in
    let _ = ignore in
    Runtime.fail_impossible_action_in_ssr "handler")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
