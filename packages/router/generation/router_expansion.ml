open Ppxlib
module B = Ast_builder.Default

let unit_expression ~loc = B.pexp_construct ~loc { txt = Longident.Lident "()"; loc } None
let optional_argument label = function None -> [] | Some expression -> [ (Labelled label, expression) ]
let unit_type ~loc = B.ptyp_constr ~loc { txt = Longident.Lident "unit"; loc } []
let result_type ~loc name = B.ptyp_constr ~loc { txt = Longident.parse name; loc } []
let option_type ~loc typ = B.ptyp_constr ~loc { txt = Longident.Lident "option"; loc } [ typ ]
let list_type ~loc typ = B.ptyp_constr ~loc { txt = Longident.Lident "list"; loc } [ typ ]
let bool_type ~loc = result_type ~loc "bool"

let prefetch_level ~loc (level : Router_declaration.prefetch) =
  let name = match level with Off -> "Off" | Intent -> "Intent" | Viewport -> "Viewport" | Idle -> "Idle" in
  B.pexp_construct ~loc { txt = Longident.parse ("RouterRuntime.PrefetchLevel." ^ name); loc } None

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

let unsafe_destination_type ~loc =
  B.ptyp_arrow ~loc Nolabel (result_type ~loc "string") (result_type ~loc "destination")

let unsafe_destination_expression ~loc =
  B.pexp_fun ~loc Nolabel None (B.pvar ~loc "href")
    (B.pexp_apply ~loc (B.evar ~loc "RouterRuntime.destination") [ (Labelled "path", B.evar ~loc "href") ])

let react_component_attribute ~loc =
  { attr_name = { txt = "react.component"; loc }; attr_payload = PStr []; attr_loc = loc }

let jsx_attribute ~loc = { attr_name = { txt = "JSX"; loc }; attr_payload = PStr []; attr_loc = loc }

let search_destination_type ~loc (search : Router_declaration.search) =
  match search.kind with Required | Optional | Default _ -> search.typ | Many -> list_type ~loc search.typ

let search_value_type ~loc (search : Router_declaration.search) =
  match search.kind with
  | Required | Default _ -> search.typ
  | Optional -> option_type ~loc search.typ
  | Many -> list_type ~loc search.typ

let search_argument_label (search : Router_declaration.search) =
  match search.kind with Required -> Labelled search.name | Optional | Default _ | Many -> Optional search.name

let parameter_label (parameter : Router_declaration.parameter) =
  match parameter.presence with
  | Segment -> Labelled parameter.name
  | OptionalSegment | OptionalRest -> Optional parameter.name

let search_label search =
  if List.exists (fun (search : Router_declaration.search) -> search.kind = Required) search then Labelled "search"
  else Optional "search"

let has_required search = List.exists (fun (search : Router_declaration.search) -> search.kind = Required) search

let decoded_search_type ~loc search =
  if has_required search then option_type ~loc (result_type ~loc "search") else result_type ~loc "search"

let route_input_type ~loc parameters search result =
  let result = B.ptyp_arrow ~loc (Optional "hash") (result_type ~loc "string") result in
  let result =
    match search with [] -> result | _ -> B.ptyp_arrow ~loc (search_label search) (result_type ~loc "search") result
  in
  List.fold_right
    (fun (parameter : Router_declaration.parameter) result ->
      B.ptyp_arrow ~loc (parameter_label parameter) parameter.argument result)
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
  let with_attributes =
    B.ptyp_arrow ~loc (Optional "attributes") (result_type ~loc "RouterReact.Link.attributes") with_class_name
  in
  route_input_type ~loc parameters search with_attributes

let update_search_function_type ~loc =
  B.ptyp_arrow ~loc (Optional "history")
    (result_type ~loc "Navigation.historyAction")
    (B.ptyp_arrow ~loc Nolabel (result_type ~loc "search") (result_type ~loc "Navigation.Result.t"))

let search_constructor_type ~loc search =
  List.fold_right
    (fun (search : Router_declaration.search) result ->
      B.ptyp_arrow ~loc (search_argument_label search) (search_destination_type ~loc search) result)
    search
    (B.ptyp_arrow ~loc Nolabel (unit_type ~loc) (result_type ~loc "search"))

let search_type_declaration ?manifest ?(name = "search") ~loc search =
  let fields =
    List.map
      (fun (search : Router_declaration.search) ->
        B.label_declaration ~loc:search.loc ~name:{ txt = search.name; loc = search.loc } ~mutable_:Immutable
          ~type_:(search_value_type ~loc:search.loc search))
      search
  in
  B.type_declaration ~loc ~name:{ txt = name; loc } ~params:[] ~cstrs:[] ~kind:(Ptype_record fields) ~private_:Public
    ~manifest

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

let absent_value ~loc (parameter : Router_declaration.parameter) =
  match parameter.presence with
  | OptionalSegment -> B.pexp_construct ~loc { txt = Longident.Lident "None"; loc } None
  | OptionalRest -> B.elist ~loc []
  | Segment -> invalid_arg "a required route parameter has no absent value"

let option_bind ~loc option name body =
  B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.bind")
    [ (Nolabel, option); (Nolabel, B.pexp_fun ~loc Nolabel None (B.pvar ~loc name) body) ]

let decode_route_expression (route : Router_declaration.route) =
  let loc = route.loc in
  let route_parameters = route.parameters in
  let decoded (parameter : Router_declaration.parameter) =
    let decoded =
      B.pexp_apply ~loc (B.evar ~loc "decodeRouteParameter")
        [
          (Labelled "name", B.estring ~loc parameter.name);
          (Labelled "parse", B.pexp_ident ~loc { txt = parameter.parser; loc });
          (Nolabel, B.evar ~loc "parameters");
        ]
    in
    match parameter.presence with
    | Segment -> decoded
    | OptionalSegment | OptionalRest ->
        let present =
          match parameter.presence with
          | OptionalSegment ->
              B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.map")
                [ (Nolabel, B.evar ~loc "Stdlib.Option.some"); (Nolabel, decoded) ]
          | Segment | OptionalRest -> decoded
        in
        B.pexp_match ~loc
          (B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.assoc_opt")
             [ (Nolabel, B.estring ~loc parameter.name); (Nolabel, B.evar ~loc "parameters") ])
          [
            B.case
              ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "None"; loc } None)
              ~guard:None
              ~rhs:(some_expression ~loc (absent_value ~loc parameter));
            B.case
              ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "Some"; loc } (Some (B.ppat_any ~loc)))
              ~guard:None ~rhs:present;
          ]
  in
  let route = some_expression ~loc (route_constructor_expression route) in
  match route_parameters with
  | [] -> route
  | parameters ->
      let some name = B.ppat_construct ~loc { txt = Longident.Lident "Some"; loc } (Some (B.pvar ~loc name)) in
      let tuple items = match items with [ item ] -> item | items -> B.ppat_tuple ~loc items in
      let names = List.map (fun (parameter : Router_declaration.parameter) -> parameter.name) parameters in
      B.pexp_let ~loc Nonrecursive
        (List.map
           (fun (parameter : Router_declaration.parameter) ->
             B.value_binding ~loc ~pat:(B.pvar ~loc parameter.name) ~expr:(decoded parameter))
           parameters)
        (B.pexp_match ~loc
           (match names with [ name ] -> B.evar ~loc name | names -> B.pexp_tuple ~loc (List.map (B.evar ~loc) names))
           [
             B.case ~lhs:(tuple (List.map some names)) ~guard:None ~rhs:route;
             B.case ~lhs:(B.ppat_any ~loc) ~guard:None
               ~rhs:(B.pexp_construct ~loc { txt = Longident.Lident "None"; loc } None);
           ])

let decode_route_parameter_expression ~loc =
  let parsed =
    B.pexp_apply ~loc (B.evar ~loc "Stdlib.Result.to_option")
      [ (Nolabel, B.pexp_apply ~loc (B.evar ~loc "parse") [ (Nolabel, B.evar ~loc "raw") ]) ]
  in
  let raw =
    B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.assoc_opt")
      [ (Nolabel, B.evar ~loc "name"); (Nolabel, B.evar ~loc "parameters") ]
  in
  B.pexp_fun ~loc (Labelled "name") None (B.pvar ~loc "name")
    (B.pexp_fun ~loc (Labelled "parse") None (B.pvar ~loc "parse")
       (B.pexp_fun ~loc Nolabel None (B.pvar ~loc "parameters") (option_bind ~loc raw "raw" parsed)))

let decode_route_function ~loc routes =
  let has_parameters =
    List.exists
      (fun (route : Router_declaration.route) -> match route.parameters with [] -> false | _ :: _ -> true)
      routes
  in
  let route_cases =
    List.map
      (fun (route : Router_declaration.route) ->
        B.case
          ~lhs:(B.ppat_constant ~loc:route.loc (Pconst_string (route.name, route.loc, None)))
          ~guard:None ~rhs:(decode_route_expression route))
      routes
  in
  let none = B.pexp_construct ~loc { txt = Longident.Lident "None"; loc } None in
  let body =
    B.pexp_match ~loc (B.evar ~loc "routeId") (route_cases @ [ B.case ~lhs:(B.ppat_any ~loc) ~guard:None ~rhs:none ])
  in
  let body =
    if has_parameters then
      B.pexp_let ~loc Nonrecursive
        [
          B.value_binding ~loc ~pat:(B.pvar ~loc "decodeRouteParameter") ~expr:(decode_route_parameter_expression ~loc);
        ]
        body
    else body
  in
  B.pexp_fun ~loc Nolabel None (B.pvar ~loc "routeId")
    (B.pexp_fun ~loc Nolabel None (B.pvar ~loc (if has_parameters then "parameters" else "_parameters")) body)

