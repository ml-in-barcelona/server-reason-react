let pstr_value_binding = [%browser_only Webapi.Dom.getElementById "foo"]
let%browser_only pstr_value_binding_2 = Webapi.Dom.getElementById "foo"

let%browser_only pexp_fun_1arg_structure_item evt =
  Webapi.Dom.getElementById "foo"

let%browser_only pexp_fun_2arg_structure_item evt moar_arguments =
  Webapi.Dom.getElementById "foo"

let make () =
  let fun_value_binding_pexp =
    [%browser_only Webapi.Dom.getElementById "foo"]
  in
  let%browser_only fun_value_binding_pexp_2 = Webapi.Dom.getElementById "foo" in
  let%browser_only fun_value_binding_pexp_fun_1arg evt =
    Webapi.Dom.getElementById "foo"
  in

  let%browser_only fun_value_binding_pexp_fun_2arg evt moar_arguments =
    Webapi.Dom.getElementById "foo"
  in

  let%browser_only fun_value_binding_labelled_args ~argument1 ~argument2 =
    setHtmlFetchState Loading
  in

  React.createElement "div"
