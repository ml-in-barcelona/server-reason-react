open Ppxlib
module B = Ast_builder.Default

let unit_expression ~loc = B.pexp_construct ~loc { txt = Longident.Lident "()"; loc } None
let optional_argument label = function None -> [] | Some expression -> [ (Labelled label, expression) ]
let unit_type ~loc = B.ptyp_constr ~loc { txt = Longident.Lident "unit"; loc } []
let result_type ~loc name = B.ptyp_constr ~loc { txt = Longident.parse name; loc } []
let option_type ~loc typ = B.ptyp_constr ~loc { txt = Longident.Lident "option"; loc } [ typ ]
let list_type ~loc typ = B.ptyp_constr ~loc { txt = Longident.Lident "list"; loc } [ typ ]
let bool_type ~loc = result_type ~loc "bool"

let destination_declaration ~loc ~manifest ~private_ =
  B.type_declaration ~loc ~name:{ txt = "destination"; loc } ~params:[] ~cstrs:[] ~kind:Ptype_abstract ~private_
    ~manifest

let navigate_type ~loc =
  let result =
    B.ptyp_constr ~loc { txt = Longident.parse "Js.Promise.t"; loc } [ result_type ~loc "Navigation.Result.t" ]
  in
  B.ptyp_arrow ~loc (Optional "history")
    (result_type ~loc "Navigation.historyAction")
    (B.ptyp_arrow ~loc (Optional "revalidate") (bool_type ~loc)
       (B.ptyp_arrow ~loc Nolabel (result_type ~loc "destination") result))

let update_hash_type ~loc =
  B.ptyp_arrow ~loc (Labelled "hash") (result_type ~loc "string")
    (B.ptyp_arrow ~loc (Optional "history")
       (result_type ~loc "Navigation.historyAction")
       (B.ptyp_arrow ~loc Nolabel (unit_type ~loc) (result_type ~loc "Navigation.Result.t")))

let react_component_attribute ~loc =
  { attr_name = { txt = "react.component"; loc }; attr_payload = PStr []; attr_loc = loc }

let search_destination_type ~loc (search : Router_declaration.search) =
  match search.kind with Required | Optional | Default _ -> search.typ | Many -> list_type ~loc search.typ

let search_value_type ~loc (search : Router_declaration.search) =
  match search.kind with
  | Required | Default _ -> search.typ
  | Optional -> option_type ~loc search.typ
  | Many -> list_type ~loc search.typ

let search_argument_label (search : Router_declaration.search) =
  match search.kind with Required -> Labelled search.name | Optional | Default _ | Many -> Optional search.name

let route_input_type ~loc parameters search result =
  let result =
    List.fold_right
      (fun (search : Router_declaration.search) result ->
        B.ptyp_arrow ~loc (search_argument_label search) (search_destination_type ~loc search) result)
      search result
  in
  List.fold_right
    (fun (parameter : Router_declaration.parameter) result ->
      B.ptyp_arrow ~loc (Labelled parameter.name) parameter.typ result)
    parameters result

let route_function_type ~loc parameters search result =
  route_input_type ~loc parameters search (B.ptyp_arrow ~loc Nolabel (unit_type ~loc) result)

let link_component_type ~loc parameters search =
  let result = result_type ~loc "React.element" in
  let with_unit = B.ptyp_arrow ~loc Nolabel (unit_type ~loc) result in
  let with_children = B.ptyp_arrow ~loc (Labelled "children") (result_type ~loc "React.element") with_unit in
  let with_revalidate = B.ptyp_arrow ~loc (Optional "revalidate") (bool_type ~loc) with_children in
  let with_history =
    B.ptyp_arrow ~loc (Optional "history") (result_type ~loc "Navigation.historyAction") with_revalidate
  in
  let with_aria_current = B.ptyp_arrow ~loc (Optional "ariaCurrent") (result_type ~loc "string") with_history in
  let with_download = B.ptyp_arrow ~loc (Optional "download") (result_type ~loc "string") with_aria_current in
  let with_target = B.ptyp_arrow ~loc (Optional "target") (result_type ~loc "string") with_download in
  let with_class_name = B.ptyp_arrow ~loc (Optional "className") (result_type ~loc "string") with_target in
  route_input_type ~loc parameters search with_class_name

let update_search_function_type ~loc search =
  let result = result_type ~loc "Navigation.Result.t" in
  let with_unit = B.ptyp_arrow ~loc Nolabel (unit_type ~loc) result in
  let with_options = B.ptyp_arrow ~loc (Optional "history") (result_type ~loc "Navigation.historyAction") with_unit in
  List.fold_right
    (fun (search : Router_declaration.search) result ->
      B.ptyp_arrow ~loc (Labelled search.name) (search_value_type ~loc search) result)
    search with_options

let search_type_declaration ~loc search =
  let fields =
    List.map
      (fun (search : Router_declaration.search) ->
        B.label_declaration ~loc:search.loc ~name:{ txt = search.name; loc = search.loc } ~mutable_:Immutable
          ~type_:(search_value_type ~loc:search.loc search))
      search
  in
  B.type_declaration ~loc ~name:{ txt = "search"; loc } ~params:[] ~cstrs:[] ~kind:(Ptype_record fields)
    ~private_:Public ~manifest:None

let route_type_declaration ~loc routes =
  let constructors =
    List.map
      (fun (route : Router_declaration.route) ->
        let args =
          match route.parameters with
          | [] -> Pcstr_tuple []
          | parameters ->
              Pcstr_record
                (List.map
                   (fun (parameter : Router_declaration.parameter) ->
                     B.label_declaration ~loc:parameter.loc
                       ~name:{ txt = parameter.name; loc = parameter.loc }
                       ~mutable_:Immutable ~type_:parameter.typ)
                   parameters)
        in
        B.constructor_declaration ~loc:route.loc ~name:{ txt = route.name; loc = route.loc } ~args ~res:None)
      routes
  in
  B.type_declaration ~loc ~name:{ txt = "route"; loc } ~params:[] ~cstrs:[] ~kind:(Ptype_variant constructors)
    ~private_:Public ~manifest:None

let some_expression ~loc expression = B.pexp_construct ~loc { txt = Longident.Lident "Some"; loc } (Some expression)