let use_route_expression ~loc =
  let current_route =
    B.pexp_apply ~loc (B.evar ~loc "RouterReact.useCurrentRoute") [ (Nolabel, unit_expression ~loc) ]
  in
  let body =
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
          ~guard:None
          ~rhs:
            (B.pexp_apply ~loc (B.evar ~loc "decodeRoute")
               [ (Nolabel, B.evar ~loc "routeId"); (Nolabel, B.evar ~loc "parameters") ]);
      ]
  in
  B.pexp_fun ~loc Nolabel None (B.punit ~loc) body

let use_matches_expression ~loc =
  let matched =
    B.pexp_fun ~loc Nolabel None
      (B.ppat_record ~loc
         [
           ({ txt = Longident.parse "RouterRuntime.Navigation.routeId"; loc }, B.pvar ~loc "routeId");
           ({ txt = Longident.parse "parameters"; loc }, B.pvar ~loc "parameters");
         ]
         Closed)
      (B.pexp_apply ~loc (B.evar ~loc "decodeRoute")
         [ (Nolabel, B.evar ~loc "routeId"); (Nolabel, B.evar ~loc "parameters") ])
  in
  B.pexp_fun ~loc Nolabel None (B.punit ~loc)
    (B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.filter_map")
       [
         (Nolabel, matched);
         (Nolabel, B.pexp_apply ~loc (B.evar ~loc "RouterReact.useMatches") [ (Nolabel, unit_expression ~loc) ]);
       ])

let typed_function ~loc label name typ body =
  let typ = match label with Optional _ -> option_type ~loc typ | Labelled _ | Nolabel -> typ in
  B.pexp_fun ~loc label None (B.ppat_constraint ~loc (B.pvar ~loc name) typ) body

let route_input_expression ~loc parameters search body =
  let body = typed_function ~loc (Optional "hash") "hash" (result_type ~loc "string") body in
  let body =
    match search with
    | [] -> body
    | _ -> typed_function ~loc (search_label search) "search" (result_type ~loc "search") body
  in
  List.fold_right
    (fun (parameter : Router_declaration.parameter) body ->
      typed_function ~loc (parameter_label parameter) parameter.name parameter.argument body)
    parameters body

let route_function_expression ~loc parameters search body =
  route_input_expression ~loc parameters search (B.pexp_fun ~loc Nolabel None (B.punit ~loc) body)

let apply_route_inputs ~loc callee parameters search =
  let arguments =
    List.map
      (fun (parameter : Router_declaration.parameter) -> (parameter_label parameter, B.evar ~loc parameter.name))
      parameters
    @ (match search with [] -> [] | _ -> [ (search_label search, B.evar ~loc "search") ])
    @ [ (Optional "hash", B.evar ~loc "hash"); (Nolabel, unit_expression ~loc) ]
  in
  B.pexp_apply ~loc callee arguments

let search_codec_signature ~loc =
  [
    B.psig_value ~loc
      (B.value_description ~loc ~name:{ txt = "search_to_rsc"; loc }
         ~type_:(B.ptyp_arrow ~loc Nolabel (result_type ~loc "search") (result_type ~loc "RSC.t"))
         ~prim:[]);
    B.psig_value ~loc
      (B.value_description ~loc ~name:{ txt = "search_of_rsc"; loc }
         ~type_:(B.ptyp_arrow ~loc Nolabel (result_type ~loc "RSC.t") (result_type ~loc "search"))
         ~prim:[]);
  ]

let route_owns_search ~root_search search = List.length search <> List.length root_search

let route_search_type ~loc ~root_search search =
  if route_owns_search ~root_search search then (Recursive, search_type_declaration ~loc search)
  else (Nonrecursive, search_type_declaration ~manifest:(result_type ~loc "search") ~loc search)

let use_search_signature ~loc search =
  B.psig_value ~loc
    (B.value_description ~loc ~name:{ txt = "useSearch"; loc }
       ~type_:
         (B.ptyp_arrow ~loc Nolabel (unit_type ~loc)
            (B.ptyp_tuple ~loc [ decoded_search_type ~loc search; update_search_function_type ~loc ]))
       ~prim:[])

let route_search_signature ~loc ~root_search search =
  match search with
  | [] -> []
  | _ ->
      let rec_flag, declaration = route_search_type ~loc ~root_search search in
      [
        B.psig_type ~loc rec_flag [ declaration ];
        B.psig_value ~loc
          (B.value_description ~loc ~name:{ txt = "search"; loc } ~type_:(search_constructor_type ~loc search) ~prim:[]);
      ]
      @ search_codec_signature ~loc
      @ if route_owns_search ~root_search search then [ use_search_signature ~loc search ] else []

let route_signature ~root_search (route : Router_declaration.route) =
  let loc = route.loc in
  let destination_type = result_type ~loc "destination" in
  let link_make =
    B.value_description ~loc ~name:{ txt = "make"; loc }
      ~type_:(link_component_type ~loc route.parameters route.search)
      ~prim:[]
  in
  let link_make = { link_make with pval_attributes = [ react_component_attribute ~loc ] } in
  let module_items =
    route_search_signature ~loc ~root_search route.search
    @ [
        B.psig_value ~loc
          (B.value_description ~loc ~name:{ txt = "destination"; loc }
             ~type_:(route_function_type ~loc route.parameters route.search destination_type)
             ~prim:[]);
        B.psig_value ~loc
          (B.value_description ~loc ~name:{ txt = "href"; loc }
             ~type_:(route_function_type ~loc route.parameters route.search (result_type ~loc "string"))
             ~prim:[]);
      ]
    @ (match route.parameters with
      | [] -> []
      | parameters ->
          let result typ =
            B.ptyp_constr ~loc { txt = Longident.Lident "result"; loc } [ typ; result_type ~loc "string" ]
          in
          [
            B.psig_value ~loc
              (B.value_description ~loc ~name:{ txt = "tryDestination"; loc }
                 ~type_:(route_function_type ~loc parameters route.search (result destination_type))
                 ~prim:[]);
            B.psig_value ~loc
              (B.value_description ~loc ~name:{ txt = "tryHref"; loc }
                 ~type_:(route_function_type ~loc parameters route.search (result (result_type ~loc "string")))
                 ~prim:[]);
          ])
    @ [ B.psig_value ~loc link_make ]
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
    (B.psig_type ~loc Recursive [ search_type_declaration ~loc search ] :: search_codec_signature ~loc)
    @ [ use_search_signature ~loc search ]

let route_hook_types ~loc =
  [
    ("useMatches", B.ptyp_arrow ~loc Nolabel (unit_type ~loc) (list_type ~loc (result_type ~loc "route")));
    ("useLocation", B.ptyp_arrow ~loc Nolabel (unit_type ~loc) (result_type ~loc "Navigation.location"));
    ("useIsCurrent", B.ptyp_arrow ~loc Nolabel (result_type ~loc "destination") (bool_type ~loc));
    ("useBlocker", B.ptyp_arrow ~loc Nolabel (bool_type ~loc) (result_type ~loc "RouterReact.blocker"));
    ( "useInvalidate",
      B.ptyp_arrow ~loc Nolabel (unit_type ~loc)
        (B.ptyp_arrow ~loc Nolabel (result_type ~loc "RouterReact.invalidation") (unit_type ~loc)) );
  ]

let active_search_declaration ~loc routes =
  let constructors =
    List.map
      (fun (route : Router_declaration.route) ->
        let args =
          match route.search with
          | [] -> Pcstr_tuple []
          | _ -> Pcstr_tuple [ result_type ~loc (route.name ^ ".search") ]
        in
        B.constructor_declaration ~loc:route.loc ~name:{ txt = route.name; loc = route.loc } ~args ~res:None)
      routes
  in
  B.type_declaration ~loc ~name:{ txt = "t"; loc } ~params:[] ~cstrs:[] ~kind:(Ptype_variant constructors)
    ~private_:Public ~manifest:None

let active_search_type ~loc = option_type ~loc (result_type ~loc "ActiveSearch.t")

let active_search_signature ~loc routes =
  [
    B.psig_module ~loc
      (B.module_declaration ~loc ~name:{ txt = Some "ActiveSearch"; loc }
         ~type_:(B.pmty_signature ~loc [ B.psig_type ~loc Recursive [ active_search_declaration ~loc routes ] ]));
    B.psig_value ~loc
      (B.value_description ~loc ~name:{ txt = "useActiveSearch"; loc }
         ~type_:(B.ptyp_arrow ~loc Nolabel (unit_type ~loc) (active_search_type ~loc))
         ~prim:[]);
  ]

let signature (declaration : Router_declaration.t) =
  let loc = declaration.loc in
  let routes = Router_declaration.routes declaration in
  let root_search = Router_declaration.root_search declaration in
  B.psig_type ~loc Recursive
    [ destination_declaration ~loc ~private_:Public ~manifest:(Some (result_type ~loc "RouterRuntime.destination")) ]
  :: B.psig_value ~loc
       (B.value_description ~loc ~name:{ txt = "unsafeDestination"; loc } ~type_:(unsafe_destination_type ~loc) ~prim:[])
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
  @ List.map
      (fun (name, typ) -> B.psig_value ~loc (B.value_description ~loc ~name:{ txt = name; loc } ~type_:typ ~prim:[]))
      (route_hook_types ~loc)
  @ search_contract_signature ~loc root_search
  @ List.map (route_signature ~root_search) routes
  @ active_search_signature ~loc routes

