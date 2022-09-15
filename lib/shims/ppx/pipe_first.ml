(* Based on https://github.com/jaredly/belt/blob/master/belt_ppx/Belt_ppx.ml *)

open Ppxlib

let traverser =
  object
    inherit Ast_traverse.map as super

    method! expression expr =
      let e = super#expression expr in
      let loc = e.pexp_loc in
      match e.pexp_desc with
      | Pexp_apply
          ( { pexp_desc = Pexp_ident { txt = Lident "|."; _ }; pexp_loc_stack }
          , [ (Nolabel, obj_arg); (Nolabel, fn) ] ) -> (
          let new_obj_arg = super#expression obj_arg in
          match fn with
          | { pexp_desc = Pexp_apply (fn, args); pexp_loc; _ } ->
              let fn = super#expression fn in
              let args =
                List.map (fun (lab, exp) -> (lab, super#expression exp)) args
              in
              { pexp_desc = Pexp_apply (fn, (Nolabel, new_obj_arg) :: args)
              ; pexp_attributes = []
              ; pexp_loc
              ; pexp_loc_stack
              }
          | { pexp_desc = Pexp_construct (lident, None)
            ; pexp_loc
            ; pexp_loc_stack
            } ->
              { pexp_desc = Pexp_construct (lident, Some new_obj_arg)
              ; pexp_attributes = []
              ; pexp_loc
              ; pexp_loc_stack
              }
          | _ ->
              Ast_builder.Default.pexp_apply ~loc (super#expression fn)
                [ (Nolabel, new_obj_arg) ])
      | _ -> super#expression e
  end

let () =
  Driver.register_transformation ~impl:traverser#structure "pipe_first_ppx"