let route_constructor_expression (route : Router_declaration.route) =
  let loc = route.loc in
  let payload =
    match route.parameters with
    | [] -> None
    | parameters ->
        Some
          (B.pexp_record ~loc
             (List.map
                (fun (parameter : Router_declaration.parameter) ->
                  ({ txt = Longident.Lident parameter.name; loc = parameter.loc }, B.evar ~loc parameter.name))
                parameters)
             None)
  in
  B.pexp_construct ~loc { txt = Longident.Lident route.name; loc } payload

let decode_route_expression (route : Router_declaration.route) =
  let loc = route.loc in
  let bindings =
    List.map
      (fun (parameter : Router_declaration.parameter) ->
        let decoded =
          B.pexp_apply ~loc (B.evar ~loc "decodeRouteParameter")
            [
              (Labelled "routeId", B.estring ~loc route.name);
              (Labelled "name", B.estring ~loc parameter.name);
              (Labelled "parse", B.pexp_ident ~loc { txt = parameter.parser; loc });
              (Nolabel, B.evar ~loc "parameters");
            ]
        in
        B.value_binding ~loc ~pat:(B.pvar ~loc parameter.name) ~expr:decoded)
      route.parameters
  in
  let route = some_expression ~loc (route_constructor_expression route) in
  match bindings with [] -> route | _ -> B.pexp_let ~loc Nonrecursive bindings route

let decode_route_parameter_expression ~loc =
  let invalid =
    let message =
      B.pexp_apply ~loc (B.evar ~loc "^")
        [ (Nolabel, B.estring ~loc "invalid parameters for active route "); (Nolabel, B.evar ~loc "routeId") ]
    in
    B.pexp_apply ~loc (B.evar ~loc "invalid_arg") [ (Nolabel, message) ]
  in
  let parsed = B.pexp_apply ~loc (B.evar ~loc "parse") [ (Nolabel, B.evar ~loc "raw") ] in
  let parse_match =
    B.pexp_match ~loc parsed
      [
        B.case
          ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "Ok"; loc } (Some (B.pvar ~loc "value")))
          ~guard:None ~rhs:(B.evar ~loc "value");
        B.case
          ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "Error"; loc } (Some (B.ppat_any ~loc)))
          ~guard:None ~rhs:invalid;
      ]
  in
  let raw =
    B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.assoc_opt")
      [ (Nolabel, B.evar ~loc "name"); (Nolabel, B.evar ~loc "parameters") ]
  in
  let body =
    B.pexp_match ~loc raw
      [
        B.case
          ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "Some"; loc } (Some (B.pvar ~loc "raw")))
          ~guard:None ~rhs:parse_match;
        B.case ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "None"; loc } None) ~guard:None ~rhs:invalid;
      ]
  in
  B.pexp_fun ~loc (Labelled "routeId") None (B.pvar ~loc "routeId")
    (B.pexp_fun ~loc (Labelled "name") None (B.pvar ~loc "name")
       (B.pexp_fun ~loc (Labelled "parse") None (B.pvar ~loc "parse")
          (B.pexp_fun ~loc Nolabel None (B.pvar ~loc "parameters") body)))

let use_route_expression ~loc routes =
  let route_cases =
    List.map
      (fun (route : Router_declaration.route) ->
        B.case
          ~lhs:(B.ppat_constant ~loc:route.loc (Pconst_string (route.name, route.loc, None)))
          ~guard:None ~rhs:(decode_route_expression route))
      routes
  in
  let unknown_route =
    B.pexp_apply ~loc (B.evar ~loc "invalid_arg") [ (Nolabel, B.estring ~loc "unknown active route") ]
  in
  let route_match =
    B.pexp_match ~loc (B.evar ~loc "routeId")
      (route_cases @ [ B.case ~lhs:(B.ppat_any ~loc) ~guard:None ~rhs:unknown_route ])
  in
  let current_route =
    B.pexp_apply ~loc (B.evar ~loc "RouterReact.useCurrentRoute") [ (Nolabel, unit_expression ~loc) ]
  in
  let route_body =
    B.pexp_match ~loc current_route
      [
        B.case
          ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "None"; loc } None)
          ~guard:None
          ~rhs:(B.pexp_construct ~loc { txt = Longident.Lident "None"; loc } None);
        B.case
          ~lhs:
            (B.ppat_construct ~loc { txt = Longident.Lident "Some"; loc }
               (Some (B.ppat_tuple ~loc [ B.pvar ~loc "routeId"; B.pvar ~loc "parameters" ])))
          ~guard:None ~rhs:route_match;
      ]
  in
  let body =
    B.pexp_let ~loc Nonrecursive
      [ B.value_binding ~loc ~pat:(B.pvar ~loc "decodeRouteParameter") ~expr:(decode_route_parameter_expression ~loc) ]
      route_body
  in
  B.pexp_fun ~loc Nolabel None (B.punit ~loc) body

let route_input_expression ~loc parameters search body =
  let body =
    List.fold_right
      (fun (search : Router_declaration.search) body ->
        B.pexp_fun ~loc (search_argument_label search) None (B.pvar ~loc search.name) body)
      search body
  in
  List.fold_right
    (fun (parameter : Router_declaration.parameter) body ->
      B.pexp_fun ~loc (Labelled parameter.name) None (B.pvar ~loc parameter.name) body)
    parameters body

let route_function_expression ~loc parameters search body =
  route_input_expression ~loc parameters search (B.pexp_fun ~loc Nolabel None (B.punit ~loc) body)

let apply_route_inputs ~loc callee parameters search =
  let arguments =
    List.map
      (fun (parameter : Router_declaration.parameter) -> (Labelled parameter.name, B.evar ~loc parameter.name))
      parameters
    @ List.map
        (fun (search : Router_declaration.search) -> (search_argument_label search, B.evar ~loc search.name))
        search
    @ [ (Nolabel, unit_expression ~loc) ]
  in
  B.pexp_apply ~loc callee arguments

