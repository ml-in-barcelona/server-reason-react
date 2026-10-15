open Ppxlib
module Builder = Ast_builder.Default

(* Only the React-specific rule lives here. Linking ppx_platform registers its
   rules and the single -js flag; we read its mode instead of adding another. *)
let has_browser_only_attribute expr =
  match expr.pexp_desc with Pexp_extension ({ txt = "browser_only" }, _) -> true | _ -> false

let use_effect (expr : expression) =
  let add_browser_only_extension expr =
    match expr.pexp_desc with
    | (Pexp_apply (_, [ (Nolabel, effect_body) ]) | Pexp_apply (_, [ (Nolabel, effect_body); _ ]))
      when has_browser_only_attribute effect_body ->
        None
    | Pexp_apply (apply_expr, [ (Nolabel, effect_body); second_arg ]) ->
        let loc = expr.pexp_loc in
        let new_effect_body = [%expr [%browser_only [%e effect_body]]] in
        let new_effect_fun = Builder.pexp_apply ~loc apply_expr [ (Nolabel, new_effect_body); second_arg ] in
        Some new_effect_fun
    | Pexp_apply (apply_expr, [ (Nolabel, effect_body) ]) ->
        let loc = expr.pexp_loc in
        let new_effect_body = [%expr [%browser_only [%e effect_body]]] in
        let new_effect_fun = Builder.pexp_apply ~loc apply_expr [ (Nolabel, new_effect_body) ] in
        Some new_effect_fun
    | _ -> None
  in
  match !Ppx_platform.mode with
  (* When it's -js, keep item as it is *)
  | Js -> None
  | Native -> add_browser_only_extension expr

let use_effects =
  let arities = "" :: List.init 8 string_of_int in
  List.concat_map
    (fun hook ->
      List.map (fun arity -> Context_free.Rule.special_function ("React." ^ hook ^ arity) use_effect) arities)
    [ "useEffect"; "useLayoutEffect" ]

let () = Driver.register_transformation "browser_ppx_effects" ~rules:use_effects
