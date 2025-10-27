mel.raw as a value

  $ cat > input.ml << EOF
  > let value = [%mel.raw {| function(element) { return element.ownerDocument; } |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  [%error
    "[server-reason-react.melange_ppx] There's a [%mel.raw \" function(element) \
     { return element.ownerDocument; } \"] expression in native, which should \
     only happen in JavaScript. You need to conditionally run it via \
     let%browser_only or switch%platform. More info at \
     https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/browser_ppx.html"]

mel.raw as an unary function

  $ cat > input.ml << EOF
  > let unary_function element = [%mel.raw {| function(element) { return element.ownerDocument; } |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  [%error
    "[server-reason-react.melange_ppx] There's a [%mel.raw \" function(element) \
     { return element.ownerDocument; } \"] expression in native, which should \
     only happen in JavaScript. You need to conditionally run it via \
     let%browser_only or switch%platform. More info at \
     https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/browser_ppx.html"]

mel.raw as an binary function

  $ cat > input.ml << EOF
  > let binary_function element count = [%mel.raw {| function(element, number) {
  >     console.log(number);
  >     return element.ownerDocument;
  > } |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  [%error
    "[server-reason-react.melange_ppx] There's a [%mel.raw \" function(element, \
     number) {\n\
    \    console.log(number);\n\
    \    return element.ownerDocument;\n\
     } \"] expression in native, which should only happen in JavaScript. You \
     need to conditionally run it via let%browser_only or switch%platform. More \
     info at \
     https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/browser_ppx.html"]

mel.raw with type

  $ cat > input.ml << EOF
  > type t
  > let global: t = [%mel.raw "window"]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type t;;
  
  [%error
    "[server-reason-react.melange_ppx] There's a [%mel.raw \"window\"] \
     expression in native, which should only happen in JavaScript. You need to \
     conditionally run it via let%browser_only or switch%platform. More info at \
     https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/browser_ppx.html"]

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml
  File "main.ml", line 26, characters 2-7:
  26 | [%error
         ^^^^^
  Error: [server-reason-react.melange_ppx] There's a [%mel.raw "window"]
         expression in native, which should only happen in JavaScript. You need
         to conditionally run it via let%browser_only or switch%platform. More
         info at
         https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/browser_ppx.html
  [2]

mel.raw as a value

  $ cat > input.ml << EOF
  > [%%mel.raw {| console.log("running in JS"); |}]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  [%%ocaml.error
  "[server-reason-react.melange_ppx] There's a [%mel.raw \" \
   console.log(\"running in JS\"); \"] expression in native, which should only \
   happen in JavaScript. You need to conditionally run it via let%browser_only \
   or switch%platform. More info at \
   https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/browser_ppx.html"]
