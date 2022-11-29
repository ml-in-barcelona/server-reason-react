(* Based on https://github.com/jaredly/belt/blob/master/belt_ppx/Belt_ppx.ml,
   rewriten in ppxlib register and Context_free.Rule.special_function *)

open Ppxlib

let expander e =
  let rec expander' e =
    let loc = e.pexp_loc in
    match e.pexp_desc with
    | Pexp_apply
        ( { pexp_desc = Pexp_ident { txt = Lident "|."; _ }; pexp_loc_stack }
        , [ (Nolabel, arg); (Nolabel, fn) ] ) -> (
        let fn = Option.value ~default:fn (expander' fn) in
        let arg = Option.value ~default:arg (expander' arg) in
        match fn with
        | { pexp_desc = Pexp_apply (fn, args); pexp_loc; _ } ->
            let args =
              List.filter_map
                (fun (lab, exp) ->
                  match expander' exp with
                  | Some e -> Some (lab, e)
                  | None -> Some (lab, exp))
                args
            in
            Some
              { pexp_desc = Pexp_apply (fn, (Nolabel, arg) :: args)
              ; pexp_attributes = []
              ; pexp_loc
              ; pexp_loc_stack
              }
        | { pexp_desc = Pexp_construct (lident, None)
          ; pexp_loc
          ; pexp_loc_stack
          } ->
            Some
              { pexp_desc = Pexp_construct (lident, Some arg)
              ; pexp_attributes = []
              ; pexp_loc
              ; pexp_loc_stack
              }
        | _ -> Some (Ast_builder.Default.pexp_apply ~loc fn [ (Nolabel, arg) ]))
    | _ -> None
  in
  expander' e

let () =
  Driver.register_transformation
    ~rules:[ Context_free.Rule.special_function "( |. )" expander ]
    "pipe_first_ppx"