let route_signature (route : Router_declaration.route) =
  let loc = route.loc in
  let destination_type = result_type ~loc "destination" in
  let link_make =
    B.value_description ~loc ~name:{ txt = "make"; loc }
      ~type_:(link_component_type ~loc route.parameters route.search)
      ~prim:[]
  in
  let link_make = { link_make with pval_attributes = [ react_component_attribute ~loc ] } in
  let module_items =
    [
      B.psig_value ~loc
        (B.value_description ~loc ~name:{ txt = "destination"; loc }
           ~type_:(route_function_type ~loc route.parameters route.search destination_type)
           ~prim:[]);
      B.psig_value ~loc
        (B.value_description ~loc ~name:{ txt = "href"; loc }
           ~type_:(route_function_type ~loc route.parameters route.search (result_type ~loc "string"))
           ~prim:[]);
      B.psig_value ~loc link_make;
    ]
  in
  B.psig_module ~loc
    (B.module_declaration ~loc ~name:{ txt = Some route.name; loc } ~type_:(B.pmty_signature ~loc module_items))

let public_modules = [ "Status"; "Loader"; "Error"; "Metadata"; "Headers"; "Navigation" ]

let signature_alias ~loc name =
  B.psig_module ~loc
    (B.module_declaration ~loc ~name:{ txt = Some name; loc }
       ~type_:(B.pmty_alias ~loc { txt = Longident.parse ("RouterRuntime." ^ name); loc }))

let structure_alias ~loc name =
  B.pstr_module ~loc
    (B.module_binding ~loc ~name:{ txt = Some name; loc }
       ~expr:(B.pmod_ident ~loc { txt = Longident.parse ("RouterRuntime." ^ name); loc }))

let search_contract_signature ~loc search =
  if search = [] then []
  else
    [
      B.psig_type ~loc Recursive [ search_type_declaration ~loc search ];
      B.psig_value ~loc
        (B.value_description ~loc ~name:{ txt = "useSearch"; loc }
           ~type_:
             (B.ptyp_arrow ~loc Nolabel (unit_type ~loc)
                (B.ptyp_tuple ~loc [ result_type ~loc "search"; update_search_function_type ~loc search ]))
           ~prim:[]);
    ]

let signature (declaration : Router_declaration.t) =
  let loc = declaration.loc in
  let routes = Router_declaration.routes declaration in
  let root_search = Router_declaration.root_search declaration in
  B.psig_type ~loc Recursive
    [ destination_declaration ~loc ~private_:Public ~manifest:(Some (result_type ~loc "RouterRuntime.destination")) ]
  :: List.map (signature_alias ~loc) public_modules
  @ [ B.psig_type ~loc Recursive [ route_type_declaration ~loc routes ] ]
  @ [
      B.psig_value ~loc
        (B.value_description ~loc ~name:{ txt = "useNavigation"; loc }
           ~type_:
             (B.ptyp_arrow ~loc Nolabel (unit_type ~loc)
                (B.ptyp_tuple ~loc [ navigate_type ~loc; result_type ~loc "Navigation.status" ]))
           ~prim:[]);
      B.psig_value ~loc
        (B.value_description ~loc ~name:{ txt = "useUpdateHash"; loc }
           ~type_:(B.ptyp_arrow ~loc Nolabel (unit_type ~loc) (update_hash_type ~loc))
           ~prim:[]);
      B.psig_value ~loc
        (B.value_description ~loc ~name:{ txt = "useRoute"; loc }
           ~type_:(B.ptyp_arrow ~loc Nolabel (unit_type ~loc) (option_type ~loc (result_type ~loc "route")))
           ~prim:[]);
    ]
  @ search_contract_signature ~loc root_search
  @ List.map route_signature routes

