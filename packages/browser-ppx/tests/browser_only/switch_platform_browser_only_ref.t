When `switch%platform`'s dropped branch references a `let%browser_only`
binding, the generated `let _ = ident` chain must NOT include that name:
the binding's pattern carries an `[@alert browser_only ...]` attribute,
and any reference would trip the alert and break compilation.

The pre-scan tracks `let%browser_only` names alongside `[@platform js]`
names, so [Body_free_idents.collect] omits them from the chain. The
binding itself already carries `[@@warning "-26-27-32-33"]`, so dropping
the reference does not reintroduce an unused-binding warning.

  $ cat > input.ml << EOF
  > let%browser_only get_offset el = el + 1
  > 
  > let use el_ref =
  >   match%platform () with
  >   | Server -> 0
  >   | Client -> el_ref + (get_offset 0)
  > EOF

With -js, the Client branch is kept. The chain references names from the
dropped Server branch (none here, so no chain).

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let get_offset el = el + 1
  let use el_ref = el_ref + get_offset 0

Without -js, the Client branch is dropped. The chain references `el_ref`
(silences warning 27 on the unused argument) but skips `get_offset`
because it is bound by `let%browser_only` and referencing it would fire
the `(alert browser_only)` on its pattern.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let (get_offset
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun el ->
    let _ = el in
    Runtime.fail_impossible_action_in_ssr "get_offset")
    [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]
  
  let use el_ref =
    (let _ = el_ref in
     0)
    [@alert "-browser_only"]

The generated code compiles cleanly with all warnings as errors. The
`(alert browser_only)` would fire if `get_offset` appeared in the chain.

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
