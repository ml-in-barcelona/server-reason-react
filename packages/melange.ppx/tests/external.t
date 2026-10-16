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
   native, or annotating it with [@melange_only]. More info at \
   https://github.com/ml-in-barcelona/ppx_platform"]

  $ echo "module Ppx_platform_runtime = struct exception Impossible_in_ssr of string let fail_impossible_action_in_ssr (_ : string) = raise (Impossible_in_ssr \"\") end" > main.ml
  $ echo "module Runtime = struct" >> main.ml
  $ cat $INSIDE_DUNE/packages/runtime/Runtime.ml >> main.ml
  $ echo "end" >> main.ml
  $ cat output.ml >> main.ml
  $ ocamlc -c main.ml
  File "main.ml", line 12, characters 3-14:
  12 | [%%ocaml.error
          ^^^^^^^^^^^
  Error: [server-reason-react.melange_ppx] There's an external in native, which
         should only happen in JavaScript. You need to conditionally discard it
         from the native build, either by moving the external in a module only
         available in native, or annotating it with [@melange_only]. More info
         at https://github.com/ml-in-barcelona/ppx_platform
  [2]

An external with [@melange_only] is passed through (ppx_platform will filter it)

  $ cat > input.ml << EOF
  > type t
  > external document: t = "document" [@@melange_only]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type t
  
  external document : t = "document" [@@melange_only]

An external with [@melange_only] is passed through (ppx_platform will filter it)

  $ cat > input.ml << EOF
  > type t
  > external document: t = "document" [@@melange_only]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  type t
  
  external document : t = "document" [@@melange_only]
