open Ppxlib

let incompatible_values = [ "cloneElement"; "createElement"; "createElementVariadic"; "jsxFragment" ]
let has_name names name = List.exists (String.equal name.txt) names

let erase_component_equations item =
  match item.psig_desc with
  | Psig_type (rec_flag, declarations) ->
      let declarations =
        List.map
          (fun declaration ->
            (* Native components accept the renderer's optional key argument. *)
            if has_name [ "component"; "componentLike" ] declaration.ptype_name then
              { declaration with ptype_manifest = None }
            else declaration)
          declarations
      in
      { item with psig_desc = Psig_type (rec_flag, declarations) }
  | _ -> item

let rec drop_optional_argument name type_ =
  match type_.ptyp_desc with
  | Ptyp_arrow (Optional label, _, output) when String.equal label name -> output
  | Ptyp_arrow (label, input, output) ->
      { type_ with ptyp_desc = Ptyp_arrow (label, input, drop_optional_argument name output) }
  | _ -> type_

let normalize_value value =
  let pval_type =
    match value.pval_name.txt with
    | "useDeferredValue" -> drop_optional_argument "initialValue" value.pval_type
    | "useActionState" -> drop_optional_argument "permalink" value.pval_type
    | _ -> value.pval_type
  in
  { value with pval_type; pval_prim = [] }

let normalize_event_module item =
  match item.psig_desc with
  | Psig_module
      ({
         pmd_name = { txt = Some "Event"; _ };
         pmd_type = { pmty_desc = Pmty_signature signature; _ } as module_type;
         _;
       } as module_) ->
      let mapper =
        object
          inherit Ast_traverse.map as super

          method! core_type type_ =
            match type_.ptyp_desc with
            | Ptyp_constr ({ txt = Ldot (Lident "Js", "t"); _ }, [ _ ]) ->
                {
                  type_ with
                  ptyp_desc =
                    Ptyp_constr
                      ({ txt = Ldot (Ldot (Lident "React", "Event"), "target_like"); loc = type_.ptyp_loc }, []);
                }
            | _ -> super#core_type type_
        end
      in
      let pmd_type = { module_type with pmty_desc = Pmty_signature (mapper#signature signature) } in
      { item with psig_desc = Psig_module { module_ with pmd_type } }
  | _ -> item

let strip_external_primitives signature =
  let mapper =
    object
      inherit Ast_traverse.map as super

      method! signature_item item =
        let item = super#signature_item item in
        match item.psig_desc with
        | Psig_value value -> { item with psig_desc = Psig_value (normalize_value value) }
        | _ -> item
    end
  in
  mapper#signature signature |> List.map erase_component_equations |> List.map normalize_event_module
  |> List.filter (fun item ->
      match item.psig_desc with Psig_value value -> not (has_name incompatible_values value.pval_name) | _ -> true)

let () = Driver.register_transformation ~intf:strip_external_primitives "compat-interface"
