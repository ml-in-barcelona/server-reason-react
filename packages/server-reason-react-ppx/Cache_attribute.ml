open Ppxlib
open Ast_builder.Default

type scope = Request | Process
type errors = Keep | Retry

type settings = {
  scope : scope option;
  ttl : expression option;
  max : expression option;
  errors : errors option;
  tags : expression option;
  key : expression option;
}

let name = "cache"
let example = "[@cache { ttl = 30.; tags = [ `User id ] }]"
let is_cache attribute = String.equal attribute.attr_name.txt name
let has_cache attributes = List.exists is_cache attributes
let without_cache attributes = List.filter (fun attribute -> not (is_cache attribute)) attributes
let error ~loc fmt = Location.raise_errorf ~loc ("server-reason-react: [@cache] " ^^ fmt)

let constructor ~loc ~field expression =
  match expression.pexp_desc with
  | Pexp_construct ({ txt = Lident name | Ldot (_, name); _ }, None) -> name
  | _ -> error ~loc "%s takes a constructor, as in %s" field example

let settings_of_payload ~loc payload =
  let empty = { scope = None; ttl = None; max = None; errors = None; tags = None; key = None } in
  let settings =
    match payload with
    | PStr [] -> empty
    | PStr [ { pstr_desc = Pstr_eval ({ pexp_desc = Pexp_record (fields, None); _ }, _); _ } ] ->
        List.fold_left
          (fun settings ({ txt; loc }, value) ->
            match txt with
            | Lident "scope" -> (
                match constructor ~loc ~field:"scope" value with
                | "Request" -> { settings with scope = Some Request }
                | "Process" -> { settings with scope = Some Process }
                | other -> error ~loc "scope is Request or Process, not %s" other)
            | Lident "errors" -> (
                match constructor ~loc ~field:"errors" value with
                | "Keep" -> { settings with errors = Some Keep }
                | "Retry" -> { settings with errors = Some Retry }
                | other -> error ~loc "errors is Keep or Retry, not %s" other)
            | Lident "ttl" -> { settings with ttl = Some value }
            | Lident "max" -> { settings with max = Some value }
            | Lident "tags" -> { settings with tags = Some value }
            | Lident "key" -> { settings with key = Some value }
            | other -> error ~loc "has no field %s. Fields: scope, ttl, max, errors, tags, key" (Longident.name other))
          empty fields
    | _ -> error ~loc "takes no payload or a record, as in %s" example
  in
  let process_only = Option.is_some settings.ttl || Option.is_some settings.max in
  match (settings.scope, process_only) with
  | Some Request, true ->
      error ~loc "ttl and max need scope = Process. Remove scope = Request: ttl or max alone means Process"
  | Some scope, _ -> (scope, settings)
  | None, true -> (Process, settings)
  | None, false -> (Request, settings)

let base_encoder = function
  | "int" -> Some "int"
  | "string" -> Some "string"
  | "bool" -> Some "bool"
  | "float" -> Some "float"
  | "int64" -> Some "int64"
  | "char" -> Some "char"
  | "unit" -> Some "unit"
  | _ -> None

let rec encoder ~loc (core_type : core_type) =
  let key name = pexp_ident ~loc { txt = Ldot (Ldot (Ldot (Lident "React", "Cache"), "Key"), name); loc } in
  match core_type.ptyp_desc with
  | Ptyp_constr ({ txt = Lident name; _ }, []) when Option.is_some (base_encoder name) ->
      key (Option.get (base_encoder name))
  | Ptyp_constr ({ txt = Lident (("option" | "list" | "array") as name); _ }, [ argument ]) ->
      [%expr [%e key name] [%e encoder ~loc argument]]
  | Ptyp_tuple items ->
      let names = List.mapi (fun index _ -> "item" ^ string_of_int index) items in
      let pattern = ppat_tuple ~loc (List.map (fun name -> ppat_var ~loc { txt = name; loc }) names) in
      let parts =
        List.map2 (fun name item -> [%expr [%e encoder ~loc item] [%e evar ~loc name]]) names items |> elist ~loc
      in
      [%expr fun [%p pattern] -> React.Cache.Key.parts [%e parts]]
  | Ptyp_var _ | Ptyp_any -> error ~loc:core_type.ptyp_loc "needs a concrete type for each argument"
  | _ -> [%expr fun value -> RSC.to_cache_key ([%to_rsc: [%t core_type]] value)]

type argument = Keyed of string * core_type | Ignored

let argument_of_param param =
  match param.pparam_desc with
  | Pparam_newtype _ -> Ignored
  | Pparam_val (_, _, pattern) -> (
      match pattern.ppat_desc with
      | Ppat_construct ({ txt = Lident "()"; _ }, None) -> Ignored
      | Ppat_constraint ({ ppat_desc = Ppat_construct ({ txt = Lident "()"; _ }, None); _ }, _) -> Ignored
      | Ppat_constraint ({ ppat_desc = Ppat_any; _ }, _) | Ppat_any -> Ignored
      | Ppat_constraint ({ ppat_desc = Ppat_var { txt; _ }; _ }, core_type) -> Keyed (txt, core_type)
      | Ppat_var { txt; loc } -> error ~loc "needs a type annotation on argument %s, as in (%s : int)" txt txt
      | _ -> error ~loc:pattern.ppat_loc "needs each argument to be a name with a type, as in ~(id : int)")

