mel.as attribute

  $ cat > input.ml << EOF
  > type t
  > external document: t = "document"
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type t
  
  [%%ocaml.error
  "[server-reason-react.melange_ppx] There's an external in native, which should \
   only happen in JavaScript. You need to conditionally run it, either by not \
   including it on native or via let%browser_only/switch%platform. More info at \
   https://ml-in-barcelona.github.io/server-reason-react/local/server-reason-react/browser_only.html"]

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml
  File "main.ml", line 23, characters 3-14:
  23 | [%%ocaml.error
          ^^^^^^^^^^^
  Error: [server-reason-react.melange_ppx] There's an external in native, which
         should only happen in JavaScript. You need to conditionally run it,
         either by not including it on native or via
         let%browser_only/switch%platform. More info at
         https://ml-in-barcelona.github.io/server-reason-react/local/server-reason-react/browser_only.html
  [2]
