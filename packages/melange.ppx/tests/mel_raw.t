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
    raise (Failure "called Melange external \"mel.\" from native")

  $ ocamlc output.ml

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
   fun _ -> raise (Failure "called Melange external \"mel.\" from native")

  $ ocamlc output.ml

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
   fun _ _ -> raise (Failure "called Melange external \"mel.\" from native")

  $ ocamlc output.ml

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
    raise (Failure "called Melange external \"mel.\" from native")

  $ ocamlc output.ml

mel.raw as a value

  $ cat > input.ml << EOF
  > [%%mel.raw {| console.log("running in JS"); |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  ()

  $ ocamlc output.ml
