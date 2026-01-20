  $ cat > input.ml << EOF
  > let make () =
  >   let%browser_only fun_value_binding_pexp_fun_2arg evt moar_arguments =
  >     let a = "foo" in
  >     Webapi.Dom.getElementById a
  >   in
  > 
  >   let%browser_only fun_value_binding_pexp_fun_default_expr ?(evt=22) =
  >     Webapi.Dom.getElementById evt
  >   in
  > 
  >   let%browser_only fun_value_binding_pexp_fun_2arg evt moar_arguments =
  >     let a = 1 in
  >     let b = 2 in
  >     Webapi.Dom.getElementById b
  >   in
  >   ()
  > 
  > EOF

With -js flag everything keeps as it is and browser_only extension disappears

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let fun_value_binding_pexp_fun_2arg evt moar_arguments =
      let a = "foo" in
      Webapi.Dom.getElementById a
    in
    let fun_value_binding_pexp_fun_default_expr ?(evt = 22) =
      Webapi.Dom.getElementById evt
    in
    let fun_value_binding_pexp_fun_2arg evt moar_arguments =
      let a = 1 in
      let b = 2 in
      Webapi.Dom.getElementById b
    in
    ()

Without -js flag, the compilation to native replaces the expression with a raise

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl > output.ml

  $ cat output.ml
  let make () =
    let fun_value_binding_pexp_fun_2arg evt =
      Runtime.fail_impossible_action_in_ssr "fun_value_binding_pexp_fun_2arg"
        [@@alert "-browser_only"]
    in
    let fun_value_binding_pexp_fun_default_expr ?evt =
      Runtime.fail_impossible_action_in_ssr
        "fun_value_binding_pexp_fun_default_expr"
        [@@alert "-browser_only"]
    in
    let fun_value_binding_pexp_fun_2arg evt =
      Runtime.fail_impossible_action_in_ssr "fun_value_binding_pexp_fun_2arg"
        [@@alert "-browser_only"]
    in
    ()

Replace Runtime.fail_impossible_action_in_ssr with print_endline so ocamlc can compile it without the Runtime module dependency
  $ sed "s/Runtime.fail_impossible_action_in_ssr/print_endline/g" output.ml > output.ml

  $ ocamlc -c output.ml
