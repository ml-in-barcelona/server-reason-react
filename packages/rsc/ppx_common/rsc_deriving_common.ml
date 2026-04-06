open Ppxlib
open Ppx_deriving_tools.Conv

let get_of_variant_case ?mark_as_seen ~variant ~polyvariant = function
  | Vcs_ctx_variant ctx -> Attribute.get ?mark_as_seen variant ctx
  | Vcs_ctx_polyvariant ctx -> Attribute.get ?mark_as_seen polyvariant ctx

let get_of_variant ?mark_as_seen ~variant ~polyvariant = function
  | Vrt_ctx_variant ctx -> Attribute.get ?mark_as_seen variant ctx
  | Vrt_ctx_polyvariant ctx -> Attribute.get ?mark_as_seen polyvariant ctx

let attr_json_name ctx = Attribute.declare "rsc.name" ctx Ast_pattern.(single_expr_payload (estring __')) (fun x -> x)

let vcs_attr_json_name =
  let variant = attr_json_name Attribute.Context.constructor_declaration in
  let polyvariant = attr_json_name Attribute.Context.rtag in
  get_of_variant_case ~variant ~polyvariant

let attr_json_allow_any ctx = Attribute.declare_flag "rsc.allow_any" ctx

let vcs_attr_json_allow_any =
  let variant = attr_json_allow_any Attribute.Context.constructor_declaration in
  let polyvariant = attr_json_allow_any Attribute.Context.rtag in
  fun ?mark_as_seen ctx ->
    match get_of_variant_case ~variant ~polyvariant ?mark_as_seen ctx with None -> false | Some () -> true

let ld_attr_json_key =
  Attribute.get
    (Attribute.declare "rsc.key" Attribute.Context.label_declaration
       Ast_pattern.(single_expr_payload (estring __'))
       (fun x -> x))

let ld_attr_json_option =
  Attribute.get (Attribute.declare "rsc.option" Attribute.Context.label_declaration Ast_pattern.(pstr nil) ())

let attr_json_allow_extra_fields ctx = Attribute.declare "rsc.allow_extra_fields" ctx Ast_pattern.(pstr nil) ()
let td_attr_json_allow_extra_fields = Attribute.get (attr_json_allow_extra_fields Attribute.Context.type_declaration)

let cd_attr_json_allow_extra_fields =
  Attribute.get (attr_json_allow_extra_fields Attribute.Context.constructor_declaration)

let ld_attr_json_default =
  Attribute.get
    (Attribute.declare "rsc.default" Attribute.Context.label_declaration
       Ast_pattern.(single_expr_payload __)
       (fun x -> x))

let ld_attr_json_drop_default =
  Attribute.get (Attribute.declare "rsc.drop_default" Attribute.Context.label_declaration Ast_pattern.(pstr nil) ())

let ld_attr_default ld =
  match ld_attr_json_default ld with
  | Some e -> Some e
  | None -> (
      match ld_attr_json_option ld with
      | Some () ->
          let loc = ld.pld_loc in
          Some [%expr Stdlib.Option.None]
      | None -> None)

let ld_drop_default ld =
  let loc = ld.pld_loc in
  match (ld_attr_json_drop_default ld, ld_attr_json_option ld) with
  | Some (), None -> Location.raise_errorf ~loc "found [@drop_default] attribute without [@option]"
  | Some (), Some () -> `Drop_option
  | None, _ -> `No
