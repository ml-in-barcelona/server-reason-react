mel.as attribute
  $ cat > input.ml << EOF
  > external get : t -> (_[@mel.as {json|{}|json}]) -> t = "get" [@@mel.send]
  > EOF

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl | tee output.ml
  let (get : t -> (_[@mel.as {json|{}|json}]) -> t) =
   fun _ ->
    let () =
      Printf.printf
        {|
  There has been a call to a Melange's external [@mel.blabla] from native code.
  
  External bindings are used to communicate with JavaScript code, which can't run on the server and should be wrapped with browser_only ppx or only run it only on the client side. If there's any issue, try wrapping the expression with a try/catch as a workaround.
  
  |}
    in
    raise (Runtime.fail_impossible_action_in_ssr "get")