let route_module ~base_path (route : Router_declaration.route) =
  let loc = route.loc in
  let parameter_values =
    List.map
      (fun (parameter : Router_declaration.parameter) ->
        let printed =
          B.pexp_apply ~loc
            (B.pexp_ident ~loc { txt = parameter.to_string; loc })
            [ (Nolabel, B.evar ~loc parameter.name) ]
        in
        B.pexp_tuple ~loc [ B.estring ~loc parameter.name; printed ])
      route.parameters
  in
  let print_value to_string value =
    B.pexp_apply ~loc (B.pexp_ident ~loc { txt = to_string; loc }) [ (Nolabel, value) ]
  in
  let search_pair name values = B.pexp_tuple ~loc [ B.estring ~loc name; values ] in
  let optional_search_entries (search : Router_declaration.search) value_body =
    let mapper = B.pexp_fun ~loc Nolabel None (B.pvar ~loc "value") value_body in
    let mapped =
      B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.map") [ (Nolabel, mapper); (Nolabel, B.evar ~loc search.name) ]
    in
    B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.to_list") [ (Nolabel, mapped) ]
  in
  let search_entries =
    List.map
      (fun (search : Router_declaration.search) ->
        let printed value = print_value search.to_string value in
        match search.kind with
        | Required -> B.elist ~loc [ search_pair search.name (B.elist ~loc [ printed (B.evar ~loc search.name) ]) ]
        | Optional ->
            optional_search_entries search (search_pair search.name (B.elist ~loc [ printed (B.evar ~loc "value") ]))
        | Default default ->
            let printed_value = printed (B.evar ~loc "value") in
            let printed_default = printed default in
            let value_body =
              B.pexp_ifthenelse ~loc
                (B.pexp_apply ~loc (B.evar ~loc "Stdlib.String.equal")
                   [ (Nolabel, printed_value); (Nolabel, printed_default) ])
                (B.elist ~loc [])
                (Some (B.elist ~loc [ search_pair search.name (B.elist ~loc [ printed_value ]) ]))
            in
            let mapper = B.pexp_fun ~loc Nolabel None (B.pvar ~loc "value") value_body in
            let mapped =
              B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.map")
                [ (Nolabel, mapper); (Nolabel, B.evar ~loc search.name) ]
            in
            let nested = B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.to_list") [ (Nolabel, mapped) ] in
            B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.concat") [ (Nolabel, nested) ]
        | Many ->
            let values =
              B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.map")
                [
                  (Nolabel, B.pexp_fun ~loc Nolabel None (B.pvar ~loc "item") (printed (B.evar ~loc "item")));
                  (Nolabel, B.evar ~loc "value");
                ]
            in
            optional_search_entries search (search_pair search.name values))
      route.search
  in
  let search_values = B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.concat") [ (Nolabel, B.elist ~loc search_entries) ] in
  let pattern_source =
    if String.equal route.path "/" && not (String.equal base_path "") then base_path else base_path ^ route.path
  in
  let pattern = B.pexp_apply ~loc (B.evar ~loc "RouterRuntime.pattern") [ (Nolabel, B.estring ~loc pattern_source) ] in
  let destination_body =
    B.pexp_apply ~loc
      (B.evar ~loc "RouterRuntime.destinationFromPattern")
      [
        (Labelled "pattern", B.evar ~loc "pattern");
        (Labelled "parameters", B.elist ~loc parameter_values);
        (Labelled "search", search_values);
      ]
  in
  let destination_expression = route_function_expression ~loc route.parameters route.search destination_body in
  let destination_call = apply_route_inputs ~loc (B.evar ~loc "destination") route.parameters route.search in
  let href_body = B.pexp_apply ~loc (B.evar ~loc "RouterRuntime.href") [ (Nolabel, destination_call) ] in
  let href_expression = route_function_expression ~loc route.parameters route.search href_body in
  let link_body =
    B.pexp_apply ~loc (B.evar ~loc "RouterReact.link")
      [
        (Labelled "destination", destination_call);
        (Optional "className", B.evar ~loc "className");
        (Optional "target", B.evar ~loc "target");
        (Optional "download", B.evar ~loc "download");
        (Optional "ariaCurrent", B.evar ~loc "ariaCurrent");
        (Optional "history", B.evar ~loc "history");
        (Optional "revalidate", B.evar ~loc "revalidate");
        (Labelled "children", B.evar ~loc "children");
        (Nolabel, unit_expression ~loc);
      ]
  in
  let link_with_unit = B.pexp_fun ~loc Nolabel None (B.punit ~loc) link_body in
  let link_with_children = B.pexp_fun ~loc (Labelled "children") None (B.pvar ~loc "children") link_with_unit in
  let link_with_revalidate =
    B.pexp_fun ~loc (Optional "revalidate") None (B.pvar ~loc "revalidate") link_with_children
  in
  let link_with_history = B.pexp_fun ~loc (Optional "history") None (B.pvar ~loc "history") link_with_revalidate in
  let link_with_aria_current =
    B.pexp_fun ~loc (Optional "ariaCurrent") None (B.pvar ~loc "ariaCurrent") link_with_history
  in
  let link_with_download = B.pexp_fun ~loc (Optional "download") None (B.pvar ~loc "download") link_with_aria_current in
  let link_with_target = B.pexp_fun ~loc (Optional "target") None (B.pvar ~loc "target") link_with_download in
  let link_with_class_name = B.pexp_fun ~loc (Optional "className") None (B.pvar ~loc "className") link_with_target in
  let link_expression = route_input_expression ~loc route.parameters route.search link_with_class_name in
  let link_binding = B.value_binding ~loc ~pat:(B.pvar ~loc "make") ~expr:link_expression in
  let link_binding = { link_binding with pvb_attributes = [ react_component_attribute ~loc ] } in
  let module_expression =
    B.pmod_structure ~loc
      [
        B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "pattern") ~expr:pattern ];
        B.pstr_value ~loc Nonrecursive
          [ B.value_binding ~loc ~pat:(B.pvar ~loc "destination") ~expr:destination_expression ];
        B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "href") ~expr:href_expression ];
        B.pstr_value ~loc Nonrecursive [ link_binding ];
      ]
  in
  B.pstr_module ~loc (B.module_binding ~loc ~name:{ txt = Some route.name; loc } ~expr:module_expression)

let search_decoder ~loc (search : Router_declaration.search) =
  let callee =
    match search.kind with
    | Required -> "RouterRuntime.Search.required"
    | Optional -> "RouterRuntime.Search.optional"
    | Default _ -> "RouterRuntime.Search.default"
    | Many -> "RouterRuntime.Search.many"
  in
  let arguments =
    [
      (Labelled "name", B.estring ~loc search.name); (Labelled "parse", B.pexp_ident ~loc { txt = search.parser; loc });
    ]
    @ (match search.kind with Default fallback -> [ (Labelled "fallback", fallback) ] | _ -> [])
    @ [ (Nolabel, B.evar ~loc "values") ]
  in
  B.pexp_apply ~loc (B.evar ~loc callee) arguments

let search_pair ~loc name values = B.pexp_tuple ~loc [ B.estring ~loc name; values ]

let print_search_value ~loc (search : Router_declaration.search) value =
  B.pexp_apply ~loc (B.pexp_ident ~loc { txt = search.to_string; loc }) [ (Nolabel, value) ]

let search_update_entry ~loc (search : Router_declaration.search) =
  let variable = B.evar ~loc search.name in
  match search.kind with
  | Required -> B.elist ~loc [ search_pair ~loc search.name (B.elist ~loc [ print_search_value ~loc search variable ]) ]
  | Optional ->
      let value = B.evar ~loc "value" in
      let pair = search_pair ~loc search.name (B.elist ~loc [ print_search_value ~loc search value ]) in
      let mapped =
        B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.map")
          [ (Nolabel, B.pexp_fun ~loc Nolabel None (B.pvar ~loc "value") pair); (Nolabel, variable) ]
      in
      B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.to_list") [ (Nolabel, mapped) ]
  | Default fallback ->
      let printed_value = print_search_value ~loc search variable in
      let printed_default = print_search_value ~loc search fallback in
      B.pexp_ifthenelse ~loc
        (B.pexp_apply ~loc (B.evar ~loc "Stdlib.String.equal") [ (Nolabel, printed_value); (Nolabel, printed_default) ])
        (B.elist ~loc [])
        (Some (B.elist ~loc [ search_pair ~loc search.name (B.elist ~loc [ printed_value ]) ]))
  | Many ->
      let values =
        B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.map")
          [
            ( Nolabel,
              B.pexp_fun ~loc Nolabel None (B.pvar ~loc "value") (print_search_value ~loc search (B.evar ~loc "value"))
            );
            (Nolabel, variable);
          ]
      in
      B.elist ~loc [ search_pair ~loc search.name values ]

