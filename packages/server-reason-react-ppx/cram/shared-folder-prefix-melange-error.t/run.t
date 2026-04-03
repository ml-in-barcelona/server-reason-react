  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=native/ -melange)))
  > EOF

  $ cat > input.re << EOF
  > [@react.client.component]
  > let make = () => React.null;
  > EOF

  $ dune describe pp input.re
  [%%ocaml.error
    "Found a react.client.component in file \"input.re\", but --shared-folder-prefix=\"native/\" does not match the file path. This can happen when a #line directive rewrites the filename seen by the PPX."]
