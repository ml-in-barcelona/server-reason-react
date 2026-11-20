  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.runtime server-reason-react.reactDom melange-json-native server-reason-react.rsc-native)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/ server-reason-react.melange_ppx server-reason-react.rsc-native.ppx)))
  > EOF

  $ cat > input.re << EOF
  > module Meta = {
  >   type t = Public | Admin;
  >   let default = Public;
  > };
  > module FunctionReferences = ReactServerDOM.FunctionReferences.Make(Meta);
  > [@react.server.function: string]
  > let withTypePayload = (): Js.Promise.t(string) => Lwt.return("ok");
  > EOF

  $ dune build
  File "input.re", line 6, characters 0-32:
  6 | [@react.server.function: string]
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: server-reason-react: the payload of [@react.server.function] must be
         one expression of type FunctionReferences.meta, for example
         [@react.server.function Admin]
  [1]

  $ cat > input.re << EOF
  > module Meta = {
  >   type t = Public | Admin;
  >   let default = Public;
  > };
  > module FunctionReferences = ReactServerDOM.FunctionReferences.Make(Meta);
  > [@react.server.function "admin"]
  > let withWrongMeta = (): Js.Promise.t(string) => Lwt.return("ok");
  > EOF

  $ dune build
  File "input.re", line 6, characters 24-31:
  6 | [@react.server.function "admin"]
                              ^^^^^^^
  Error: This constant has type string but an expression was expected of type
           FunctionReferences.meta
  [1]

  $ cat > input.re << EOF
  > [@react.server.function: string]
  > let withTypePayload = (): Js.Promise.t(string) => Lwt.return("ok");
  > EOF

  $ ../ppx.sh --output re -js input.re
  [%%ocaml.error
    "server-reason-react: the payload of [@react.server.function] must be one expression of type FunctionReferences.meta, for example [@react.server.function Admin]"
  ];
