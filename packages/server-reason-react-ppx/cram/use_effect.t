Effect bodies never run on the server. Only server-reason-react.ppx is linked here, so it emits [%browser_only] and nothing expands it.

  $ cat > input.ml << EOF
  > let make () =
  >   React.useEffect0 (fun () -> None);
  >   React.useEffect2 (fun () -> dispatch (); None) (a, b);
  >   React.useLayoutEffect1 (fun () -> None) [| a |];
  >   React.useEffect1 [%browser_only fun () -> None] [| a |];
  >   React.useState (fun () -> 0)
  > EOF

Native: bodies are wrapped, already wrapped bodies are skipped, other React calls are untouched

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    React.useEffect0 [%browser_only fun () -> None];
    React.useEffect2
      [%browser_only
        fun () ->
          dispatch ();
          None]
      (a, b);
    React.useLayoutEffect1 [%browser_only fun () -> None] [| a |];
    React.useEffect1 [%browser_only fun () -> None] [| a |];
    React.useState (fun () -> 0)

With -melange nothing changes

  $ ./standalone.exe -impl input.ml -melange | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    React.useEffect0 (fun () -> None);
    React.useEffect2
      (fun () ->
        dispatch ();
        None)
      (a, b);
    React.useLayoutEffect1 (fun () -> None) [| a |];
    React.useEffect1 [%browser_only fun () -> None] [| a |];
    React.useState (fun () -> 0)

With ppx_platform linked as well, the emitted [%browser_only] is expanded in the same run

  $ ./standalone_platform.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    React.useEffect0 (fun () ->
        Ppx_platform_runtime.fail_impossible_action_in_ssr "<unkwnown>");
    React.useEffect2
      (fun () -> Ppx_platform_runtime.fail_impossible_action_in_ssr "<unkwnown>")
      (a, b);
    React.useLayoutEffect1
      (fun () -> Ppx_platform_runtime.fail_impossible_action_in_ssr "<unkwnown>")
      [| a |];
    React.useEffect1
      (fun () -> Ppx_platform_runtime.fail_impossible_action_in_ssr "<unkwnown>")
      [| a |];
    React.useState (fun () -> 0)

A let%browser_only function called on native raises the exception that Runtime re-exports

  $ ./impossible_in_ssr.exe | grep caught
  caught Runtime.Impossible_in_ssr