let search_contract_structure ~loc search =
  if search = [] then []
  else
    let update_body =
      let values =
        B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.concat")
          [ (Nolabel, B.elist ~loc (List.map (search_update_entry ~loc) search)) ]
      in
      B.pexp_apply ~loc (B.evar ~loc "updateSearch")
        [
          ( Labelled "owned",
            B.elist ~loc (List.map (fun (item : Router_declaration.search) -> B.estring ~loc item.name) search) );
          (Labelled "values", values);
          (Optional "history", B.evar ~loc "history");
          (Nolabel, unit_expression ~loc);
        ]
    in
    let update_with_unit = B.pexp_fun ~loc Nolabel None (B.punit ~loc) update_body in
    let update_with_options = B.pexp_fun ~loc (Optional "history") None (B.pvar ~loc "history") update_with_unit in
    let update_function =
      List.fold_right
        (fun (search : Router_declaration.search) body ->
          B.pexp_fun ~loc (Labelled search.name) None (B.pvar ~loc search.name) body)
        search update_with_options
    in
    let mapper = B.pexp_fun ~loc Nolabel None (B.pvar ~loc "updateSearch") update_function in
    let use_search =
      let record =
        B.pexp_record ~loc
          (List.map
             (fun (search : Router_declaration.search) ->
               ({ txt = Longident.Lident search.name; loc = search.loc }, search_decoder ~loc:search.loc search))
             search)
          None
      in
      let update_search = B.pexp_apply ~loc mapper [ (Nolabel, B.evar ~loc "updateSearch") ] in
      let body =
        B.pexp_let ~loc Nonrecursive
          [
            B.value_binding ~loc
              ~pat:(B.ppat_tuple ~loc [ B.pvar ~loc "values"; B.pvar ~loc "updateSearch" ])
              ~expr:(B.pexp_apply ~loc (B.evar ~loc "RouterReact.useSearch") [ (Nolabel, unit_expression ~loc) ]);
          ]
          (B.pexp_tuple ~loc [ record; update_search ])
      in
      B.pexp_fun ~loc Nolabel None (B.punit ~loc) body
    in
    [
      B.pstr_type ~loc Recursive [ search_type_declaration ~loc search ];
      B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "useSearch") ~expr:use_search ];
    ]

let handles (declaration : Router_declaration.t) =
  let base_path = if declaration.base_path = "/" then "" else declaration.base_path in
  let loc = declaration.loc in
  let routes = Router_declaration.routes declaration in
  let root_search = Router_declaration.root_search declaration in
  B.pstr_type ~loc Recursive
    [ destination_declaration ~loc ~private_:Public ~manifest:(Some (result_type ~loc "RouterRuntime.destination")) ]
  :: List.map (structure_alias ~loc) public_modules
  @ [ B.pstr_type ~loc Recursive [ route_type_declaration ~loc routes ] ]
  @ [
      B.pstr_value ~loc Nonrecursive
        [ B.value_binding ~loc ~pat:(B.pvar ~loc "useNavigation") ~expr:(B.evar ~loc "RouterReact.useNavigation") ];
      B.pstr_value ~loc Nonrecursive
        [ B.value_binding ~loc ~pat:(B.pvar ~loc "useUpdateHash") ~expr:(B.evar ~loc "RouterReact.useUpdateHash") ];
      B.pstr_value ~loc Nonrecursive
        [ B.value_binding ~loc ~pat:(B.pvar ~loc "useRoute") ~expr:(use_route_expression ~loc routes) ];
    ]
  @ search_contract_structure ~loc root_search
  @ List.map (route_module ~base_path) routes

let apply_native_inputs_with ~loc callee parameters search loaders extra =
  let arguments =
    List.map
      (fun (parameter : Router_declaration.parameter) -> (Labelled parameter.name, B.evar ~loc parameter.name))
      parameters
    @ List.map (fun (search : Router_declaration.search) -> (Labelled search.name, B.evar ~loc search.name)) search
    @ List.map (fun name -> (Labelled name, B.evar ~loc name)) loaders
    @ extra
    @ [ (Nolabel, unit_expression ~loc) ]
  in
  B.pexp_apply ~loc callee arguments

let apply_native_inputs ~loc callee parameters search loaders =
  apply_native_inputs_with ~loc callee parameters search loaders []

let component_props ~loc component =
  match component.pexp_desc with
  | Pexp_ident { txt = Longident.Ldot (parent, "make"); _ } ->
      B.pexp_ident ~loc { txt = Longident.Ldot (parent, "makeProps"); loc }
  | _ ->
      Location.raise_errorf ~loc:component.pexp_loc
        "router: component attachments must use a qualified Module.make identifier"

let apply_native_component_inputs_with ~loc component parameters search loaders extra =
  let props = apply_native_inputs_with ~loc (component_props ~loc component) parameters search loaders extra in
  B.pexp_apply ~loc component [ (Nolabel, props) ]

let apply_native_component_inputs ~loc component parameters search loaders =
  apply_native_component_inputs_with ~loc component parameters search loaders []

let native_path_decoder ~loc (parameter : Router_declaration.parameter) =
  B.pexp_apply ~loc
    (B.evar ~loc "RouterServer.Decode.path")
    [
      (Labelled "input", B.evar ~loc "input");
      (Labelled "name", B.estring ~loc parameter.name);
      (Labelled "parse", B.pexp_ident ~loc { txt = parameter.parser; loc });
    ]

let native_search_decoder ~loc (search : Router_declaration.search) =
  let callee =
    match search.kind with
    | Required -> "RouterServer.Decode.searchRequired"
    | Optional -> "RouterServer.Decode.searchOptional"
    | Default _ -> "RouterServer.Decode.searchDefault"
    | Many -> "RouterServer.Decode.searchMany"
  in
  let arguments =
    [
      (Labelled "input", B.evar ~loc "input");
      (Labelled "name", B.estring ~loc search.name);
      (Labelled "parse", B.pexp_ident ~loc { txt = search.parser; loc });
    ]
    @ match search.kind with Default fallback -> [ (Labelled "fallback", fallback) ] | _ -> []
  in
  B.pexp_apply ~loc (B.evar ~loc callee) arguments

let bind_decode ~loc name decoder body =
  B.pexp_apply ~loc (B.evar ~loc "Stdlib.Result.bind")
    [ (Nolabel, decoder); (Nolabel, B.pexp_fun ~loc Nolabel None (B.pvar ~loc name) body) ]

