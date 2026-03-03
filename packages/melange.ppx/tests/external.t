An external without platform attribute errors

  $ cat > input.ml << EOF
  > type t
  > external document: t = "document"
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  type t
  
  [%%ocaml.error
  "[server-reason-react.melange_ppx] There's an external in native, which should \
   only happen in JavaScript. You need to conditionally discard it from the \
   native build, either by moving the external in a module only available in \
   native, or annotating it with [@platform js]. More info at \
   https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/browser_ppx.html"]

  $ echo "module Runtime = struct" > main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml
  File "main.ml", line 26, characters 3-14:
  26 | [%%ocaml.error
          ^^^^^^^^^^^
  Error: [server-reason-react.melange_ppx] There's an external in native, which
         should only happen in JavaScript. You need to conditionally discard it
         from the native build, either by moving the external in a module only
         available in native, or annotating it with [@platform js]. More info
         at
         https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/browser_ppx.html
  [2]

An external with [@platform js] is passed through (browser_ppx will filter it)

  $ cat > input.ml << EOF
  > type t
  > external document: t = "document" [@@platform js]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type t
  
  external document : t = "document" [@@platform js]

An external with [@browser_only] is passed through (browser_ppx will filter it)

  $ cat > input.ml << EOF
  > type t
  > external document: t = "document" [@@browser_only]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type t
  
  external document : t = "document" [@@browser_only]
