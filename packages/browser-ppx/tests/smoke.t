ppx_platform rules still apply through browser_ppx

  $ cat > input.ml << EOF
  > let%browser_only focus x = x
  > let value = match%platform () with
  >   | Client -> "client"
  >   | Server -> "server"
  > EOF

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let focus x = x
  let value = "client"

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let (focus
       [@alert
         browser_only
           "This expression is marked to only run on the browser where \
            JavaScript can run. You can only use it inside a let%browser_only \
            function."]) =
   (fun x ->
    Ppx_platform_runtime.fail_impossible_action_in_ssr "focus")
    [@alert "-browser_only"]
  [@@warning "-27-32"]
  
  let value = "server"

A let%browser_only function called on native raises the exception that Runtime re-exports

  $ ./impossible_in_ssr.exe | grep caught
  caught Runtime.Impossible_in_ssr
