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

Without -js flag, the compilation to native errors out indicating that a function must be used

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let pstr_value_binding =
    [%ocaml.error
      "[browser_ppx] browser_only works on function definitions. For other \
       cases, use switch%platform or feel free to open an issue in \
       https://github.com/ml-in-barcelona/server-reason-react."]
  
  let make () =
    let pstr_value_binding_2 =
      [%ocaml.error
        "[browser_ppx] browser_only works on function definitions. For other \
         cases, use switch%platform or feel free to open an issue in \
         https://github.com/ml-in-barcelona/server-reason-react."]
    in
    ()