let parameter_entries ~loc (parameter : Router_declaration.parameter) =
  let pair value =
    B.pexp_tuple ~loc
      [
        B.estring ~loc parameter.name;
        B.pexp_apply ~loc (B.pexp_ident ~loc { txt = parameter.to_string; loc }) [ (Nolabel, value) ];
      ]
  in
  let value = B.evar ~loc parameter.name in
  match parameter.presence with
  | Segment -> B.elist ~loc [ pair value ]
  | OptionalSegment ->
      let mapped =
        B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.map")
          [
            (Nolabel, B.pexp_fun ~loc Nolabel None (B.pvar ~loc "value") (pair (B.evar ~loc "value"))); (Nolabel, value);
          ]
      in
      B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.to_list") [ (Nolabel, mapped) ]
  | OptionalRest ->
      B.pexp_match ~loc value
        [
          B.case
            ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "[]"; loc } None)
            ~guard:None ~rhs:(B.elist ~loc []);
          B.case ~lhs:(B.pvar ~loc "value") ~guard:None ~rhs:(B.elist ~loc [ pair (B.evar ~loc "value") ]);
        ]

let parameter_list ~loc parameters =
  B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.concat")
    [ (Nolabel, B.elist ~loc (List.map (parameter_entries ~loc) parameters)) ]

let search_decoder ~loc (search : Router_declaration.search) =
  let callee =
    match search.kind with
    | Required -> "RouterRuntime.Search.required"
    | Optional -> "RouterRuntime.Search.optional"
    | Default _ -> "RouterRuntime.Search.default"
    | Many -> "RouterRuntime.Search.many"
  in
  let arguments =
    [ (Labelled "name", B.estring ~loc search.key); (Labelled "parse", B.pexp_ident ~loc { txt = search.parser; loc }) ]
    @ (match search.kind with Default fallback -> [ (Labelled "fallback", fallback) ] | _ -> [])
    @ [ (Nolabel, B.evar ~loc "values") ]
  in
  B.pexp_apply ~loc (B.evar ~loc callee) arguments

let search_of_values ?qualify ~loc search =
  let label name = match qualify with None -> Longident.Lident name | Some path -> Longident.Ldot (path, name) in
  let required = List.filter (fun (search : Router_declaration.search) -> search.kind = Required) search in
  let temporary (search : Router_declaration.search) = "required_" ^ search.name in
  let record =
    B.pexp_record ~loc
      (List.map
         (fun (search : Router_declaration.search) ->
           ( { txt = label search.name; loc = search.loc },
             match search.kind with
             | Required -> B.evar ~loc (temporary search)
             | Optional | Default _ | Many -> search_decoder ~loc:search.loc search ))
         search)
      None
  in
  match required with
  | [] -> record
  | required ->
      let some (search : Router_declaration.search) =
        B.ppat_construct ~loc { txt = Longident.Lident "Some"; loc } (Some (B.pvar ~loc (temporary search)))
      in
      B.pexp_let ~loc Nonrecursive
        (List.map
           (fun (search : Router_declaration.search) ->
             B.value_binding ~loc ~pat:(B.pvar ~loc (temporary search)) ~expr:(search_decoder ~loc:search.loc search))
           required)
        (B.pexp_match ~loc
           (match required with
           | [ search ] -> B.evar ~loc (temporary search)
           | required -> B.pexp_tuple ~loc (List.map (fun search -> B.evar ~loc (temporary search)) required))
           [
             B.case
               ~lhs:
                 (match required with
                 | [ search ] -> some search
                 | required -> B.ppat_tuple ~loc (List.map some required))
               ~guard:None ~rhs:(some_expression ~loc record);
             B.case ~lhs:(B.ppat_any ~loc) ~guard:None
               ~rhs:(B.pexp_construct ~loc { txt = Longident.Lident "None"; loc } None);
           ])

let search_values_expression ~loc record search =
  let entry (search : Router_declaration.search) =
    let value = B.pexp_field ~loc record { txt = Longident.Lident search.name; loc } in
    let print value = B.pexp_apply ~loc (B.pexp_ident ~loc { txt = search.to_string; loc }) [ (Nolabel, value) ] in
    let pair values = B.elist ~loc [ B.pexp_tuple ~loc [ B.estring ~loc search.key; values ] ] in
    match search.kind with
    | Required -> pair (B.elist ~loc [ print value ])
    | Optional ->
        B.pexp_match ~loc value
          [
            B.case
              ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "None"; loc } None)
              ~guard:None ~rhs:(B.elist ~loc []);
            B.case
              ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "Some"; loc } (Some (B.pvar ~loc "value")))
              ~guard:None
              ~rhs:(pair (B.elist ~loc [ print (B.evar ~loc "value") ]));
          ]
    | Default fallback ->
        B.pexp_ifthenelse ~loc
          (B.pexp_apply ~loc (B.evar ~loc "Stdlib.String.equal") [ (Nolabel, print value); (Nolabel, print fallback) ])
          (B.elist ~loc [])
          (Some (pair (B.elist ~loc [ print value ])))
    | Many ->
        B.pexp_match ~loc value
          [
            B.case
              ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "[]"; loc } None)
              ~guard:None ~rhs:(B.elist ~loc []);
            B.case ~lhs:(B.pvar ~loc "values") ~guard:None
              ~rhs:
                (pair
                   (B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.map")
                      [ (Nolabel, B.pexp_ident ~loc { txt = search.to_string; loc }); (Nolabel, B.evar ~loc "values") ]));
          ]
  in
  B.pexp_apply ~loc (B.evar ~loc "Stdlib.List.concat") [ (Nolabel, B.elist ~loc (List.map entry search)) ]

let search_constructor_expression ~loc search =
  let record =
    B.pexp_record ~loc
      (List.map
         (fun (search : Router_declaration.search) ->
           ({ txt = Longident.Lident search.name; loc }, B.evar ~loc search.name))
         search)
      None
  in
  let body = B.pexp_fun ~loc Nolabel None (B.punit ~loc) (B.pexp_constraint ~loc record (result_type ~loc "search")) in
  List.fold_right
    (fun (search : Router_declaration.search) body ->
      let default =
        match search.kind with
        | Default fallback -> Some fallback
        | Many -> Some (B.elist ~loc [])
        | Required | Optional -> None
      in
      B.pexp_fun ~loc (search_argument_label search) default
        (B.ppat_constraint ~loc (B.pvar ~loc search.name) (search_value_type ~loc search))
        body)
    search body

let search_codec_structure ~loc ~values search =
  let primitive name = B.evar ~loc ("RSC.Primitives." ^ name) in
  let codec suffix =
    B.pexp_apply ~loc
      (primitive ("list" ^ suffix))
      [
        ( Nolabel,
          B.pexp_apply ~loc
            (primitive ("tuple2" ^ suffix))
            [
              (Nolabel, primitive ("string" ^ suffix));
              (Nolabel, B.pexp_apply ~loc (primitive ("list" ^ suffix)) [ (Nolabel, primitive ("string" ^ suffix)) ]);
            ] );
      ]
  in
  let to_rsc =
    B.pexp_fun ~loc Nolabel None
      (B.ppat_constraint ~loc (B.pvar ~loc "search") (result_type ~loc "search"))
      (B.pexp_apply ~loc (codec "_to_rsc") [ (Nolabel, values) ])
  in
  let of_rsc =
    B.pexp_fun ~loc Nolabel None (B.pvar ~loc "rsc")
      (B.pexp_let ~loc Nonrecursive
         [
           B.value_binding ~loc ~pat:(B.pvar ~loc "values")
             ~expr:(B.pexp_apply ~loc (codec "_of_rsc") [ (Nolabel, B.evar ~loc "rsc") ]);
         ]
         (B.pexp_constraint ~loc
            (if has_required search then
               B.pexp_match ~loc (search_of_values ~loc search)
                 [
                   B.case
                     ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "Some"; loc } (Some (B.pvar ~loc "search")))
                     ~guard:None ~rhs:(B.evar ~loc "search");
                   B.case
                     ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "None"; loc } None)
                     ~guard:None
                     ~rhs:
                       (B.pexp_apply ~loc (B.evar ~loc "Stdlib.raise")
                          [
                            ( Nolabel,
                              B.pexp_construct ~loc
                                { txt = Longident.parse "RSC.Of_rsc_error"; loc }
                                (Some
                                   (B.pexp_construct ~loc
                                      { txt = Longident.parse "RSC.Rsc_error"; loc }
                                      (Some (B.estring ~loc "search record without its required parameters")))) );
                          ]);
                 ]
             else search_of_values ~loc search)
            (result_type ~loc "search")))
  in
  [
    B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "search_to_rsc") ~expr:to_rsc ];
    B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "search_of_rsc") ~expr:of_rsc ];
  ]

let use_search_structure ~loc ~values search =
  let update =
    B.pexp_fun ~loc (Optional "history") None (B.pvar ~loc "history")
      (B.pexp_fun ~loc Nolabel None
         (B.ppat_constraint ~loc (B.pvar ~loc "search") (result_type ~loc "search"))
         (B.pexp_apply ~loc (B.evar ~loc "updateSearch")
            [
              ( Labelled "owned",
                B.elist ~loc (List.map (fun (item : Router_declaration.search) -> B.estring ~loc item.key) search) );
              (Labelled "values", values);
              (Optional "history", B.evar ~loc "history");
              (Nolabel, unit_expression ~loc);
            ]))
  in
  let use_search =
    let body =
      B.pexp_let ~loc Nonrecursive
        [
          B.value_binding ~loc
            ~pat:(B.ppat_tuple ~loc [ B.pvar ~loc "values"; B.pvar ~loc "updateSearch" ])
            ~expr:(B.pexp_apply ~loc (B.evar ~loc "RouterReact.useSearch") [ (Nolabel, unit_expression ~loc) ]);
        ]
        (B.pexp_tuple ~loc
           [
             search_of_values ~loc search;
             B.pexp_apply ~loc (B.evar ~loc "React.useMemo1")
               [
                 (Nolabel, B.pexp_fun ~loc Nolabel None (B.punit ~loc) update);
                 (Nolabel, B.pexp_array ~loc [ B.evar ~loc "updateSearch" ]);
               ];
           ])
    in
    B.pexp_constraint ~loc
      (B.pexp_fun ~loc Nolabel None (B.punit ~loc) body)
      (B.ptyp_arrow ~loc Nolabel (unit_type ~loc)
         (B.ptyp_tuple ~loc [ decoded_search_type ~loc search; update_search_function_type ~loc ]))
  in
  B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "useSearch") ~expr:use_search ]

