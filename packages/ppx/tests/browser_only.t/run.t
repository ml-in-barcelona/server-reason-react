With -js flag everything keeps as it is and browser_only extension disappears

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let pstr_value_binding = Webapi.Dom.getElementById "foo"
  let pstr_value_binding_2 = Webapi.Dom.getElementById "foo"
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
    React.createElement "div"

Without -js flag, the compilation to native replaces the expression with `raise (ReactDOM.Impossible_in_ssr`

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let pstr_value_binding =
    Runtime.fail_impossible_action_in_ssr "Webapi.Dom.getElementById"
  
  let pstr_value_binding_2 = Webapi.Dom.getElementById "foo"
  
  let pexp_fun_1arg_structure_item evt =
    Runtime.fail_impossible_action_in_ssr "pexp_fun_1arg_structure_item"
  [@@warning "-27-32"]
  
  let pexp_fun_2arg_structure_item evt moar_arguments =
    Runtime.fail_impossible_action_in_ssr "pexp_fun_2arg_structure_item"
  [@@warning "-27-32"]
  
  let make () =
    let fun_value_binding_pexp =
      Runtime.fail_impossible_action_in_ssr "Webapi.Dom.getElementById"
    in
    (let fun_value_binding_pexp_2 =
       [%ocaml.error
         "browser_only works on function definitions. If there's another case \
          where it can be helpful, feel free to open an issue in \
          https://github.com/ml-in-barcelona/server-reason-react."]
     in
     (let fun_value_binding_pexp_fun_1arg =
       fun [@warning "-27"] evt ->
        Runtime.fail_impossible_action_in_ssr "fun_value_binding_pexp_fun_1arg"
         [@@warning "-27-26"]
      in
      (let fun_value_binding_pexp_fun_2arg =
        fun [@warning "-27"] evt ->
         fun [@warning "-27"] moar_arguments ->
          Runtime.fail_impossible_action_in_ssr "fun_value_binding_pexp_fun_2arg"
          [@@warning "-27-26"]
       in
       (let fun_value_binding_labelled_args =
         fun [@warning "-27"] ~argument1 ->
          fun [@warning "-27"] ~argument2 ->
           Runtime.fail_impossible_action_in_ssr "fun_value_binding_labelled_args"
           [@@warning "-27-26"]
        in
        React.createElement "div")
       [@warning "-27"])
      [@warning "-27"])
     [@warning "-27"])
    [@warning "-27"]
