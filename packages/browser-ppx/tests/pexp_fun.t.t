  $ cat > input.ml << EOF
  > let%browser_only pexp_fun_1arg_structure_item evt =
  >   Webapi.Dom.getElementById "foo"
  >  
  > let%browser_only pexp_fun_2arg_structure_item evt moar_arguments =
  >   Webapi.Dom.getElementById "foo"
  > 
  > let make () =
  >   let%browser_only fun_value_binding_pexp_fun_2arg evt moar_arguments =
  >     Webapi.Dom.getElementById "foo"
  >   in
  > 
  >   let%browser_only fun_value_binding_labelled_args ~argument1 ~argument2 =
  >     setHtmlFetchState Loading
  >   in
  >   ()
  > EOF

With -js flag everything keeps as it is and browser_only extension disappears

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let pexp_fun_1arg_structure_item evt = Webapi.Dom.getElementById "foo"
  
  let pexp_fun_2arg_structure_item evt moar_arguments =
    Webapi.Dom.getElementById "foo"
  
  let make () =
    let fun_value_binding_pexp_fun_2arg evt moar_arguments =
      Webapi.Dom.getElementById "foo"
    in
    let fun_value_binding_labelled_args ~argument1 ~argument2 =
      setHtmlFetchState Loading
    in
    ()
Without -js flag, the compilation to native replaces the expression with `raise (ReactDOM.Impossible_in_ssr`

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let (pexp_fun_1arg_structure_item
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@warning "-27-32"] [@alert "-browser_only"] evt ->
    Runtime.fail_impossible_action_in_ssr "pexp_fun_1arg_structure_item"
  
  let (pexp_fun_2arg_structure_item
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun [@warning "-27-32"] [@alert "-browser_only"] evt moar_arguments ->
    Runtime.fail_impossible_action_in_ssr "pexp_fun_2arg_structure_item"
  
  let make () =
    let fun_value_binding_pexp_fun_2arg evt moar_arguments =
      Runtime.fail_impossible_action_in_ssr "fun_value_binding_pexp_fun_2arg"
        [@@warning "-27-26"] [@@alert "-browser_only"]
    in
    let fun_value_binding_labelled_args ~argument1 ~argument2 =
      Runtime.fail_impossible_action_in_ssr "fun_value_binding_labelled_args"
        [@@warning "-27-26"] [@@alert "-browser_only"]
    in
    ()
