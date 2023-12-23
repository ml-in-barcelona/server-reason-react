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

Without -js flag, the compilation to native replaces the expression with `raise (Runtime.Impossible_in_ssr`

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let pexp_ident =
      Runtime.fail_impossible_action_in_ssr "Webapi__Dom__Element.asHtmlElement"
        [@@alert "-browser_only"]
    in
    ()