let route_module ~base_path ~root_search (route : Router_declaration.route) =
  let loc = route.loc in
  let search_values =
    match (route.search, search_label route.search) with
    | [], _ -> B.elist ~loc []
    | _, Labelled _ -> B.pexp_apply ~loc (B.evar ~loc "searchValues") [ (Nolabel, B.evar ~loc "search") ]
    | _, (Optional _ | Nolabel) ->
        B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.fold")
          [
            (Labelled "none", B.elist ~loc []);
            (Labelled "some", B.evar ~loc "searchValues");
            (Nolabel, B.evar ~loc "search");
          ]
  in
  let pattern_source =
    if String.equal route.path "/" && not (String.equal base_path "") then base_path else base_path ^ route.path
  in
  let pattern = B.pexp_apply ~loc (B.evar ~loc "RouterRuntime.pattern") [ (Nolabel, B.estring ~loc pattern_source) ] in
  let destination_body =
    B.pexp_apply ~loc
      (B.evar ~loc "RouterRuntime.destinationFromPattern")
      [
        (Labelled "pattern", B.evar ~loc "pattern");
        (Labelled "parameters", parameter_list ~loc route.parameters);
        (Labelled "search", search_values);
      ]
  in
  let destination_body =
    B.pexp_let ~loc Nonrecursive
      [ B.value_binding ~loc ~pat:(B.pvar ~loc "value") ~expr:destination_body ]
      (B.pexp_match ~loc (B.evar ~loc "hash")
         [
           B.case
             ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "None"; loc } None)
             ~guard:None ~rhs:(B.evar ~loc "value");
           B.case
             ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "Some"; loc } (Some (B.pvar ~loc "hash")))
             ~guard:None
             ~rhs:
               (B.pexp_apply ~loc (B.evar ~loc "RouterRuntime.withHash")
                  [ (Nolabel, B.evar ~loc "value"); (Labelled "hash", B.evar ~loc "hash") ]);
         ])
  in
  let destination_body =
    match route.prefetch with
    | Intent -> destination_body
    | level ->
        B.pexp_apply ~loc
          (B.evar ~loc "RouterRuntime.withPrefetch")
          [ (Nolabel, destination_body); (Nolabel, prefetch_level ~loc level) ]
  in
  let destination_body =
    List.fold_right
      (fun (parameter : Router_declaration.parameter) body ->
        match parameter.presence with
        | OptionalRest ->
            B.pexp_let ~loc Nonrecursive
              [
                B.value_binding ~loc ~pat:(B.pvar ~loc parameter.name)
                  ~expr:
                    (B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.value")
                       [ (Labelled "default", B.elist ~loc []); (Nolabel, B.evar ~loc parameter.name) ]);
              ]
              body
        | Segment | OptionalSegment -> body)
      route.parameters destination_body
  in
  let destination_expression =
    route_function_expression ~loc route.parameters route.search
      (B.pexp_constraint ~loc destination_body (result_type ~loc "destination"))
  in
  let destination_call = apply_route_inputs ~loc (B.evar ~loc "destination") route.parameters route.search in
  let href_body = B.pexp_apply ~loc (B.evar ~loc "RouterRuntime.href") [ (Nolabel, destination_call) ] in
  let href_expression =
    route_function_expression ~loc route.parameters route.search
      (B.pexp_constraint ~loc href_body (result_type ~loc "string"))
  in
  let link_body =
    let element =
      B.pexp_apply ~loc
        (B.evar ~loc "RouterReact.Link.createElement")
        [
          (Labelled "destination", destination_call);
          (Optional "attributes", B.evar ~loc "attributes");
          (Optional "className", B.evar ~loc "className");
          (Optional "target", B.evar ~loc "target");
          (Optional "download", B.evar ~loc "download");
          (Optional "ariaCurrent", B.evar ~loc "ariaCurrent");
          (Optional "history", B.evar ~loc "history");
          (Optional "revalidate", B.evar ~loc "revalidate");
          (Labelled "children", B.elist ~loc [ B.evar ~loc "children" ]);
          (Nolabel, unit_expression ~loc);
        ]
    in
    { element with pexp_attributes = [ jsx_attribute ~loc ] }
  in
  let link_with_unit =
    B.pexp_fun ~loc Nolabel None (B.punit ~loc) (B.pexp_constraint ~loc link_body (result_type ~loc "React.element"))
  in
  let link_with_children =
    typed_function ~loc (Labelled "children") "children" (result_type ~loc "React.element") link_with_unit
  in
  let link_with_revalidate =
    typed_function ~loc (Optional "revalidate") "revalidate" (bool_type ~loc) link_with_children
  in
  let link_with_history =
    typed_function ~loc (Optional "history") "history"
      (result_type ~loc "Navigation.historyAction")
      link_with_revalidate
  in
  let link_with_aria_current =
    typed_function ~loc (Optional "ariaCurrent") "ariaCurrent" (result_type ~loc "string") link_with_history
  in
  let link_with_download =
    typed_function ~loc (Optional "download") "download" (result_type ~loc "string") link_with_aria_current
  in
  let link_with_target =
    typed_function ~loc (Optional "target") "target" (result_type ~loc "string") link_with_download
  in
  let link_with_class_name =
    typed_function ~loc (Optional "className") "className" (result_type ~loc "string") link_with_target
  in
  let link_with_attributes =
    typed_function ~loc (Optional "attributes") "attributes"
      (result_type ~loc "RouterReact.Link.attributes")
      link_with_class_name
  in
  let link_expression = route_input_expression ~loc route.parameters route.search link_with_attributes in
  let try_items =
    match route.parameters with
    | [] -> []
    | parameters ->
        let result_constraint typ =
          B.ptyp_constr ~loc
            { txt = Longident.Lident "result"; loc }
            [ result_type ~loc typ; result_type ~loc "string" ]
        in
        let try_body =
          B.pexp_match ~loc destination_call
            [
              B.case ~lhs:(B.pvar ~loc "value") ~guard:None
                ~rhs:(B.pexp_construct ~loc { txt = Longident.Lident "Ok"; loc } (Some (B.evar ~loc "value")));
              B.case
                ~lhs:
                  (B.ppat_exception ~loc
                     (B.ppat_construct ~loc
                        { txt = Longident.Lident "Invalid_argument"; loc }
                        (Some (B.pvar ~loc "message"))))
                ~guard:None
                ~rhs:(B.pexp_construct ~loc { txt = Longident.Lident "Error"; loc } (Some (B.evar ~loc "message")));
            ]
        in
        let try_href_body =
          B.pexp_apply ~loc (B.evar ~loc "Stdlib.Result.map")
            [
              (Nolabel, B.evar ~loc "RouterRuntime.href");
              (Nolabel, apply_route_inputs ~loc (B.evar ~loc "tryDestination") parameters route.search);
            ]
        in
        [
          B.pstr_value ~loc Nonrecursive
            [
              B.value_binding ~loc ~pat:(B.pvar ~loc "tryDestination")
                ~expr:
                  (route_function_expression ~loc parameters route.search
                     (B.pexp_constraint ~loc try_body (result_constraint "destination")));
            ];
          B.pstr_value ~loc Nonrecursive
            [
              B.value_binding ~loc ~pat:(B.pvar ~loc "tryHref")
                ~expr:
                  (route_function_expression ~loc parameters route.search
                     (B.pexp_constraint ~loc try_href_body (result_constraint "string")));
            ];
        ]
  in
  let link_binding = B.value_binding ~loc ~pat:(B.pvar ~loc "make") ~expr:link_expression in
  let link_binding = { link_binding with pvb_attributes = [ react_component_attribute ~loc ] } in
  let search_values_binding =
    match route.search with
    | [] -> []
    | _ ->
        [
          B.pstr_value ~loc Nonrecursive
            [
              B.value_binding ~loc ~pat:(B.pvar ~loc "searchValues")
                ~expr:
                  (B.pexp_fun ~loc Nolabel None
                     (B.ppat_constraint ~loc (B.pvar ~loc "search") (result_type ~loc "search"))
                     (search_values_expression ~loc (B.evar ~loc "search") route.search));
            ];
        ]
  in
  let search_items =
    match route.search with
    | [] -> []
    | _ ->
        let rec_flag, declaration = route_search_type ~loc ~root_search route.search in
        [ B.pstr_type ~loc rec_flag [ declaration ] ]
  in
  let search_constructor =
    match route.search with
    | [] -> []
    | _ ->
        let values = B.pexp_apply ~loc (B.evar ~loc "searchValues") [ (Nolabel, B.evar ~loc "search") ] in
        [
          B.pstr_value ~loc Nonrecursive
            [ B.value_binding ~loc ~pat:(B.pvar ~loc "search") ~expr:(search_constructor_expression ~loc route.search) ];
        ]
        @ search_codec_structure ~loc ~values route.search
        @ if route_owns_search ~root_search route.search then [ use_search_structure ~loc ~values route.search ] else []
  in
  let private_items =
    B.pstr_open ~loc
      {
        popen_expr =
          B.pmod_structure ~loc
            (B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "pattern") ~expr:pattern ]
            :: search_values_binding);
        popen_override = Fresh;
        popen_loc = loc;
        popen_attributes = [];
      }
  in
  let module_expression =
    B.pmod_structure ~loc
      (search_items @ (private_items :: search_constructor)
      @ [
          B.pstr_value ~loc Nonrecursive
            [ B.value_binding ~loc ~pat:(B.pvar ~loc "destination") ~expr:destination_expression ];
          B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "href") ~expr:href_expression ];
        ]
      @ try_items
      @ [ B.pstr_value ~loc Nonrecursive [ link_binding ] ])
  in
  B.pstr_module ~loc (B.module_binding ~loc ~name:{ txt = Some route.name; loc } ~expr:module_expression)

