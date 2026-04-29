The `[%browser_only expr]` form (extension as expression) wraps an
expression. For function expressions, args are preserved; for non-function
expressions, the body is replaced with a raise.

  $ cat > input.ml << EOF
  > let make () =
  >   let handler = [%browser_only fun event -> ignore event] in
  >   handler
  > EOF

With -js, the extension is removed and the expression is kept verbatim.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let handler event = ignore event in
    handler

Without -js, the function arg is preserved with its let-chain reference.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let make () =
    let handler event =
      let _ = event in
      let _ = ignore in
      Runtime.fail_impossible_action_in_ssr "fun event -> ignore event"
    in
    handler

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
