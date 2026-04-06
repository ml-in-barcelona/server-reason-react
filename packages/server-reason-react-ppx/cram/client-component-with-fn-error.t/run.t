  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.reactDom melange-json-native server-reason-react.rsc-native)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/ server-reason-react.melange_ppx server-reason-react.rsc-native.ppx)))
  > EOF

  $ dune build
  File "input.re", line 2, characters 22-32:
  2 | let make = (~initial: int => int) => {
                            ^^^^^^^^^^
  Error: server-reason-react: you can't pass plain functions into client
         components. Use Runtime.server_function for server actions.
  [1]
