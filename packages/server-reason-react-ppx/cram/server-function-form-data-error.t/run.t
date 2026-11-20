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
  File "input.re", lines 8-14, characters 0-1:
   8 | [@react.server.function]
   9 | let withTwoFormData =
  10 |     (country: string, a: Js.FormData.t, b: Js.FormData.t)
  11 |     : Js.Promise.t(string) => {
  12 |   let _ = (a, b);
  13 |   Lwt.return(country);
  14 | }.
  Error: server-reason-react: server functions must have only one FormData
         argument
  [1]
