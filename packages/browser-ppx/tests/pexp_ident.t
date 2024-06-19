  $ cat > input.ml << EOF
  > let make () =
  >   let%browser_only pexp_ident = Webapi__Dom__Element.asHtmlElement in
  >   ()
  > EOF

With -js flag everything keeps as it is and browser_only extension disappears

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let pexp_ident = Webapi__Dom__Element.asHtmlElement in
    ()

Without -js flag, the compilation to native errors out indicating that a function must be used

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let pexp_ident =
      [%ocaml.error
        "[browser_ppx] browser_only works on function definitions. For other \
         cases, use switch%platform or feel free to open an issue in \
         https://github.com/ml-in-barcelona/server-reason-react."]
    in
    ()
