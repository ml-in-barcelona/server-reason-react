  $ cat > input.ml << EOF
  > let pstr_value_binding = [%browser_only Webapi.Dom.getElementById "foo"]
  > let make () =
  >   let%browser_only pstr_value_binding_2 = Webapi.Dom.getElementById "foo" in
  >   ()
  > 
  > EOF

With -js flag everything keeps as it is and browser_only extension disappears

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let pstr_value_binding = Webapi.Dom.getElementById "foo"
  
  let make () =
    let pstr_value_binding_2 = Webapi.Dom.getElementById "foo" in
    ()
  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let pstr_value_binding =
    Runtime.fail_impossible_action_in_ssr "Webapi.Dom.getElementById"
  
  let make () =
    let pstr_value_binding_2 =
      [%ocaml.error
        "browser_only works on function definitions or values. If there's \
         another case where it can be helpful, feel free to open an issue in \
         https://github.com/ml-in-barcelona/server-reason-react."]
    in
    ()
