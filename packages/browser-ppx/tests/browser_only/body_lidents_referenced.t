Free unqualified identifiers in the body of a `let%browser_only` function
are referenced via `let _ = name` so warnings 26/27/32 don't fire on outer
let-bindings whose only use is inside the dropped body.

  $ cat > input.ml << EOF
  > let helper x = x + 1
  > 
  > let%browser_only use_helper arg =
  >   let local = helper arg in
  >   String.length (string_of_int local)
  > EOF

With -js, the binding is preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let helper x = x + 1
  
  let use_helper arg =
    let local = helper arg in
    String.length (string_of_int local)

Without -js, the body is replaced. `helper` (an outer Lident) and
`string_of_int` (a Stdlib Lident) are referenced via `let _ = ...`.
`local` is locally bound (inside the body) and NOT referenced. Qualified
paths like `String.length` are skipped.

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
    let _ = string_of_int in
    Runtime.fail_impossible_action_in_ssr "use_helper")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