let boundary_callback ~loc attachment parameters search loaders =
  let call =
    apply_native_component_inputs_with ~loc attachment parameters search loaders
      [ (Labelled "error", B.evar ~loc "error") ]
  in
  B.pexp_fun ~loc Nolabel None (B.pvar ~loc "error") call

let canonical_parameters ~loc parameters =
  List.map
    (fun (parameter : Router_declaration.parameter) ->
      let value =
        B.pexp_apply ~loc
          (B.pexp_ident ~loc { txt = parameter.to_string; loc })
          [ (Nolabel, B.evar ~loc parameter.name) ]
      in
      B.pexp_tuple ~loc [ B.estring ~loc parameter.name; value ])
    parameters

let branch_scope ~loc (scope : Router_declaration.scope) parameters ~reusable =
  B.pexp_apply ~loc
    (B.evar ~loc "RouterServer.Branch.Scope.make")
    [
      (Labelled "id", B.estring ~loc scope.id);
      (Labelled "parameters", B.elist ~loc (canonical_parameters ~loc parameters));
      (Labelled "reusable", B.ebool ~loc reusable);
    ]

let scope_plan (scope : Router_declaration.scope) parameters search loaders ~reusable =
  let loc = scope.loc in
  let callback attachment = apply_native_inputs ~loc attachment parameters search loaders in
  let component attachment = apply_native_component_inputs ~loc attachment parameters search loaders in
  let arguments =
    (match (scope.attachments.layout, scope.attachments.loading) with
      | None, None -> []
      | layout, loading ->
          let identity = branch_scope ~loc scope parameters ~reusable in
          let instance_key =
            B.pexp_apply ~loc (B.evar ~loc "RouterServer.Branch.Scope.instanceKey") [ (Nolabel, identity) ]
          in
          let children = B.evar ~loc "children" in
          let body =
            match layout with
            | None -> children
            | Some layout ->
                let outlet =
                  B.pexp_apply ~loc (B.evar ~loc "RouterReact.outlet")
                    [
                      (Labelled "owner", instance_key); (Labelled "children", children); (Nolabel, unit_expression ~loc);
                    ]
                in
                apply_native_component_inputs_with ~loc layout parameters search loaders
                  [ (Labelled "children", outlet) ]
          in
          let body =
            match loading with
            | None -> body
            | Some loading ->
                B.pexp_apply ~loc (B.evar ~loc "RouterReact.suspense")
                  [
                    (Labelled "fallback", component loading);
                    (Labelled "children", body);
                    (Nolabel, unit_expression ~loc);
                  ]
          in
          [ (Labelled "layout", B.pexp_fun ~loc Nolabel None (B.pvar ~loc "children") body) ])
    @ optional_argument "metadata"
        (Option.map
           (fun metadata -> B.pexp_fun ~loc Nolabel None (B.punit ~loc) (callback metadata))
           scope.attachments.metadata)
    @ optional_argument "headers"
        (Option.map
           (fun headers -> B.pexp_fun ~loc Nolabel None (B.punit ~loc) (callback headers))
           scope.attachments.headers)
    @ [ (Nolabel, unit_expression ~loc) ]
  in
  B.pexp_apply ~loc (B.evar ~loc "RouterServer.Plan.Scope.make") arguments

let failure_plan ~loc scopes error not_found error_boundary =
  let arguments =
    [ (Labelled "scopes", B.elist ~loc scopes); (Labelled "error", error) ]
    @ optional_argument "notFound" not_found
    @ optional_argument "errorBoundary" error_boundary
    @ [ (Nolabel, unit_expression ~loc) ]
  in
  B.pexp_apply ~loc (B.evar ~loc "RouterServer.Plan.failure") arguments

let loader_execution (route : Router_declaration.route) =
  let loc = route.loc in
  let rec build scopes parameters search loader_values completed not_found error_boundary loader_seen =
    match scopes with
    | [] ->
        let page =
          apply_native_component_inputs ~loc route.page route.parameters route.search loader_values |> fun page ->
          B.pexp_constraint ~loc page (result_type ~loc "React.element")
        in
        let plan =
          B.pexp_apply ~loc
            (B.evar ~loc "RouterServer.Plan.success")
            [ (Labelled "scopes", B.elist ~loc completed); (Labelled "page", page) ]
        in
        B.pexp_apply ~loc (B.evar ~loc "RouterServer.Execution.done_") [ (Nolabel, plan) ]
    | (scope : Router_declaration.scope) :: rest -> (
        let parameters = parameters @ scope.Router_declaration.parameters in
        let search = search @ scope.search in
        let not_found =
          match scope.attachments.not_found with
          | Some boundary -> Some (boundary_callback ~loc:scope.loc boundary parameters search loader_values)
          | None -> not_found
        in
        let error_boundary =
          match scope.attachments.error with
          | Some boundary -> Some (boundary_callback ~loc:scope.loc boundary parameters search loader_values)
          | None -> error_boundary
        in
        match scope.attachments.loader with
        | None ->
            let reusable = (not loader_seen) && Option.is_some scope.attachments.layout in
            let current = scope_plan scope parameters search loader_values ~reusable in
            build rest parameters search loader_values (completed @ [ current ]) not_found error_boundary loader_seen
        | Some loader ->
            let run_call = apply_native_inputs ~loc:loader.loc loader.run parameters search loader_values in
            let run = B.pexp_fun ~loc:loader.loc Nolabel None (B.punit ~loc:loader.loc) run_call in
            let next_loaders = loader_values @ [ loader.result_label ] in
            let current = scope_plan scope parameters search next_loaders ~reusable:false in
            let next_body =
              build rest parameters search next_loaders (completed @ [ current ]) not_found error_boundary true
            in
            let next = B.pexp_fun ~loc:loader.loc Nolabel None (B.pvar ~loc:loader.loc loader.result_label) next_body in
            let failed =
              failure_plan ~loc:loader.loc completed (B.evar ~loc:loader.loc "error") not_found error_boundary
            in
            let failure = B.pexp_fun ~loc:loader.loc Nolabel None (B.pvar ~loc:loader.loc "error") failed in
            B.pexp_apply ~loc:loader.loc
              (B.evar ~loc:loader.loc "RouterServer.Execution.loadWithBoundary")
              [ (Labelled "run", run); (Labelled "failure", failure); (Labelled "next", next) ])
  in
  build route.scopes [] [] [] [] None None false

