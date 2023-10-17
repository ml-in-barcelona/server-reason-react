  $ cat > input.ml << EOF
  > let pstr_value_binding = [%browser_only Webapi.Dom.getElementById "foo"]
  > let%browser_only pstr_value_binding_2 = Webapi.Dom.getElementById "foo"
  > let%browser_only pexp_ident = Webapi__Dom__Element.asHtmlElement
  > 
  > let%browser_only pexp_fun_1arg_structure_item evt =
  >   Webapi.Dom.getElementById "foo"
  >  
  > let%browser_only pexp_fun_2arg_structure_item evt moar_arguments =
  >   Webapi.Dom.getElementById "foo"
  > 
  > let make () =
  >   let fun_value_binding_pexp =
  >     [%browser_only Webapi.Dom.getElementById "foo"]
  >   in
  >   let%browser_only fun_value_binding_pexp_2 = Webapi.Dom.getElementById "foo" in
  >   let%browser_only fun_value_binding_pexp_fun_1arg evt =
  >     Webapi.Dom.getElementById "foo"
  >   in
  > 
  >   let%browser_only fun_value_binding_pexp_fun_2arg evt moar_arguments =
  >     Webapi.Dom.getElementById "foo"
  >   in
  > 
  >   let%browser_only fun_value_binding_labelled_args ~argument1 ~argument2 =
  >     setHtmlFetchState Loading
  >   in
  > 
  >   let%browser_only pexp_ident = Webapi__Dom__Element.asHtmlElement in
  > 
  >   React.createElement "div"
  > EOF

With -js flag everything keeps as it is and browser_only extension disappears

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let pstr_value_binding = Webapi.Dom.getElementById "foo"
  let pstr_value_binding_2 = Webapi.Dom.getElementById "foo"
  let pexp_ident = Webapi__Dom__Element.asHtmlElement
  let pexp_fun_1arg_structure_item evt = Webapi.Dom.getElementById "foo"
  
  let pexp_fun_2arg_structure_item evt moar_arguments =
    Webapi.Dom.getElementById "foo"
  
  let make () =
    let fun_value_binding_pexp = Webapi.Dom.getElementById "foo" in
    let fun_value_binding_pexp_2 = Webapi.Dom.getElementById "foo" in
    let fun_value_binding_pexp_fun_1arg evt = Webapi.Dom.getElementById "foo" in
    let fun_value_binding_pexp_fun_2arg evt moar_arguments =
      Webapi.Dom.getElementById "foo"
    in
    let fun_value_binding_labelled_args ~argument1 ~argument2 =
      setHtmlFetchState Loading
    in
    let pexp_ident = Webapi__Dom__Element.asHtmlElement in
    React.createElement "div"

Without -js flag, the compilation to native replaces the expression with `raise (ReactDOM.Impossible_in_ssr`

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let pstr_value_binding =
    Runtime.fail_impossible_action_in_ssr "Webapi.Dom.getElementById"
  
  let pstr_value_binding_2 = Webapi.Dom.getElementById "foo"
  
  let (pexp_ident
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
    Runtime.fail_impossible_action_in_ssr "Webapi__Dom__Element.asHtmlElement"
  [@@alert "-browser_only"]
  
  let (pexp_fun_1arg_structure_item
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun evt -> Runtime.fail_impossible_action_in_ssr "pexp_fun_1arg_structure_item"
  [@@warning "-27-32"] [@@alert "-browser_only"]
  
  let (pexp_fun_2arg_structure_item
      [@alert
        browser_only
          "This expression is marked to only run on the browser where JavaScript \
           can run. You can only use it inside a let%browser_only function."]) =
   fun evt moar_arguments ->
    Runtime.fail_impossible_action_in_ssr "pexp_fun_2arg_structure_item"
  [@@warning "-27-32"] [@@alert "-browser_only"]
  
  let make () =
    let fun_value_binding_pexp =
      Runtime.fail_impossible_action_in_ssr "Webapi.Dom.getElementById"
    in
    let fun_value_binding_pexp_2 =
      [%ocaml.error
        "browser_only works on function definitions or values. If there's \
         another case where it can be helpful, feel free to open an issue in \
         https://github.com/ml-in-barcelona/server-reason-react."]
    in
    let fun_value_binding_pexp_fun_1arg evt =
      Runtime.fail_impossible_action_in_ssr "fun_value_binding_pexp_fun_1arg"
        [@@warning "-27-26"] [@@alert "-browser_only"]
    in
    let fun_value_binding_pexp_fun_2arg evt moar_arguments =
      Runtime.fail_impossible_action_in_ssr "fun_value_binding_pexp_fun_2arg"
        [@@warning "-27-26"] [@@alert "-browser_only"]
    in
    let fun_value_binding_labelled_args ~argument1 ~argument2 =
      Runtime.fail_impossible_action_in_ssr "fun_value_binding_labelled_args"
        [@@warning "-27-26"] [@@alert "-browser_only"]
    in
    let pexp_ident =
      Runtime.fail_impossible_action_in_ssr "Webapi__Dom__Element.asHtmlElement"
        [@@alert "-browser_only"]
    in
    React.createElement "div"
