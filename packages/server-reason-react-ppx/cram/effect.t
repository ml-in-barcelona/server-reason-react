server-reason-react.ppx leaves effects untouched on native

  $ cat > input.ml << EOF
  > let make () =
  >   React.useEffect0 (fun () -> None);
  >   React.useLayoutEffect1 (fun () -> dispatch (); None) [| a |];
  >   React.useEffect1 [%melange_only fun () -> None] [| a |]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    React.useEffect0 (fun () -> None);
    React.useLayoutEffect1
      (fun () ->
        dispatch ();
        None)
      [| a |];
    React.useEffect1 [%melange_only fun () -> None] [| a |]

An explicit [%melange_only] inside an effect is expanded by ppx_platform when both ppxes run

  $ ./standalone_platform.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    React.useEffect0 (fun () -> None);
    React.useLayoutEffect1
      (fun () ->
        dispatch ();
        None)
      [| a |];
    React.useEffect1
      (fun () -> Ppx_platform.fail_melange_only "<unkwnown>")
      [| a |]