let wrap_body ~loc ~settings ~cache body params =
  let key =
    match settings.key with
    | Some key -> key
    | None -> (
        let parts =
          List.filter_map
            (fun param ->
              match argument_of_param param with
              | Keyed (name, core_type) -> Some [%expr [%e encoder ~loc core_type] [%e evar ~loc name]]
              | Ignored -> None)
            params
        in
        match parts with [] -> [%expr ""] | parts -> [%expr React.Cache.Key.parts [%e elist ~loc parts]])
  in
  let tags = match settings.tags with Some tags -> [ (Labelled "tags", tags) ] | None -> [] in
  pexp_apply ~loc [%expr React.Cache.run]
    ([ (Nolabel, evar ~loc cache); (Labelled "key", key) ] @ tags @ [ (Nolabel, [%expr fun () -> [%e body]]) ])

let rec rewrite_function ~settings ~cache ~params expression =
  let loc = expression.pexp_loc in
  match expression.pexp_desc with
  | Pexp_function (_, _, Pfunction_cases _) -> error ~loc "needs named arguments, not function cases"
  | Pexp_function (new_params, constraint_, Pfunction_body body) ->
      let params = params @ new_params in
      let body =
        match (body.pexp_desc, constraint_) with
        | Pexp_function (_, _, Pfunction_body _), None -> rewrite_function ~settings ~cache ~params body
        | _ -> wrap_body ~loc ~settings ~cache body params
      in
      { expression with pexp_desc = Pexp_function (new_params, constraint_, Pfunction_body body) }
  | _ -> error ~loc "goes on a function, as in let[@cache] viewer ~(id : int) = ..."

let make_cache ~loc ~name ~scope ~settings =
  let optional label = function None -> [] | Some value -> [ (Labelled label, value) ] in
  let scope = match scope with Request -> [%expr React.Cache.Request] | Process -> [%expr React.Cache.Process] in
  let errors =
    Option.map (function Keep -> [%expr React.Cache.Keep] | Retry -> [%expr React.Cache.Retry]) settings.errors
  in
  pexp_apply ~loc [%expr React.Cache.make]
    ([ (Labelled "name", estring ~loc name); (Labelled "scope", scope) ]
    @ optional "ttl" settings.ttl @ optional "max" settings.max @ optional "errors" errors
    @ [ (Nolabel, [%expr ()]) ])

let cache_name ~module_path binding_name = String.concat "." (module_path @ [ binding_name ])

let rewrite_binding ~native ~module_path binding =
  match List.find_opt is_cache binding.pvb_attributes with
  | None -> binding
  | Some attribute -> (
      let loc = attribute.attr_loc in
      let scope, settings = settings_of_payload ~loc attribute.attr_payload in
      let binding = { binding with pvb_attributes = without_cache binding.pvb_attributes } in
      let binding_name =
        match binding.pvb_pat.ppat_desc with
        | Ppat_var { txt; _ } -> txt
        | _ -> error ~loc:binding.pvb_pat.ppat_loc "goes on a binding with a name, as in let[@cache] viewer = ..."
      in
      match (native, scope) with
      | false, Process -> error ~loc "scope = Process is for server code only: the browser has no process cache"
      | false, Request -> binding
      | true, _ ->
          let cache = "server_reason_react_cache" in
          let wrapped = rewrite_function ~settings ~cache ~params:[] binding.pvb_expr in
          let expr =
            [%expr
              let [%p ppat_var ~loc { txt = cache; loc }] =
                [%e make_cache ~loc ~name:(cache_name ~module_path binding_name) ~scope ~settings]
              in
              [%e wrapped]]
          in
          { binding with pvb_expr = expr })

let rewrite_structure_item ~native ~module_path item =
  match item.pstr_desc with
  | Pstr_value (rec_flag, bindings) when List.exists (fun binding -> has_cache binding.pvb_attributes) bindings -> (
      try
        match rec_flag with
        | Recursive -> error ~loc:item.pstr_loc "does not support let rec"
        | Nonrecursive ->
            { item with pstr_desc = Pstr_value (rec_flag, List.map (rewrite_binding ~native ~module_path) bindings) }
      with Location.Error error -> pstr_extension ~loc:item.pstr_loc (Location.Error.to_extension error) [])
  | _ -> item

let check_local_binding expression =
  match expression.pexp_desc with
  | Pexp_let (_, bindings, _) when List.exists (fun binding -> has_cache binding.pvb_attributes) bindings ->
      let loc = expression.pexp_loc in
      pexp_extension ~loc
        (Location.error_extensionf ~loc
           "server-reason-react: [@cache] goes on a top-level binding, so that its cache is created once")
  | _ -> expression
