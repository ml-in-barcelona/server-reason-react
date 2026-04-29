When the body references outer let-bindings, the body itself is dropped on
native. The free identifiers (like `helper` here) are NOT referenced by the
generated let-chain \u2014 only function arguments are referenced.

If `helper` happens to be unused on native because of this, the user can add
`[@@warning "-32"]` on `helper`'s declaration, or define it under a
`[@platform js]` block.

  $ cat > input.ml << EOF
  > let helper x = x + 1
  > 
  > let%browser_only use_helper arg = helper arg
  > 
  > let _ = helper 0
  > EOF

With -js, everything is preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let helper x = x + 1
  let use_helper arg = helper arg
  let _ = helper 0

Without -js, the body of `use_helper` is replaced. `helper` is NOT referenced
in the generated code (we only reference function arguments, not body free
identifiers, to avoid breaking compilation when the body references
platform-restricted symbols).

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let helper x = x + 1
  
  let (use_helper
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun arg ->
    let _ = arg in
    let _ = helper in
    Runtime.fail_impossible_action_in_ssr "use_helper")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]
  
  let _ = helper 0

The generated code compiles cleanly with all warnings as errors.

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
