open Printf
open StdLabels
open Ppxlib
open Ast_builder.Default
open Ppx_deriving_tools
open Ppx_deriving_tools.Conv
open Rsc_deriving_common

module Of_rsc = struct
  let with_refs ~loc prefix fs inner =
    let gen_name n = sprintf "%s_%s" prefix n in
    let gen_expr (n : label loc) = pexp_ident ~loc:n.loc { loc = n.loc; txt = lident (gen_name n.txt) } in
    List.fold_left (List.rev fs) ~init:(inner gen_expr) ~f:(fun next ld ->
        let n = ld.pld_name in
        let patt = ppat_var ~loc:n.loc { loc = n.loc; txt = gen_name n.txt } in
        [%expr
          let [%p patt] =
            ref
              [%e
                match ld_attr_default ld with
                | Some default -> [%expr Stdlib.Option.Some [%e default]]
                | None -> [%expr Stdlib.Option.None]]
          in
          [%e next]])

  let build_tuple ~loc derive es ts =
    let args =
      List.fold_left
        (List.rev (List.combine es ts))
        ~init:[]
        ~f:(fun prev (x, t) ->
          let this = derive t [%expr RSC.of_model [%e x]] in
          this :: prev)
    in
    pexp_tuple ~loc args

  let build_record ~allow_extra_fields ~loc derive fs x fields make =
    with_refs ~loc "x" fs @@ fun ename ->
    let handle_field k v =
      let fail_case =
        [%pat? name]
        -->
        if allow_extra_fields then [%expr ()]
        else [%expr RSC.of_rsc_error ~rsc:[%e x] (Stdlib.Printf.sprintf {|did not expect field "%s"|} name)]
      in
      let cases =
        List.fold_left (List.rev fs) ~init:[ fail_case ] ~f:(fun next ld ->
            let key = Option.value ~default:ld.pld_name (ld_attr_json_key ld) in
            pstring ~loc:key.loc key.txt
            --> [%expr [%e ename ld.pld_name] := Stdlib.Option.Some [%e derive ld.pld_type [%expr RSC.of_model [%e v]]]]
            :: next)
      in
      pexp_match ~loc k cases
    in
    let build =
      let fields =
        List.map fs ~f:(fun ld ->
            let key = Option.value ~default:ld.pld_name (ld_attr_json_key ld) in
            let default = ld_attr_default ld in
            ( map_loc lident ld.pld_name,
              [%expr
                match Stdlib.( ! ) [%e ename ld.pld_name] with
                | Stdlib.Option.Some v -> v
                | Stdlib.Option.None ->
                    [%e
                      match default with
                      | Some default -> default
                      | None ->
                          [%expr
                            RSC.of_rsc_error ~rsc:[%e x] [%e estring ~loc:key.loc (sprintf "expected field %S" key.txt)]]]]
            ))
      in
      pexp_record ~loc fields None
    in
    [%expr
      let rec iter = function
        | [] -> ()
        | (n', v) :: rest ->
            [%e handle_field [%expr n'] [%expr v]];
            iter rest
      in
      iter [%e fields];
      [%e make build]]

  let derive_of_tuple derive t x =
    let loc = t.tpl_loc in
    let n = List.length t.tpl_types in
    let xpatt, xexprs = gen_pat_list ~loc "x" n in
    let model = [%expr RSC.to_model [%e x]] in
    pexp_match ~loc model
      [
        [%pat? React.Model.List [%p xpatt]] --> build_tuple ~loc derive xexprs t.tpl_types;
        [%pat? _]
        --> [%expr RSC.of_rsc_error ~rsc:[%e x] [%e estring ~loc (sprintf "expected an array of length %i" n)]];
      ]

  let derive_of_record derive t x =
    let loc = t.rcd_loc in
    let allow_extra_fields = Option.is_some (td_attr_json_allow_extra_fields t.rcd_ctx) in
    let model = [%expr RSC.to_model [%e x]] in
    pexp_match ~loc model
      [
        [%pat? React.Model.Assoc fs] --> build_record ~allow_extra_fields ~loc derive t.rcd_fields x [%expr fs] Fun.id;
        [%pat? _] --> [%expr RSC.of_rsc_error ~rsc:[%e x] [%e estring ~loc "expected an object"]];
      ]

  let derive_of_variant_case derive make vcs =
    match vcs with
    | Vcs_tuple (n, t) when vcs_attr_json_allow_any t.tpl_ctx ->
        let loc = n.loc in
        [%pat? _] --> make (Some [%expr x])
    | Vcs_tuple (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.tpl_ctx) in
        let arity = List.length t.tpl_types in
        if arity = 0 then
          [%pat? React.Model.List [ React.Model.Json (`String [%p pstring ~loc:n.loc n.txt]) ]] --> make None
        else
          let xpatt, xexprs = gen_pat_list ~loc "x" arity in
          [%pat? React.Model.List (React.Model.Json (`String [%p pstring ~loc:n.loc n.txt]) :: [%p xpatt])]
          --> make (Some (build_tuple ~loc derive xexprs t.tpl_types))
    | Vcs_record (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.rcd_ctx) in
        let allow_extra_fields =
          match t.rcd_ctx with
          | Vcs_ctx_variant cd -> Option.is_some (cd_attr_json_allow_extra_fields cd)
          | Vcs_ctx_polyvariant _ -> false
        in
        [%pat? React.Model.List [ React.Model.Json (`String [%p pstring ~loc:n.loc n.txt]); React.Model.Assoc fs ]]
        --> build_record ~allow_extra_fields ~loc derive t.rcd_fields [%expr x] [%expr fs] (fun e -> make (Some e))

  let cmp_sort_vcs vcs1 vcs2 =
    let allow_any_1 = vcs_attr_json_allow_any vcs1 and allow_any_2 = vcs_attr_json_allow_any vcs2 in
    match (allow_any_1, allow_any_2) with true, true | false, false -> 0 | true, false -> -1 | false, true -> 1

  let deriving : Ppx_deriving_tools.deriving =
    deriving_of_match () ~name:"of_rsc"
      ~of_t:(fun ~loc -> [%type: RSC.t])
      ~cmp_sort_vcs ~derive_of_tuple ~derive_of_record ~derive_of_variant_case
end

module To_rsc = struct
  let gen_exp_pat ~loc prefix =
    let n = gen_symbol ~prefix () in
    (evar ~loc n, pvar ~loc n)

  let derive_of_tuple derive t es =
    let loc = t.tpl_loc in
    [%expr RSC.Primitives.list_values_to_rsc [%e elist ~loc (List.map2 t.tpl_types es ~f:derive)]]

  let derive_of_record derive t es =
    let loc = t.rcd_loc in
    let ebnds, pbnds = gen_exp_pat ~loc "bnds" in
    let e =
      List.combine t.rcd_fields es
      |> List.fold_left ~init:ebnds ~f:(fun acc (ld, x) ->
          let key = Option.value ~default:ld.pld_name (ld_attr_json_key ld) in
          let k = estring ~loc:key.loc key.txt in
          let v = derive ld.pld_type x in
          let ebnds =
            match ld_drop_default ld with
            | `No -> [%expr ([%e k], [%e v]) :: [%e ebnds]]
            | `Drop_option ->
                [%expr
                  match [%e x] with
                  | Stdlib.Option.None -> [%e ebnds]
                  | Stdlib.Option.Some _ -> ([%e k], [%e v]) :: [%e ebnds]]
          in
          [%expr
            let [%p pbnds] = [%e ebnds] in
            [%e acc]])
    in
    [%expr
      RSC.Primitives.assoc_to_rsc
        (let [%p pbnds] = [] in
         [%e e])]

  let derive_of_variant_case derive vcs es =
    match vcs with
    | Vcs_tuple (_n, t) when vcs_attr_json_allow_any t.tpl_ctx -> (
        match es with [ x ] -> x | xs -> failwith (sprintf "expected a tuple of length 1, got %i" (List.length xs)))
    | Vcs_tuple (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.tpl_ctx) in
        [%expr
          RSC.Primitives.list_values_to_rsc
            (RSC.Primitives.string_to_rsc [%e estring ~loc:n.loc n.txt]
            :: [%e elist ~loc (List.map2 t.tpl_types es ~f:derive)])]
    | Vcs_record (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.rcd_ctx) in
        [%expr
          RSC.Primitives.list_values_to_rsc
            [ RSC.Primitives.string_to_rsc [%e estring ~loc:n.loc n.txt]; [%e derive_of_record derive t es] ]]

  let deriving : Ppx_deriving_tools.deriving =
    deriving_to () ~name:"to_rsc"
      ~t_to:(fun ~loc -> [%type: RSC.t])
      ~derive_of_tuple ~derive_of_record ~derive_of_variant_case
end

let () =
  let _of_rsc = Ppx_deriving_tools.register Of_rsc.deriving in
  let _to_rsc = Ppx_deriving_tools.register To_rsc.deriving in
  let (_ : Deriving.t) = Ppx_deriving_tools.register_combined "rsc" [ To_rsc.deriving; Of_rsc.deriving ] in
  ()