let projected_branch (route : Router_declaration.route) =
  let loc = route.loc in
  let rec build scopes parameters loader_seen projected =
    match scopes with
    | [] -> B.elist ~loc projected
    | (scope : Router_declaration.scope) :: scopes ->
        let parameters = parameters @ scope.parameters in
        let has_loader = Option.is_some scope.attachments.loader in
        let reusable = (not loader_seen) && (not has_loader) && Option.is_some scope.attachments.layout in
        let projected = projected @ [ branch_scope ~loc:scope.loc scope parameters ~reusable ] in
        build scopes parameters (loader_seen || has_loader) projected
  in
  build route.scopes [] false []

let parsed_path path =
  match RouterPattern.parse path with
  | Ok pattern -> pattern
  | Error _ -> invalid_arg "validated router path failed to parse"

let percent_encode value =
  let hex = "0123456789ABCDEF" in
  let unescaped = function
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '_' | '.' | '!' | '~' | '*' | '\'' | '(' | ')' -> true
    | _ -> false
  in
  let buffer = Buffer.create (String.length value) in
  String.iter
    (fun character ->
      if unescaped character then Buffer.add_char buffer character
      else
        let code = Char.code character in
        Buffer.add_char buffer '%';
        Buffer.add_char buffer hex.[code lsr 4];
        Buffer.add_char buffer hex.[code land 0x0f])
    value;
  Buffer.contents buffer

let encoded_path path =
  match RouterPattern.render (parsed_path path) ~parameter:(fun _ -> None) ~encode:percent_encode with
  | Ok path -> path
  | Error _ -> invalid_arg "static router path unexpectedly required a parameter"

let type_string typ = Format.asprintf "%a" Pprintast.core_type typ
let expression_string expression = Pprintast.string_of_expression expression

let attachment_part name = function
  | None -> name ^ ":none"
  | Some expression -> name ^ ":" ^ expression_string expression

let search_kind_part (search : Router_declaration.search) =
  match search.kind with
  | Required -> "required"
  | Optional -> "optional"
  | Many -> "many"
  | Default fallback -> "default:" ^ expression_string fallback

let fingerprint_parts (route : Router_declaration.route) =
  let route_parts = [ "route:" ^ route.name; "path:" ^ route.path ] in
  let parameter_parts =
    List.map
      (fun (parameter : Router_declaration.parameter) ->
        "parameter:" ^ parameter.name ^ ":" ^ type_string parameter.typ)
      route.parameters
  in
  let search_parts =
    List.map
      (fun (search : Router_declaration.search) ->
        "search:" ^ search.name ^ ":" ^ type_string search.typ ^ ":" ^ search_kind_part search)
      route.search
  in
  let scope_parts =
    List.concat_map
      (fun (scope : Router_declaration.scope) ->
        let attachments = scope.attachments in
        [
          "scope:" ^ scope.id ^ ":" ^ scope.path;
          attachment_part "layout" attachments.layout;
          attachment_part "loading" attachments.loading;
          attachment_part "notFound" attachments.not_found;
          attachment_part "error" attachments.error;
          (match attachments.loader with
          | None -> "loader:none"
          | Some loader -> "loader:" ^ loader.result_label ^ ":" ^ expression_string loader.run);
          attachment_part "metadata" attachments.metadata;
          attachment_part "headers" attachments.headers;
        ])
      route.scopes
  in
  route_parts @ parameter_parts @ search_parts @ scope_parts

let endpoint ~base_path ~invalid_search ~routes (route : Router_declaration.route) =
  let loc = route.loc in
  let route_pattern = parsed_path route.path in
  let execution = loader_execution route in
  let prepared =
    B.pexp_apply ~loc
      (B.evar ~loc "RouterServer.Endpoint.prepared")
      [
        (Labelled "branch", projected_branch route);
        (Labelled "execution", B.pexp_fun ~loc Nolabel None (B.punit ~loc) execution);
      ]
    |> fun prepared -> B.pexp_construct ~loc { txt = Longident.Lident "Ok"; loc } (Some prepared)
  in
  let decoded_search =
    List.fold_right
      (fun (search : Router_declaration.search) body ->
        bind_decode ~loc:search.loc search.name (native_search_decoder ~loc:search.loc search) body)
      route.search prepared
  in
  let decoded =
    List.fold_right
      (fun (parameter : Router_declaration.parameter) body ->
        bind_decode ~loc:parameter.loc parameter.name (native_path_decoder ~loc:parameter.loc parameter) body)
      route.parameters decoded_search
  in
  let decode = B.pexp_fun ~loc Nolabel None (B.pvar ~loc "input") decoded in
  let active_routes =
    routes
    |> List.filter (fun (_, candidate_pattern) -> RouterPattern.isPrefix ~prefix:candidate_pattern route_pattern)
    |> List.sort (fun ((left : Router_declaration.route), left_pattern) (right, right_pattern) ->
        match
          Int.compare
            (List.length (RouterPattern.segments left_pattern))
            (List.length (RouterPattern.segments right_pattern))
        with
        | 0 -> String.compare left.name right.name
        | order -> order)
    |> List.map (fun ((candidate : Router_declaration.route), _) ->
        B.pexp_tuple ~loc
          [
            B.estring ~loc candidate.name;
            B.elist ~loc
              (List.map
                 (fun (parameter : Router_declaration.parameter) -> B.estring ~loc parameter.name)
                 candidate.parameters);
          ])
  in
  let fingerprint =
    [ "basePath:" ^ base_path; attachment_part "invalidSearch" invalid_search ] @ fingerprint_parts route
    |> String.concat "\n" |> Digest.string |> Digest.to_hex
  in
  B.pexp_apply ~loc
    (B.evar ~loc "RouterServer.Endpoint.make")
    [
      (Labelled "id", B.estring ~loc route.name);
      (Labelled "path", B.estring ~loc route.path);
      (Labelled "activeRoutes", B.elist ~loc active_routes);
      (Labelled "fingerprint", B.estring ~loc fingerprint);
      (Labelled "decode", decode);
    ]

