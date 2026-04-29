Simplest case: single argument, body uses no free identifiers.

  $ cat > input.ml << EOF
  > let%browser_only greet name = name
  > EOF

With -js, the extension is removed and the binding is preserved as-is.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let greet name = name

Without -js, native code preserves the argument and references it via let _ = ...
to silence warning 27 (unused argument).

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let (greet
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun name ->
    let _ = name in
    Runtime.fail_impossible_action_in_ssr "greet")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

The generated code compiles cleanly with all warnings as errors. We compile
without the -27-32 suppression to prove the let-chain handles those warnings.

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