let search_contract_structure ~loc search =
  if search = [] then []
  else
    let values = search_values_expression ~loc (B.evar ~loc "search") search in
    (B.pstr_type ~loc Recursive [ search_type_declaration ~loc search ] :: search_codec_structure ~loc ~values search)
    @ [ use_search_structure ~loc ~values search ]

let active_search_structure ~loc routes =
  let uses_values = List.exists (fun (route : Router_declaration.route) -> route.search <> []) routes in
  let constructor (route : Router_declaration.route) payload =
    B.pexp_construct ~loc { txt = Longident.parse ("ActiveSearch." ^ route.name); loc } payload
  in
  let cases =
    List.map
      (fun (route : Router_declaration.route) ->
        let rhs =
          match route.search with
          | [] -> some_expression ~loc (constructor route None)
          | search ->
              let decoded = search_of_values ~qualify:(Longident.Lident route.name) ~loc search in
              if has_required search then
                B.pexp_apply ~loc (B.evar ~loc "Stdlib.Option.map")
                  [
                    ( Nolabel,
                      B.pexp_fun ~loc Nolabel None (B.pvar ~loc "search")
                        (constructor route (Some (B.evar ~loc "search"))) );
                    (Nolabel, decoded);
                  ]
              else some_expression ~loc (constructor route (Some decoded))
        in
        B.case ~lhs:(B.ppat_constant ~loc (Pconst_string (route.name, loc, None))) ~guard:None ~rhs)
      routes
  in
  let none = B.pexp_construct ~loc { txt = Longident.Lident "None"; loc } None in
  let body =
    B.pexp_let ~loc Nonrecursive
      [
        B.value_binding ~loc ~pat:(B.pvar ~loc "route")
          ~expr:(B.pexp_apply ~loc (B.evar ~loc "RouterReact.useCurrentRoute") [ (Nolabel, unit_expression ~loc) ]);
      ]
      (B.pexp_let ~loc Nonrecursive
         [
           B.value_binding ~loc
             ~pat:(B.ppat_tuple ~loc [ B.pvar ~loc (if uses_values then "values" else "_values"); B.ppat_any ~loc ])
             ~expr:(B.pexp_apply ~loc (B.evar ~loc "RouterReact.useSearch") [ (Nolabel, unit_expression ~loc) ]);
         ]
         (B.pexp_match ~loc (B.evar ~loc "route")
            [
              B.case ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "None"; loc } None) ~guard:None ~rhs:none;
              B.case
                ~lhs:
                  (B.ppat_construct ~loc { txt = Longident.Lident "Some"; loc }
                     (Some (B.ppat_tuple ~loc [ B.pvar ~loc "routeId"; B.ppat_any ~loc ])))
                ~guard:None
                ~rhs:
                  (B.pexp_match ~loc (B.evar ~loc "routeId")
                     (cases @ [ B.case ~lhs:(B.ppat_any ~loc) ~guard:None ~rhs:none ]));
            ]))
  in
  [
    B.pstr_module ~loc
      (B.module_binding ~loc ~name:{ txt = Some "ActiveSearch"; loc }
         ~expr:(B.pmod_structure ~loc [ B.pstr_type ~loc Recursive [ active_search_declaration ~loc routes ] ]));
    B.pstr_value ~loc Nonrecursive
      [
        B.value_binding ~loc ~pat:(B.pvar ~loc "useActiveSearch")
          ~expr:
            (B.pexp_constraint ~loc
               (B.pexp_fun ~loc Nolabel None (B.punit ~loc) body)
               (B.ptyp_arrow ~loc Nolabel (unit_type ~loc) (active_search_type ~loc)));
      ];
  ]

let handles (declaration : Router_declaration.t) =
  let base_path = if declaration.base_path = "/" then "" else declaration.base_path in
  let loc = declaration.loc in
  let routes = Router_declaration.routes declaration in
  let root_search = Router_declaration.root_search declaration in
  B.pstr_type ~loc Recursive
    [ destination_declaration ~loc ~private_:Public ~manifest:(Some (result_type ~loc "RouterRuntime.destination")) ]
  :: B.pstr_value ~loc Nonrecursive
       [
         B.value_binding ~loc ~pat:(B.pvar ~loc "unsafeDestination")
           ~expr:(B.pexp_constraint ~loc (unsafe_destination_expression ~loc) (unsafe_destination_type ~loc));
       ]
  :: List.map (structure_alias ~loc) public_modules
  @ [ B.pstr_type ~loc Recursive [ route_type_declaration ~loc routes ] ]
  @ [
      B.pstr_value ~loc Nonrecursive
        [
          B.value_binding ~loc ~pat:(B.pvar ~loc "useNavigation")
            ~expr:
              (B.pexp_constraint ~loc
                 (B.evar ~loc "RouterReact.useNavigation")
                 (B.ptyp_arrow ~loc Nolabel (unit_type ~loc)
                    (B.ptyp_tuple ~loc [ navigate_type ~loc; result_type ~loc "Navigation.status" ])));
        ];
      B.pstr_value ~loc Nonrecursive
        [
          B.value_binding ~loc ~pat:(B.pvar ~loc "useUpdateHash")
            ~expr:
              (B.pexp_constraint ~loc
                 (B.evar ~loc "RouterReact.useUpdateHash")
                 (B.ptyp_arrow ~loc Nolabel (unit_type ~loc) (update_hash_type ~loc)));
        ];
      B.pstr_open ~loc
        {
          popen_expr =
            B.pmod_structure ~loc
              [
                B.pstr_value ~loc Nonrecursive
                  [ B.value_binding ~loc ~pat:(B.pvar ~loc "decodeRoute") ~expr:(decode_route_function ~loc routes) ];
              ];
          popen_override = Fresh;
          popen_loc = loc;
          popen_attributes = [];
        };
      B.pstr_value ~loc Nonrecursive
        [ B.value_binding ~loc ~pat:(B.pvar ~loc "useRoute") ~expr:(use_route_expression ~loc) ];
    ]
  @ List.map
      (fun (name, typ) ->
        let expression =
          match name with "useMatches" -> use_matches_expression ~loc | name -> B.evar ~loc ("RouterReact." ^ name)
        in
        B.pstr_value ~loc Nonrecursive
          [ B.value_binding ~loc ~pat:(B.pvar ~loc name) ~expr:(B.pexp_constraint ~loc expression typ) ])
      (route_hook_types ~loc)
  @ search_contract_structure ~loc root_search
  @ List.map (route_module ~base_path ~root_search) routes
  @ active_search_structure ~loc routes

let apply_native_inputs_with ?(context = []) ~loc callee parameters search loaders extra =
  let arguments =
    context
    @ List.map
        (fun (parameter : Router_declaration.parameter) -> (Labelled parameter.name, B.evar ~loc parameter.name))
        parameters
    @ (match search with None -> [] | Some variable -> [ (Labelled "search", B.evar ~loc variable) ])
    @ List.map (fun name -> (Labelled name, B.evar ~loc name)) loaders
    @ extra
    @ [ (Nolabel, unit_expression ~loc) ]
  in
  B.pexp_apply ~loc callee arguments

let apply_native_inputs ?context ~loc callee parameters search loaders =
  apply_native_inputs_with ?context ~loc callee parameters search loaders []

let context_arguments ~loc (context : core_type option) =
  match context with None -> [] | Some _ -> [ (Labelled "context", B.evar ~loc "context") ]

let references_context expression =
  (object
     inherit [bool] Ast_traverse.fold as super

     method! expression expression found =
       match expression.pexp_desc with
       | Pexp_ident { txt = Lident "context"; _ } -> true
       | _ -> super#expression expression found
  end)
    #expression
    expression false

let context_pattern ?used ~loc typ body =
  let used = Option.value used ~default:(references_context body) in
  B.ppat_constraint ~loc (if used then B.pvar ~loc "context" else B.ppat_any ~loc) typ

let execution_function ?used ~loc (context : core_type option) body =
  let pattern = match context with None -> B.punit ~loc | Some typ -> context_pattern ?used ~loc typ body in
  B.pexp_fun ~loc Nolabel None pattern body

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
      (Labelled "name", B.estring ~loc search.key);
      (Labelled "parse", B.pexp_ident ~loc { txt = search.parser; loc });
    ]
    @ match search.kind with Default fallback -> [ (Labelled "fallback", fallback) ] | _ -> []
  in
  B.pexp_apply ~loc (B.evar ~loc callee) arguments

let input_pattern ~loc used = B.pvar ~loc (if used then "input" else "_input")

let bind_decode ~loc name decoder body =
  B.pexp_apply ~loc (B.evar ~loc "Stdlib.Result.bind")
    [ (Nolabel, decoder); (Nolabel, B.pexp_fun ~loc Nolabel None (B.pvar ~loc name) body) ]