let fallback (declaration : Router_declaration.t) =
  let loc = declaration.loc in
  let scope = declaration.root.scope in
  let search = Router_declaration.root_search declaration in
  let not_found =
    Option.map (fun boundary -> boundary_callback ~loc:scope.loc boundary [] search []) scope.attachments.not_found
  in
  let error_boundary =
    Option.map (fun boundary -> boundary_callback ~loc:scope.loc boundary [] search []) scope.attachments.error
  in
  let completed =
    match scope.attachments.loader with Some _ -> [] | None -> [ scope_plan scope [] search [] ~reusable:true ]
  in
  let planned = failure_plan ~loc completed (B.evar ~loc "error") not_found error_boundary in
  let decoded =
    List.fold_right
      (fun (search : Router_declaration.search) body ->
        bind_decode ~loc:search.loc search.name (native_search_decoder ~loc:search.loc search) body)
      search
      (B.pexp_construct ~loc { txt = Longident.Lident "Ok"; loc } (Some planned))
  in
  let decode_failure =
    let invalid_search_boundary =
      Option.map (fun boundary -> boundary_callback ~loc:boundary.pexp_loc boundary [] [] []) declaration.invalid_search
    in
    let recovery =
      List.map
        (fun (search : Router_declaration.search) ->
          let expression =
            match search.kind with
            | Required -> None
            | Optional ->
                Some (B.pexp_construct ~loc:search.loc { txt = Longident.Lident "None"; loc = search.loc } None)
            | Default fallback -> Some fallback
            | Many -> Some (B.elist ~loc:search.loc [])
          in
          Option.map (fun expression -> (search, expression)) expression)
        search
    in
    let failed =
      match invalid_search_boundary with
      | Some boundary -> failure_plan ~loc [] (B.evar ~loc "decodeError") None (Some boundary)
      | None when Option.is_some error_boundary && List.for_all Option.is_some recovery -> (
          let bindings =
            List.filter_map
              (fun item ->
                Option.map
                  (fun ((search : Router_declaration.search), expression) ->
                    B.value_binding ~loc:search.loc ~pat:(B.pvar ~loc:search.loc search.name) ~expr:expression)
                  item)
              recovery
          in
          let plan = failure_plan ~loc completed (B.evar ~loc "decodeError") not_found error_boundary in
          match bindings with [] -> plan | _ -> B.pexp_let ~loc Nonrecursive bindings plan)
      | None -> failure_plan ~loc [] (B.evar ~loc "decodeError") None None
    in
    B.pexp_fun ~loc Nolabel None (B.pvar ~loc "decodeError") failed
  in
  let folded =
    B.pexp_apply ~loc (B.evar ~loc "Stdlib.Result.fold")
      [ (Labelled "ok", B.evar ~loc "Stdlib.Fun.id"); (Labelled "error", decode_failure); (Nolabel, decoded) ]
  in
  let with_input =
    B.pexp_let ~loc Nonrecursive
      [
        B.value_binding ~loc ~pat:(B.pvar ~loc "input")
          ~expr:(B.pexp_apply ~loc (B.evar ~loc "RouterServer.Input.forSearch") [ (Nolabel, B.evar ~loc "search") ]);
      ]
      folded
  in
  B.pexp_fun ~loc (Labelled "search") None (B.pvar ~loc "search")
    (B.pexp_fun ~loc (Labelled "error") None (B.pvar ~loc "error") with_input)

let registry (declaration : Router_declaration.t) =
  let loc = declaration.loc in
  let routes = Router_declaration.routes declaration in
  let parsed_routes = List.map (fun (route : Router_declaration.route) -> (route, parsed_path route.path)) routes in
  let route_values =
    List.map
      (endpoint ~base_path:declaration.base_path ~invalid_search:declaration.invalid_search ~routes:parsed_routes)
      routes
  in
  let base_path =
    B.pstr_value ~loc Nonrecursive
      [ B.value_binding ~loc ~pat:(B.pvar ~loc "basePath") ~expr:(B.estring ~loc (encoded_path declaration.base_path)) ]
  in
  let error_type =
    match declaration.application_error with
    | Some policy -> B.ptyp_constr ~loc { txt = Longident.Ldot (policy, "t"); loc } []
    | None -> unit_type ~loc
  in
  let plan_type =
    B.ptyp_constr ~loc
      { txt = Longident.parse "RouterServer.Plan.t"; loc }
      [ result_type ~loc "React.element"; error_type ]
  in
  let registry_type =
    B.ptyp_constr ~loc { txt = Longident.parse "RouterServer.EndpointRegistry.t"; loc } [ plan_type; error_type ]
  in
  let registry =
    B.pstr_value ~loc Nonrecursive
      [
        B.value_binding ~loc
          ~pat:(B.ppat_constraint ~loc (B.pvar ~loc "registry") registry_type)
          ~expr:
            (B.pexp_apply ~loc
               (B.evar ~loc "RouterServer.EndpointRegistry.makeExn")
               [ (Nolabel, B.elist ~loc route_values) ]);
      ]
  in
  let fallback =
    B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "fallback") ~expr:(fallback declaration) ]
  in
  let application_status =
    let expression =
      match declaration.application_error with
      | Some policy -> B.pexp_ident ~loc { txt = Longident.Ldot (policy, "status"); loc }
      | None ->
          let body =
            B.pexp_construct ~loc { txt = Longident.parse "RouterRuntime.Status.InternalServerError"; loc } None
          in
          B.pexp_fun ~loc Nolabel None (B.ppat_any ~loc) body
    in
    B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "applicationStatus") ~expr:expression ]
  in
  let server =
    let expression =
      B.pexp_apply ~loc
        (B.evar ~loc "RouterServer.Server.make")
        [
          (Labelled "basePath", B.evar ~loc "basePath");
          (Labelled "registry", B.evar ~loc "registry");
          (Labelled "fallback", B.evar ~loc "fallback");
          (Labelled "applicationStatus", B.evar ~loc "applicationStatus");
          (Nolabel, unit_expression ~loc);
        ]
    in
    B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "server") ~expr:expression ]
  in
  [ base_path; registry; fallback; application_status; server ]
