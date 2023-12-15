mel.raw as a value

  $ cat > input.ml << EOF
  > let value = [%mel.raw {| function(element) { return element.ownerDocument; } |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (value
      [@alert
        browser_only
          "Since it's a [%mel.raw ...]. This expression is marked to only run on \
           the browser where JavaScript can run. You can only use it inside a \
           let%browser_only function."]) =
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "value")

mel.raw as an unary function

  $ cat > input.ml << EOF
  > let unary_function element = [%mel.raw {| function(element) { return element.ownerDocument; } |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (unary_function
      [@alert
        browser_only
          "Since it's a [%mel.raw ...]. This expression is marked to only run on \
           the browser where JavaScript can run. You can only use it inside a \
           let%browser_only function."]) =
   fun _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "unary_function")

mel.raw as an binary function

  $ cat > input.ml << EOF
  > let binary_function element count = [%mel.raw {| function(element, number) {
  >     console.log(number);
  >     return element.ownerDocument;
  > } |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (binary_function
      [@alert
        browser_only
          "Since it's a [%mel.raw ...]. This expression is marked to only run on \
           the browser where JavaScript can run. You can only use it inside a \
           let%browser_only function."]) =
   fun _ _ ->
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "binary_function")

mel.raw with type

  $ cat > input.ml << EOF
  > type t
  > let global: t = [%mel.raw "window"]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type t
  
  let (global
      [@alert
        browser_only
          "Since it's a [%mel.raw ...]. This expression is marked to only run on \
           the browser where JavaScript can run. You can only use it inside a \
           let%browser_only function."]) =
    let () =
      Printf.printf
        {|
  There is a Melange's external (for example: [@mel.get]) call from native code.
  
  Melange externals are bindings to JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "")

mel.raw as a value

  $ cat > input.ml << EOF
  > [%%mel.raw {| console.log("running in JS"); |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  ()
