  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.runtime server-reason-react.reactDom melange-json-native server-reason-react.rsc-native)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/ server-reason-react.melange_ppx server-reason-react.rsc-native.ppx)))
  > EOF

  $ dune build
  File "input.re", lines 10-16, characters 0-1:
  10 | [@react.server.function]
  11 | let withTwoFormData =
  12 |     (country: string, a: Js.FormData.t, b: Js.FormData.t)
  13 |     : Js.Promise.t(string) => {
  14 |   let _ = (a, b);
  15 |   Lwt.return(country);
  16 | }.
  Error: server-reason-react: server functions must have only one FormData
         argument
  [1]
