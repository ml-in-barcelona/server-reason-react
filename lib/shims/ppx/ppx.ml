(* https://github.com/jaredly/belt/blob/master/belt_ppx/Belt_ppx.ml *)

open Ppxlib

let expand_pipe pexp_apply =
  match pexp_apply with
  | { pexp_desc = Pexp_apply (_f, _args); pexp_attributes = _attrs; _ } -> None
  | _ -> None

let () =
  Driver.register_transformation
    ~rules:[ Context_free.Rule.special_function "|." expand_pipe ]
    "pipe_ppx"