let scope_search current (scope : Router_declaration.scope) =
  match scope.search with [] -> current | _ -> Some (if String.equal scope.id "root" then "search" else "routeSearch")

let search_record_decoder ~loc ~path ~typ ~inherited own =
  let label name = Longident.parse (String.concat "." (path @ [ name ])) in
  let temporary index = "search_" ^ Int.to_string index in
  let inherited_fields =
    List.map
      (fun (search : Router_declaration.search) ->
        ( { txt = label search.name; loc },
          B.pexp_field ~loc (B.evar ~loc "search") { txt = Longident.parse ("Router." ^ search.name); loc } ))
      inherited
  in
  let own_fields =
    List.mapi
      (fun index (search : Router_declaration.search) ->
        ({ txt = label search.name; loc }, B.evar ~loc (temporary index)))
      own
  in
  let record = B.pexp_constraint ~loc (B.pexp_record ~loc (inherited_fields @ own_fields) None) typ in
  let ok = B.pexp_construct ~loc { txt = Longident.Lident "Ok"; loc } (Some record) in
  List.fold_right
    (fun (index, (search : Router_declaration.search)) body ->
      bind_decode ~loc:search.loc (temporary index) (native_search_decoder ~loc:search.loc search) body)
    (List.mapi (fun index search -> (index, search)) own)
    ok

let root_search_decoder ~loc search =
  search_record_decoder ~loc ~path:[ "Router" ] ~typ:(result_type ~loc "Router.search") ~inherited:[] search

let decode_parameters ~present parameters body =
  List.fold_right
    (fun (parameter : Router_declaration.parameter) body ->
      let loc = parameter.loc in
      if List.mem parameter.name present then
        let decoder = native_path_decoder ~loc parameter in
        let decoder =
          match parameter.presence with
          | OptionalSegment ->
              B.pexp_apply ~loc (B.evar ~loc "Stdlib.Result.map")
                [ (Nolabel, B.evar ~loc "Stdlib.Option.some"); (Nolabel, decoder) ]
          | Segment | OptionalRest -> decoder
        in
        bind_decode ~loc parameter.name decoder body
      else
        B.pexp_let ~loc Nonrecursive
          [ B.value_binding ~loc ~pat:(B.pvar ~loc parameter.name) ~expr:(absent_value ~loc parameter) ]
          body)
    parameters body

let boundary_callback ~loc attachment parameters search loaders =
  let call =
    apply_native_component_inputs_with ~loc attachment parameters search loaders
      [ (Labelled "error", B.evar ~loc "error") ]
  in
  B.pexp_fun ~loc Nolabel None (B.pvar ~loc "error") call

let branch_scope ~loc (scope : Router_declaration.scope) parameters ~reusable =
  B.pexp_apply ~loc
    (B.evar ~loc "RouterServer.Branch.Scope.make")
    [
      (Labelled "id", B.estring ~loc scope.id);
      (Labelled "parameters", parameter_list ~loc parameters);
      (Labelled "reusable", B.ebool ~loc reusable);
    ]

let render_error_boundary ~loc boundary parameters search loaders body =
  let error =
    B.pexp_construct ~loc
      { txt = Longident.parse "RouterRuntime.Error.Internal"; loc }
      (Some (B.pexp_record ~loc [ ({ txt = Longident.Lident "diagnosticId"; loc }, B.estring ~loc "render") ] None))
  in
  let fallback =
    B.pexp_construct ~loc
      { txt = Longident.parse "React.Upper_case_component"; loc }
      (Some
         (B.pexp_tuple ~loc
            [
              B.estring ~loc "RouterErrorFallback";
              B.pexp_fun ~loc Nolabel None (B.punit ~loc)
                (B.pexp_apply ~loc (boundary_callback ~loc boundary parameters search loaders) [ (Nolabel, error) ]);
            ]))
  in
  B.pexp_apply ~loc
    (B.evar ~loc "RouterReact.errorBoundary")
    [ (Labelled "fallback", fallback); (Labelled "children", body); (Nolabel, unit_expression ~loc) ]

