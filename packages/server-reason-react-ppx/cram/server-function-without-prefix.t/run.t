  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.runtime server-reason-react.js)
  >  (preprocess (pps server-reason-react.ppx)))
  > EOF

  $ cat > input.ml << EOF
  > let[@react.server.function] greet ~(name : string) : string Js.Promise.t = Js.Promise.resolve name
  > EOF

  $ dune build
  File "input.ml", line 1, characters 0-98:
  1 | let[@react.server.function] greet ~(name : string) : string Js.Promise.t = Js.Promise.resolve name
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: Found a server.function without -shared-folder-prefix argument.
         Provide one.
  [1]
