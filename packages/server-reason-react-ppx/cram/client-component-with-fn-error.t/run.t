  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.reactDom melange-json)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/ server-reason-react.melange_ppx melange-json-native.ppx)))
  > EOF

  $ dune build
  File "input.re", line 2, characters 22-32:
  2 | let make = (~initial: int => int) => {
                            ^^^^^^^^^^
  Error: server-reason-react: you can't pass functions into client components.
         Functions aren't serialisable to JSON.
  [1]
