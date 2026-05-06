On Native, the `switch%platform` extension drops the Client branch and
keeps the Server branch. To silence warnings 26/27 on outer let-bindings
whose only consumers are inside the dropped Client branch, the handler
prepends `let _ = ident` references for each free unqualified Lident in
the Client branch.

  $ cat > input.ml << EOF
  > let make () =
  >   let helper = print_endline in
  >   let count = 42 in
  >   match%platform () with
  >   | Client -> helper (string_of_int count)
  >   | Server -> ()
  > EOF

With -js, the Client branch is kept.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let helper = print_endline in
    let count = 42 in
    helper (string_of_int count)

Without -js, the Client branch is dropped, but `helper`, `count`, and
`string_of_int` are referenced via `let _ = ...` before the Server expr.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let make () =
    let helper = print_endline in
    let count = 42 in
    ((let _ = helper in
      let _ = string_of_int in
      let _ = count in
      ())
    [@alert "-browser_only"])

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