let scope_plan ~context (scope : Router_declaration.scope) parameters search loaders ~boundary_loaders ~reusable =
  let loc = scope.loc in
  let callback attachment =
    apply_native_inputs ~context:(context_arguments ~loc context) ~loc attachment parameters search loaders
  in
  let component attachment = apply_native_component_inputs ~loc attachment parameters search loaders in
  let catch body =
    match scope.attachments.error with
    | None -> body
    | Some boundary -> render_error_boundary ~loc boundary parameters search boundary_loaders body
  in
  let arguments =
    (match (scope.attachments.layout, scope.attachments.loading, scope.attachments.error) with
      | None, None, None -> []
      | None, None, Some _ ->
          [
            (Labelled "layout", B.pexp_fun ~loc Nolabel None (B.pvar ~loc "children") (catch (B.evar ~loc "children")));
          ]
      | layout, loading, _ ->
          let identity = branch_scope ~loc scope parameters ~reusable in
          let instance_key =
            B.pexp_apply ~loc (B.evar ~loc "RouterServer.Branch.Scope.instanceKey") [ (Nolabel, identity) ]
          in
          let children = B.evar ~loc "children" in
          let body =
            match layout with
            | None -> catch children
            | Some layout ->
                let outlet =
                  B.pexp_apply ~loc (B.evar ~loc "RouterReact.outlet")
                    [
                      (Labelled "owner", instance_key); (Labelled "children", children); (Nolabel, unit_expression ~loc);
                    ]
                in
                apply_native_component_inputs_with ~loc layout parameters search loaders
                  [ (Labelled "children", catch outlet) ]
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

let loader_execution ~context (route : Router_declaration.route) =
  let loc = route.loc in
  let loader_call (loader : Router_declaration.loader) parameters search loader_values =
    apply_native_inputs
      ~context:(context_arguments ~loc:loader.loc context)
      ~loc:loader.loc loader.run parameters search loader_values
  in
  let parallel =
    List.fold_left
      (fun (parameters, search, parallel) (scope : Router_declaration.scope) ->
        let parameters = parameters @ scope.parameters in
        let search = scope_search search scope in
        match scope.attachments.loader with
        | Some loader when loader.parallel -> (parameters, search, parallel @ [ (loader, parameters, search) ])
        | Some _ | None -> (parameters, search, parallel))
      ([], None, []) route.scopes
    |> fun (_, _, parallel) -> parallel
  in
  let taken =
    [ "context"; "search"; "routeSearch"; "error"; "children"; "input"; "prepared"; "decodeError" ]
    @ List.map (fun (parameter : Router_declaration.parameter) -> parameter.name) route.parameters
    @ List.filter_map
        (fun (scope : Router_declaration.scope) ->
          Option.map (fun (loader : Router_declaration.loader) -> loader.result_label) scope.attachments.loader)
        route.scopes
  in
  let started =
    List.fold_left
      (fun started ((loader : Router_declaration.loader), _, _) ->
        let rec fresh name =
          if List.mem name taken || List.exists (fun (_, used) -> String.equal used name) started then fresh (name ^ "_")
          else name
        in
        started @ [ (loader.result_label, fresh ("started_" ^ loader.result_label)) ])
      [] parallel
  in
  let rec build scopes parameters search loader_values completed not_found error_boundary =
    match scopes with
    | [] ->
        let page =
          apply_native_component_inputs ~loc route.page route.parameters search loader_values |> fun page ->
          B.pexp_constraint ~loc page (result_type ~loc "React.element")
        in
        let plan =
          B.pexp_apply ~loc
            (B.evar ~loc "RouterServer.Plan.success")
            [ (Labelled "scopes", B.elist ~loc completed); (Labelled "page", page) ]
        in
        let failure =
          B.pexp_fun ~loc Nolabel None (B.pvar ~loc "error")
            (failure_plan ~loc completed (B.evar ~loc "error") not_found error_boundary)
        in
        let plan =
          B.pexp_apply ~loc (B.evar ~loc "RouterServer.Plan.withFailure") [ (Nolabel, plan); (Nolabel, failure) ]
        in
        B.pexp_apply ~loc (B.evar ~loc "RouterServer.Execution.done_") [ (Nolabel, plan) ]
    | (scope : Router_declaration.scope) :: rest -> (
        let parameters = parameters @ scope.Router_declaration.parameters in
        let search = scope_search search scope in
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
            let reusable = Option.is_some scope.attachments.layout in
            let current =
              scope_plan ~context scope parameters search loader_values ~boundary_loaders:loader_values ~reusable
            in
            build rest parameters search loader_values (completed @ [ current ]) not_found error_boundary
        | Some loader ->
            let run =
              match List.assoc_opt loader.result_label started with
              | Some name ->
                  B.pexp_apply ~loc:loader.loc
                    (B.evar ~loc:loader.loc "RouterServer.Execution.await")
                    [ (Nolabel, B.evar ~loc:loader.loc name) ]
              | None ->
                  B.pexp_fun ~loc:loader.loc Nolabel None (B.punit ~loc:loader.loc)
                    (loader_call loader parameters search loader_values)
            in
            let next_loaders = loader_values @ [ loader.result_label ] in
            let reusable = Option.is_some scope.attachments.layout in
            let current =
              scope_plan ~context scope parameters search next_loaders ~boundary_loaders:loader_values ~reusable
            in
            let next_body =
              build rest parameters search next_loaders (completed @ [ current ]) not_found error_boundary
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
  List.fold_right
    (fun ((loader : Router_declaration.loader), parameters, search) execution ->
      let name = List.assoc loader.result_label started in
      let loc = loader.loc in
      B.pexp_apply ~loc
        (B.evar ~loc "RouterServer.Execution.start")
        [
          (Labelled "run", B.pexp_fun ~loc Nolabel None (B.punit ~loc) (loader_call loader parameters search []));
          (Labelled "next", B.pexp_fun ~loc Nolabel None (B.pvar ~loc name) execution);
        ])
    parallel
    (build route.scopes [] None [] [] None None)

let parsed_path path =
  match RouterPattern.parseTemplate path with
  | Ok pattern -> pattern
  | Error _ -> invalid_arg "validated router path failed to parse"

let active_route_candidates routes pattern =
  routes
  |> List.filter_map (fun (route, shapes) ->
      match
        shapes
        |> List.filter (fun shape -> RouterPattern.isPrefix ~prefix:shape pattern)
        |> List.map (fun shape -> List.length (RouterPattern.segments shape))
      with
      | [] -> None
      | lengths -> Some (route, List.fold_left max 0 lengths))
  |> List.sort (fun ((left : Router_declaration.route), left_length) (right, right_length) ->
      match Int.compare left_length right_length with 0 -> String.compare left.name right.name | order -> order)

let projected_branch (route : Router_declaration.route) =
  let loc = route.loc in
  let rec build scopes parameters projected =
    match scopes with
    | [] -> B.elist ~loc projected
    | (scope : Router_declaration.scope) :: scopes ->
        let parameters = parameters @ scope.parameters in
        let reusable = Option.is_some scope.attachments.layout in
        let projected = projected @ [ branch_scope ~loc:scope.loc scope parameters ~reusable ] in
        build scopes parameters projected
  in
  build route.scopes [] []

let recover_decode_failure ~context ~loc ~branch ~scopes ~active_routes error_boundary =
  let plan = failure_plan ~loc scopes (B.evar ~loc "decodeError") None (Some error_boundary) in
  let execution =
    execution_function ~loc context (B.pexp_apply ~loc (B.evar ~loc "RouterServer.Execution.done_") [ (Nolabel, plan) ])
  in
  let prepared =
    B.pexp_apply ~loc
      (B.evar ~loc "RouterServer.Endpoint.recovered")
      [
        (Labelled "branch", B.elist ~loc branch);
        (Labelled "activeRoutes", B.elist ~loc (List.map (fun route -> B.estring ~loc route) active_routes));
        (Labelled "execution", execution);
      ]
  in
  B.pexp_construct ~loc { txt = Longident.Lident "Ok"; loc } (Some prepared)

let decode_endpoint ~context ~routes ~present ~root_search (route : Router_declaration.route) prepared =
  let rec build scopes pattern parameters search completed branch error_boundary loader_seen root =
    match scopes with
    | [] -> prepared
    | (scope : Router_declaration.scope) :: scopes -> (
        let loc = scope.loc in
        let next_parameters = parameters @ scope.parameters in
        let next_search = scope_search search scope in
        let next_pattern = RouterPattern.append pattern (parsed_path scope.path) in
        let has_loader = Option.is_some scope.attachments.loader in
        let reusable = Option.is_some scope.attachments.layout in
        let next_branch = branch @ [ branch_scope ~loc scope next_parameters ~reusable ] in
        let next_error_boundary =
          if loader_seen then error_boundary
          else
            match scope.attachments.error with
            | Some boundary -> Some (boundary_callback ~loc boundary next_parameters next_search [])
            | None -> error_boundary
        in
        let next_completed =
          if loader_seen || has_loader then completed
          else completed @ [ scope_plan ~context scope next_parameters next_search [] ~boundary_loaders:[] ~reusable ]
        in
        let success =
          build scopes next_pattern next_parameters next_search next_completed next_branch next_error_boundary
            (loader_seen || has_loader) false
        in
        let decoded_search =
          match (scope.search, next_search) with
          | [], _ | _, None -> success
          | own, Some variable ->
              let decoder =
                if root then root_search_decoder ~loc own
                else
                  search_record_decoder ~loc ~path:[ "Router"; route.name ]
                    ~typ:(result_type ~loc ("Router." ^ route.name ^ ".search"))
                    ~inherited:root_search own
              in
              bind_decode ~loc variable decoder success
        in
        let decoded = decode_parameters ~present scope.parameters decoded_search in
        if scope.parameters = [] && scope.search = [] then decoded
        else if root then decoded
        else
          match error_boundary with
          | None -> decoded
          | Some boundary ->
              let active_routes =
                active_route_candidates routes pattern
                |> List.map (fun ((route : Router_declaration.route), _) -> route.name)
              in
              let recover = recover_decode_failure ~context ~loc ~branch ~scopes:completed ~active_routes boundary in
              B.pexp_match ~loc decoded
                [
                  B.case
                    ~lhs:(B.ppat_construct ~loc { txt = Longident.Lident "Ok"; loc } (Some (B.pvar ~loc "prepared")))
                    ~guard:None
                    ~rhs:(B.pexp_construct ~loc { txt = Longident.Lident "Ok"; loc } (Some (B.evar ~loc "prepared")));
                  B.case
                    ~lhs:
                      (B.ppat_construct ~loc { txt = Longident.Lident "Error"; loc } (Some (B.pvar ~loc "decodeError")))
                    ~guard:None ~rhs:recover;
                ])
  in
  build route.scopes (parsed_path "/") [] None [] [] None false true

let encoded_path path =
  match
    RouterPattern.render (parsed_path path)
      ~parameter:(fun _ -> None)
      ~encodeStatic:RouterPattern.encodeStaticSegment ~encodeParameter:RouterPattern.encodeStaticSegment
  with
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

let search_part (search : Router_declaration.search) =
  let key = if String.equal search.key search.name then "" else ":key:" ^ search.key in
  "search:" ^ search.name ^ key ^ ":" ^ type_string search.typ ^ ":" ^ search_kind_part search

let fingerprint_parts (route : Router_declaration.route) =
  let route_parts = [ "route:" ^ route.name; "path:" ^ route.path ] in
  let parameter_parts =
    List.map
      (fun (parameter : Router_declaration.parameter) ->
        "parameter:" ^ parameter.name ^ ":" ^ type_string parameter.typ)
      route.parameters
  in
  let search_parts = List.map (fun (search : Router_declaration.search) -> search_part search) route.search in
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
          | Some loader ->
              "loader:" ^ loader.result_label ^ ":" ^ expression_string loader.run
              ^ if loader.parallel then ":parallel" else "");
          attachment_part "metadata" attachments.metadata;
          attachment_part "headers" attachments.headers;
        ])
      route.scopes
  in
  route_parts @ parameter_parts @ search_parts @ scope_parts

let endpoint ~context ~base_path ~invalid_search ~root_search ~routes ~primary ~shape (route : Router_declaration.route)
    =
  let loc = route.loc in
  let shape_path = RouterPattern.toString shape in
  let present =
    RouterPattern.parameters shape |> List.map (fun (parameter : RouterPattern.parameter) -> parameter.name)
  in
  let execution = loader_execution ~context route in
  let prepared =
    B.pexp_apply ~loc
      (B.evar ~loc "RouterServer.Endpoint.prepared")
      [ (Labelled "branch", projected_branch route); (Labelled "execution", execution_function ~loc context execution) ]
    |> fun prepared -> B.pexp_construct ~loc { txt = Longident.Lident "Ok"; loc } (Some prepared)
  in
  let decoded = decode_endpoint ~context ~routes ~present ~root_search route prepared in
  let decode = B.pexp_fun ~loc Nolabel None (input_pattern ~loc (present <> [] || route.search <> [])) decoded in
  let active_routes =
    active_route_candidates routes shape
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
    ([ "basePath:" ^ base_path; attachment_part "invalidSearch" invalid_search ]
    @ fingerprint_parts route
    @ if String.equal shape_path route.path then [] else [ "shape:" ^ shape_path ])
    |> String.concat "\n" |> Digest.string |> Digest.to_hex
  in
  let endpoint =
    B.pexp_apply ~loc
      (B.evar ~loc "RouterServer.Endpoint.make")
      [
        (Labelled "id", B.estring ~loc (if primary then route.name else route.name ^ "@" ^ shape_path));
        (Labelled "path", B.estring ~loc shape_path);
        (Labelled "activeRoutes", B.elist ~loc active_routes);
        (Labelled "fingerprint", B.estring ~loc fingerprint);
        (Labelled "decode", decode);
      ]
  in
  match route.prefetch with
  | Intent -> endpoint
  | level ->
      B.pexp_apply ~loc
        (B.evar ~loc "RouterServer.Endpoint.withPrefetch")
        [ (Nolabel, endpoint); (Nolabel, prefetch_level ~loc level) ]

let redirect_search_type (redirect : Router_declaration.redirect) =
  String.map (function ('a' .. 'z' | '0' .. '9') as character -> character | _ -> '_') redirect.id ^ "_search"

let redirect_own_search ~root_search (redirect : Router_declaration.redirect) =
  List.filteri (fun index _ -> index >= List.length root_search) redirect.search

let redirect_search_types ~root_search endpoints =
  List.filter_map
    (function
      | Router_declaration.RedirectTo redirect when redirect_own_search ~root_search redirect <> [] ->
          Some
            (B.pstr_type ~loc:redirect.loc Recursive
               [ search_type_declaration ~name:(redirect_search_type redirect) ~loc:redirect.loc redirect.search ])
      | Router_declaration.RedirectTo _ | Router_declaration.Page _ -> None)
    endpoints

