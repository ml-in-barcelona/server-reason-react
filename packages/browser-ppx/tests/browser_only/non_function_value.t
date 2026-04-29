Non-function value bindings are replaced with just the raise. Body free
identifiers are NOT referenced because the body may reference platform-
restricted symbols (browser-only modules) that don't exist on native.

  $ cat > input.ml << EOF
  > let some_value = "hello"
  > 
  > let%browser_only ofElement = some_value
  > EOF

With -js, the binding is preserved.

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let some_value = "hello"
  let ofElement = some_value

Without -js, the binding is replaced with a polymorphic raise.

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let some_value = "hello"
  
  let (ofElement
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
    Runtime.fail_impossible_action_in_ssr "ofElement" [@alert "-browser_only"]
  [@@warning "-26-27-32-33"]

  $ cat ../runtime_stub.ml output.ml > final.ml
  $ ocamlc -w @a-70 -c final.ml
