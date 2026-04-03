  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.runtime server-reason-react.reactDom melange-json)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=native/ server-reason-react.melange_ppx melange-json-native.ppx)))
  > EOF

  $ cat > input.ml << EOF
  > let[@react.server.function] action () : string Js.Promise.t = Js.Promise.resolve "ok"
  > EOF

  $ dune describe pp input.ml
  [%%ocaml.error
    "Found a react.server.function in file \"input.ml\", but --shared-folder-prefix=\"native/\" does not match the file path. This can happen when a #line directive rewrites the filename seen by the PPX."]