let redirect_endpoint ~context ~base_path ~invalid_search ~root_search (redirect : Router_declaration.redirect) =
  let loc = redirect.loc in
  let own = redirect_own_search ~root_search redirect in
  let search =
    match (own, root_search) with
    | [], [] -> None
    | [], _ -> Some ("search", "Router.search")
    | _, _ -> Some ("routeSearch", redirect_search_type redirect)
  in
  let target =
    match search with
    | None -> redirect.target
    | Some (_, search_type) ->
        let result =
          B.ptyp_arrow ~loc (Labelled "search") (result_type ~loc search_type)
            (B.ptyp_arrow ~loc Nolabel (unit_type ~loc) (result_type ~loc "RouterRuntime.destination"))
        in
        B.pexp_constraint ~loc redirect.target
          (List.fold_right
             (fun (parameter : Router_declaration.parameter) result ->
               B.ptyp_arrow ~loc (Labelled parameter.name) parameter.typ result)
             redirect.parameters result)
  in
  let destination =
    apply_native_inputs ~loc target redirect.parameters (Option.map fst search) [] |> fun destination ->
    B.pexp_constraint ~loc destination (result_type ~loc "RouterRuntime.destination")
  in
  let execution =
    B.pexp_apply ~loc
      (B.evar ~loc
         (if redirect.permanent then "RouterServer.Execution.permanentRedirect" else "RouterServer.Execution.redirect"))
      [ (Nolabel, destination) ]
  in
  let prepared =
    B.pexp_apply ~loc
      (B.evar ~loc "RouterServer.Endpoint.prepared")
      [
        (Labelled "branch", B.elist ~loc []);
        (Labelled "execution", execution_function ~used:false ~loc context execution);
      ]
    |> fun prepared -> B.pexp_construct ~loc { txt = Longident.Lident "Ok"; loc } (Some prepared)
  in
  let decoded_search =
    let decoded_own =
      match search with
      | Some (variable, search_type) when own <> [] ->
          bind_decode ~loc variable
            (search_record_decoder ~loc ~path:[] ~typ:(result_type ~loc search_type) ~inherited:root_search own)
            prepared
      | Some _ | None -> prepared
    in
    match root_search with
    | [] -> decoded_own
    | _ -> bind_decode ~loc "search" (root_search_decoder ~loc root_search) decoded_own
  in
  let decoded =
    List.fold_right
      (fun (parameter : Router_declaration.parameter) body ->
        bind_decode ~loc:parameter.loc parameter.name (native_path_decoder ~loc:parameter.loc parameter) body)
      redirect.parameters decoded_search
  in
  let decode =
    B.pexp_fun ~loc Nolabel None (input_pattern ~loc (redirect.parameters <> [] || redirect.search <> [])) decoded
  in
  let parameter_parts =
    List.map
      (fun (parameter : Router_declaration.parameter) ->
        "parameter:" ^ parameter.name ^ ":" ^ type_string parameter.typ)
      redirect.parameters
  in
  let search_parts = List.map (fun (search : Router_declaration.search) -> search_part search) redirect.search in
  let fingerprint =
    [
      "basePath:" ^ base_path;
      attachment_part "invalidSearch" invalid_search;
      "redirect:" ^ redirect.id;
      "path:" ^ redirect.path;
      "target:" ^ expression_string redirect.target;
    ]
    @ (if redirect.permanent then [ "permanent" ] else [])
    @ parameter_parts @ search_parts
    |> String.concat "\n" |> Digest.string |> Digest.to_hex
  in
  B.pexp_apply ~loc
    (B.evar ~loc "RouterServer.Endpoint.make")
    [
      (Labelled "id", B.estring ~loc redirect.id);
      (Labelled "path", B.estring ~loc redirect.path);
      (Labelled "activeRoutes", B.elist ~loc []);
      (Labelled "fingerprint", B.estring ~loc fingerprint);
      (Labelled "decode", decode);
    ]

let fallback (declaration : Router_declaration.t) =
  let loc = declaration.loc in
  let scope = declaration.root.scope in
  let search = Router_declaration.root_search declaration in
  let variable = scope_search None scope in
  let not_found =
    Option.map (fun boundary -> boundary_callback ~loc:scope.loc boundary [] variable []) scope.attachments.not_found
  in
  let error_boundary =
    Option.map (fun boundary -> boundary_callback ~loc:scope.loc boundary [] variable []) scope.attachments.error
  in
  let completed =
    match scope.attachments.loader with
    | Some _ -> []
    | None -> [ scope_plan ~context:declaration.context scope [] variable [] ~boundary_loaders:[] ~reusable:true ]
  in
  let planned = failure_plan ~loc completed (B.evar ~loc "error") not_found error_boundary in
  let decoded =
    let ok = B.pexp_construct ~loc { txt = Longident.Lident "Ok"; loc } (Some planned) in
    match search with [] -> ok | _ -> bind_decode ~loc "search" (root_search_decoder ~loc search) ok
  in
  let decode_failure =
    let invalid_search_boundary =
      Option.map
        (fun boundary -> boundary_callback ~loc:boundary.pexp_loc boundary [] None [])
        declaration.invalid_search
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
          let fields =
            List.filter_map
              (Option.map (fun ((search : Router_declaration.search), expression) ->
                   ({ txt = Longident.parse ("Router." ^ search.name); loc = search.loc }, expression)))
              recovery
          in
          let plan = failure_plan ~loc completed (B.evar ~loc "decodeError") not_found error_boundary in
          match fields with
          | [] -> plan
          | _ ->
              B.pexp_let ~loc Nonrecursive
                [
                  B.value_binding ~loc ~pat:(B.pvar ~loc "search")
                    ~expr:(B.pexp_constraint ~loc (B.pexp_record ~loc fields None) (result_type ~loc "Router.search"));
                ]
                plan)
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
        B.value_binding ~loc
          ~pat:(input_pattern ~loc (search <> []))
          ~expr:(B.pexp_apply ~loc (B.evar ~loc "RouterServer.Input.forSearch") [ (Nolabel, B.evar ~loc "search") ]);
      ]
      folded
  in
  let fallback =
    B.pexp_fun ~loc (Labelled "search") None (B.pvar ~loc "search")
      (B.pexp_fun ~loc (Labelled "error") None (B.pvar ~loc "error") with_input)
  in
  match declaration.context with
  | None -> fallback
  | Some typ -> B.pexp_fun ~loc (Labelled "context") None (context_pattern ~loc typ fallback) fallback

let registry (declaration : Router_declaration.t) =
  let loc = declaration.loc in
  let endpoints = Router_declaration.endpoints declaration in
  let root_search = Router_declaration.root_search declaration in
  let routes =
    List.filter_map
      (function Router_declaration.Page route -> Some route | Router_declaration.RedirectTo _ -> None)
      endpoints
  in
  let parsed_routes =
    List.map (fun (route : Router_declaration.route) -> (route, Router_declaration.shapes route.path)) routes
  in
  let route_values =
    List.concat_map
      (function
        | Router_declaration.Page route ->
            Router_declaration.shapes route.path
            |> List.mapi (fun index shape ->
                endpoint ~context:declaration.context ~base_path:declaration.base_path
                  ~invalid_search:declaration.invalid_search ~root_search ~routes:parsed_routes ~primary:(index = 0)
                  ~shape route)
        | Router_declaration.RedirectTo redirect ->
            [
              redirect_endpoint ~context:declaration.context ~base_path:declaration.base_path
                ~invalid_search:declaration.invalid_search ~root_search redirect;
            ])
      endpoints
  in
  let base_path =
    B.pstr_value ~loc Nonrecursive
      [ B.value_binding ~loc ~pat:(B.pvar ~loc "basePath") ~expr:(B.estring ~loc (encoded_path declaration.base_path)) ]
  in
  let registry =
    B.pstr_value ~loc Nonrecursive
      [
        B.value_binding ~loc ~pat:(B.pvar ~loc "registry")
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
      match declaration.error_status with
      | Some status -> status
      | None ->
          let body =
            B.pexp_construct ~loc { txt = Longident.parse "RouterRuntime.Status.InternalServerError"; loc } None
          in
          B.pexp_fun ~loc Nolabel None (B.ppat_any ~loc) body
    in
    B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "applicationStatus") ~expr:expression ]
  in
  let server =
    let trailing_slash =
      let constructor =
        match declaration.trailing_slash with
        | Router_declaration.Redirect -> "RouterServer.TrailingSlash.Redirect"
        | Router_declaration.Reject -> "RouterServer.TrailingSlash.Reject"
      in
      B.pexp_construct ~loc { txt = Longident.parse constructor; loc } None
    in
    let expression =
      B.pexp_apply ~loc
        (B.evar ~loc
           (match declaration.context with
           | None -> "RouterServer.Server.make"
           | Some _ -> "RouterServer.Server.makeWithContext"))
        ([
           (Labelled "basePath", B.evar ~loc "basePath");
           (Labelled "registry", B.evar ~loc "registry");
           (Labelled "trailingSlash", trailing_slash);
           (Labelled "fallback", B.evar ~loc "fallback");
           (Labelled "applicationStatus", B.evar ~loc "applicationStatus");
         ]
        @ List.filter_map
            (fun (label, value) -> Option.map (fun value -> (Labelled label, B.ebool ~loc value)) value)
            [ ("interceptLinks", declaration.intercept_links); ("viewTransitions", declaration.view_transitions) ]
        @ Option.to_list
            (Option.map
               (fun literal -> (Labelled "pageCacheMaxAge", B.efloat ~loc literal))
               declaration.page_cache_max_age)
        @ [ (Nolabel, unit_expression ~loc) ])
    in
    B.pstr_value ~loc Nonrecursive [ B.value_binding ~loc ~pat:(B.pvar ~loc "server") ~expr:expression ]
  in
  redirect_search_types ~root_search endpoints @ [ base_path; registry; fallback; application_status; server ]
