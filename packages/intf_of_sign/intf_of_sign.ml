(* https://discuss.ocaml.org/t/how-can-i-generate-mli-files-from-ml-files/5427 *)
(* https://stackoverflow.com/questions/26821053/how-to-auto-generate-stubs-from-mli-file *)

[@@@warning "-32"]

module Builder = Ppxlib.Ast_builder.Default

let _read_lines file = In_channel.with_open_text file In_channel.input_all
let loc = Ppxlib.Location.none
let loc = Ppxlib.Location.none

let read_cmi sourcefile =
  try Cmi_format.read_cmi sourcefile with
  | Cmi_format.Error (Not_an_interface filepath) ->
      Format.eprintf "Error: '%s' is not an interface file" filepath;
      exit 2
  | Cmi_format.Error (Wrong_version_interface (filepath, version)) ->
      Format.eprintf "Error: '%s' has the wrong version: %s" filepath version;
      exit 2
  | Cmi_format.Error (Corrupted_interface filepath) ->
      Format.eprintf "Error: '%s' is corrupted" filepath;
      exit 2
  | _ ->
      Format.eprintf "ERROR!!!";
      exit 2

module Dummy_implementation = struct
  let with_loc txt = Ppxlib.{ txt; loc }
  let with_location txt = Location.{ txt; loc = Location.none }

  let not_implemented msg =
    let msg = Builder.pexp_constant ~loc (Pconst_string (msg, loc, None)) in
    [%expr "Error: " ^ [%e msg] ^ " is not implemented"]

  let of_argument _arg =
    let name = Builder.pvar ~loc "_" in
    [%pat? [%p name]]

  let of_const value =
    match value with
    | "string" -> [%expr ""]
    | "int" -> [%expr 0]
    | "float" -> [%expr 0.0]
    | "bool" -> [%expr false]
    | "unit" -> [%expr ()]
    | "char" -> [%expr 'a']
    | "list" -> [%expr []]
    | "array" -> [%expr [||]]
    | "option" -> [%expr None]
    | _ -> [%expr "???"]

  let read_desc_from_type_expr (type_expr : Types.type_expr) =
    let (type_expr : Types.transient_expr) = Obj.magic type_expr in
    type_expr.desc

  let of_value_description (description : Types.value_description) :
      Parsetree.expression =
    let rec of_type_desc desc =
      match desc with
      | Types.Tvar (Some var) -> [%expr [%e of_const var]]
      | Tvar None -> not_implemented "???"
      | Tarrow (arg_label, _type_expr, type_expr, _commutable) ->
          [%expr
            fun [%p of_argument arg_label] ->
              [%e of_type_desc (read_desc_from_type_expr type_expr)]]
      | Ttuple tuple ->
          Builder.pexp_tuple ~loc
            (List.map
               (fun type_expr ->
                 of_type_desc (read_desc_from_type_expr type_expr))
               tuple)
      | Tconstr (path, _type_exprs, _abbrev) -> of_const (Path.name path)
      | Tobject (_type_expr, _) -> not_implemented "Tobject"
      | Tfield (_name, _field_kind, _, _) -> not_implemented "Tfield"
      | Tnil -> not_implemented "Tnil"
      | Tlink _type_expr -> not_implemented "Tlink"
      | Tsubst (_type_expr, _type_expr_sub) -> not_implemented "Tsubst"
      | Tvariant _row_desc -> not_implemented "Tvariant"
      | Tunivar _var -> not_implemented "Tunivar"
      | Tpoly (_type_expr, _type_exprs) -> not_implemented "Tpoly"
      | Tpackage (_path, _package) -> not_implemented "Tpackage"
    in

    let type_desc = read_desc_from_type_expr description.val_type in
    of_type_desc type_desc

  let rec of_module_declaration module_declaration =
    match module_declaration with
    | Types.Mty_signature signature ->
        let structure_item_list = of_signature signature in
        Builder.pmod_structure ~loc structure_item_list
    | Mty_functor (functor_parameter, module_type) ->
        let functor_parameter = of_function_parameter functor_parameter in
        let module_expr = of_module_declaration module_type in
        Builder.pmod_functor ~loc functor_parameter module_expr
    (* TODO: Mty_alias and Mty_ident are implemented as ident, is that wrong? *)
    | Mty_alias path | Mty_ident path ->
        let path = Path.name path in
        let longident = with_loc (Ppxlib.Longident.Lident path) in
        Builder.pmod_ident ~loc longident

  and of_function_parameter functor_parameter : Parsetree.functor_parameter =
    (* and functor_parameter =
       | Unit
       | Named of Ident.t option * module_type *)
    match functor_parameter with
    | Unit -> Parsetree.Unit
    | Named (ident, module_type) ->
        let txt = Option.map Ident.name ident in
        let module_type = of_module_type module_type in
        Parsetree.Named ({ txt; loc = Location.none }, module_type)

  (* open Ast_helper
     let t_mty = Mty.signature [ t ]
     let fn_arg = Parsetree.Named(Location.(mkloc (Some "T") none), t_mty)
  *)
  (* let (functor_parameter ) =
       if type_declaration.type_params = [] then Unit
       else
         (* let module_type = Builder.type_declaration ~loc type_declaration in *)
         (* let module_type = Mty_ident () in
            Named (with_loc None, ) *)
         Unit
     in *)

  and ident_of_path (path : Path.t) =
    let path = Path.name path in
    with_location (Longident.Lident path)

  (* TODO: Missing *)
  and of_module_type module_type =
    match module_type with
    | Types.Mty_ident path -> Ast_helper.Mty.ident (ident_of_path path)
    | Mty_alias path -> Ast_helper.Mty.alias (ident_of_path path)
    | Mty_signature signature ->
        let signatures = of_signature_to_signature signature in
        Ast_helper.Mty.signature signatures
    | Mty_functor (functor_parameter, module_type) ->
        Ast_helper.Mty.functor_
          (of_functor_parameter functor_parameter)
          (of_module_type module_type)

  and of_signature_item_to_signature_item
      (signature_item : Types.signature_item) =
    match signature_item with
    | Sig_value (_ident, _value_description, _visibility) ->
        Ast_helper.Sig.type_ Nonrecursive []
    | Sig_module (_ident, _module_presence, _declaration, _rec, _visibility) ->
        Ast_helper.Sig.type_ Nonrecursive []
    | Sig_type (_ident, _type_declaration, _rec_, _visibility) ->
        Ast_helper.Sig.type_ Nonrecursive []
    | Sig_typext (_ident, _extension_constructor, _ext, _visibility) ->
        Ast_helper.Sig.type_ Nonrecursive []
    | Sig_modtype (_ident, _modtype_declaration, _visibility) ->
        Ast_helper.Sig.type_ Nonrecursive []
    | Sig_class (_ident, _class_declaration, _rec, _visibility) ->
        Ast_helper.Sig.type_ Nonrecursive []
    | Sig_class_type (_ident, _class_type_declaration, _rec, _visibility) ->
        Ast_helper.Sig.type_ Nonrecursive []

  and of_signature_to_signature signature =
    List.map of_signature_item_to_signature_item signature

  and of_functor_parameter functor_parameter =
    match functor_parameter with
    | Types.Unit -> Parsetree.Unit
    | Named (ident, module_type) ->
        let txt = Option.map Ident.name ident in
        let module_type = of_module_type module_type in
        Parsetree.Named ({ txt; loc = Location.none }, module_type)

  and of_type_declaration (type_declaration : Types.type_declaration) =
    let (functor_parameter : Parsetree.functor_parameter) =
      if type_declaration.type_params = [] then Unit
      else
        (* let module_type = Builder.type_declaration ~loc type_declaration in *)
        (* let module_type = Mty_ident () in
           Named (with_loc None, ) *)
        Unit
    in
    failwith "oftd" |> ignore;
    (* let module_expr = of_module_declaration module_type in *)
    let longident = with_loc (Ppxlib.Longident.Lident "lolwat") in
    let module_expr = Builder.pmod_ident ~loc longident in
    Builder.pmod_functor ~loc functor_parameter module_expr

  and of_signature_item (signature : Types.signature_item) =
    match signature with
    | Sig_value (ident, value_description, _visibility) ->
        let name = Builder.pvar ~loc @@ Ident.name ident in
        let value = of_value_description value_description in
        [%stri let [%p name] = [%e value]]
    | Sig_module (ident, _module_presence, declaration, _rec, _visibility) ->
        let txt = Ident.name ident in
        let name = with_loc (Some txt) in
        let module_expr = of_module_declaration declaration.md_type in
        Builder.pstr_module ~loc
          (Builder.module_binding ~loc ~name ~expr:module_expr)
    (* TODO: Implement nones *)
    | Sig_type (ident, type_declaration, _rec_, _visibility) ->
        let txt = Ident.name ident in
        let name = with_loc (Some txt) in
        let (type_declaration : Parsetree.type_declaration) =
          Obj.magic type_declaration
        in
        let t = Ast_helper.Sig.type_ Nonrecursive [ type_declaration ] in
        let t_mty = Ast_helper.Mty.signature [ t ] in
        let _parameter =
          Parsetree.Named ({ txt = Some "T"; loc = Location.none }, t_mty)
        in
        let expr = Ast_helper.Mod.structure [] in
        let binding = Builder.module_binding ~loc ~name ~expr in
        Builder.pstr_module ~loc binding
    | Sig_typext (_ident, _extension_constructor, _ext, _visibility) ->
        failwith "Sig_typext" |> ignore;
        [%stri let not_implemented = "Sig_typext"]
    | Sig_modtype (_ident, _modtype_declaration, _visibility) ->
        failwith "Sig_modtype" |> ignore;
        [%stri let not_implemented = "Sig_modtype"]
    | Sig_class (_ident, _class_declaration, _rec, _visibility) ->
        failwith "Sig_class" |> ignore;
        [%stri let not_implemented = "Sig_class"]
    | Sig_class_type (_ident, _class_type_declaration, _rec, _visibility) ->
        failwith "Sig_class_type" |> ignore;
        [%stri let not_implemented = "Sig_class_type"]

  and of_signature (signatures : Types.signature) =
    signatures |> List.map of_signature_item
end

let () =
  let sourcefile =
    "./_build/default/lib/webapi/.webapi_melange.objs/melange/webapi_melange__Webapi__Basa64.cmi"
  in
  let cmi = read_cmi sourcefile in
  let signature = cmi.cmi_sign in
  Format.pp_print_newline Format.std_formatter ();
  Printtyp.signature Format.std_formatter signature;
  Format.printf "\n\nimplementation\n================\n";
  let implementation = Dummy_implementation.of_signature signature in
  Pprintast.structure Format.std_formatter implementation;
  Format.pp_print_newline Format.std_formatter ()
