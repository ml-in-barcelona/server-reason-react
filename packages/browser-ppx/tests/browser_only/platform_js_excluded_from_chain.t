Names declared `[@platform js]` (or with another drop-on-native attribute)
are excluded from the let-chain even when they appear as free Lidents in
the body. Referencing them on native would fail to compile because the
binding is dropped by the platform filter.

  $ cat > input.ml << EOF
  > let regular_helper x = x + 1
  > 
  > let js_only_helper x = x * 2 [@@platform js]
  > 
  > let%browser_only use_helpers arg =
  >   let a = regular_helper arg in
  >   let b = js_only_helper arg in
  >   a + b
  > EOF

With -js, both helpers are preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let regular_helper x = x + 1
  let js_only_helper x = x * 2 [@@platform js]
  
  let use_helpers arg =
    let a = regular_helper arg in
    let b = js_only_helper arg in
    a + b

Without -js, `js_only_helper` is dropped from the structure. The let-chain
in `use_helpers` references `regular_helper` (a regular Lident) but NOT
`js_only_helper` (excluded by the pre-scan).

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let regular_helper x = x + 1
  
  let (use_helpers
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun arg ->
    let _ = arg in
    let _ = regular_helper in
    Runtime.fail_impossible_action_in_ssr "use_helpers")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
