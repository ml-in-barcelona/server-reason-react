open Ppxlib

let incompatible_values =
  [ "cloneElement"; "createElement"; "createElementVariadic"; "forwardRef"; "jsxFragment"; "useDeferredValue" ]

(* These APIs intentionally expose native renderer representations instead of JavaScript ones. *)
let incompatible_modules = [ "Event"; "Experimental"; "Ref" ]
let has_name names name = List.exists (String.equal name.txt) names

let has_optional_name names name =
  Option.fold ~none:false ~some:(fun name -> List.exists (String.equal name) names) name.txt

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

let strip_external_primitives signature =
  let mapper =
    object
      inherit Ast_traverse.map as super

      method! signature_item item =
        let item = super#signature_item item in
        match item.psig_desc with
        | Psig_value value -> { item with psig_desc = Psig_value { value with pval_prim = [] } }
        | _ -> item
    end
  in
  mapper#signature signature |> List.map erase_component_equations
  |> List.filter (fun item ->
      match item.psig_desc with
      | Psig_value value -> not (has_name incompatible_values value.pval_name)
      | Psig_module module_ -> not (has_optional_name incompatible_modules module_.pmd_name)
      | _ -> true)

let () = Driver.register_transformation ~intf:strip_external_primitives "compat-interface"
