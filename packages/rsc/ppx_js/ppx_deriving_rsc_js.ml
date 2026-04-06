open Printf
open StdLabels
open Ppxlib
open Ast_builder.Default
open Ppx_deriving_tools
open Ppx_deriving_tools.Conv
open Rsc_deriving_common

module Of_rsc = struct
  let build_tuple ~loc derive si (ts : core_type list) e =
    pexp_tuple ~loc (List.mapi ts ~f:(fun i t -> derive t [%expr Js.Array.unsafe_get [%e e] [%e eint ~loc (si + i)]]))

  let build_js_type ~loc (fs : label_declaration list) =
    let f ld =
      let n = ld.pld_name in
      let n = Option.value ~default:n (ld_attr_json_key ld) in
      let pof_desc = Otag (n, [%type: RSC.t Js.undefined]) in
      { pof_loc = loc; pof_attributes = []; pof_desc }
    in
    let row = ptyp_object ~loc (List.map fs ~f) Closed in
    [%type: [%t row] Js.t]

  let build_record ~loc derive (fs : label_declaration list) x make =
    let handle_field fs ld =
      ( map_loc lident ld.pld_name,
        let n = ld.pld_name in
        let n = Option.value ~default:n (ld_attr_json_key ld) in
        [%expr
          match Js.Undefined.toOption [%e fs]##[%e pexp_ident ~loc:n.loc (map_loc lident n)] with
          | Stdlib.Option.Some v -> [%e derive ld.pld_type [%expr v]]
          | Stdlib.Option.None ->
              [%e
                match ld_attr_default ld with
                | Some default -> default
                | None ->
                    [%expr
                      RSC.of_rsc_error ~rsc:[%e x] [%e estring ~loc (sprintf "expected field %S to be present" n.txt)]]]]
      )
    in
    [%expr
      let fs = (Obj.magic [%e x] : [%t build_js_type ~loc fs]) in
      [%e make (pexp_record ~loc (List.map fs ~f:(handle_field [%expr fs])) None)]]

  let is_object ~loc x =
    [%expr
      Stdlib.( && )
        (Stdlib.( = ) (Js.typeof [%e x]) "object")
        (Stdlib.( && )
           (Stdlib.not (Js.Array.isArray [%e x]))
           (Stdlib.not (Stdlib.( == ) (Obj.magic [%e x] : 'a Js.null) Js.null)))]

  let ensure_object ~loc x =
    [%expr if Stdlib.not [%e is_object ~loc x] then RSC.of_rsc_error ~rsc:[%e x] [%e estring ~loc "expected an object"]]

  let ensure_array_len ~loc ~allow_any_constr ~else_ n len x =
    [%expr
      if Stdlib.( <> ) [%e len] [%e eint ~loc n] then
        [%e
          match allow_any_constr with
          | Some allow_any_constr -> allow_any_constr x
          | None -> [%expr RSC.of_rsc_error ~rsc:[%e x] [%e estring ~loc (sprintf "expected an array of length %i" n)]]]
      else [%e else_]]

  let derive_of_tuple derive t x =
    let loc = t.tpl_loc in
    let n = List.length t.tpl_types in
    [%expr
      if
        Stdlib.( && )
          (Js.Array.isArray [%e x])
          (Stdlib.( = ) (Js.Array.length (Obj.magic [%e x] : RSC.t array)) [%e eint ~loc n])
      then
        let es = (Obj.magic [%e x] : RSC.t array) in
        [%e build_tuple ~loc derive 0 t.tpl_types [%expr es]]
      else RSC.of_rsc_error ~rsc:[%e x] [%e estring ~loc (sprintf "expected an array of length %i" n)]]

  let derive_of_record derive t x =
    let loc = t.rcd_loc in
    [%expr
      [%e ensure_object ~loc x];
      [%e build_record ~loc derive t.rcd_fields x Fun.id]]

  let derive_of_variant _derive t ~allow_any_constr body x =
    let loc = t.vrt_loc in
    [%expr
      if Js.Array.isArray [%e x] then
        let array = (Obj.magic [%e x] : RSC.t array) in
        let len = Js.Array.length array in
        if Stdlib.( > ) len 0 then
          let tag = Js.Array.unsafe_get array 0 in
          if Stdlib.( = ) (Js.typeof tag) "string" then
            let tag = (Obj.magic tag : string) in
            [%e body]
          else
            [%e
              match allow_any_constr with
              | Some allow_any_constr -> allow_any_constr x
              | None -> [%expr RSC.of_rsc_error ~rsc:[%e x] "expected a non-empty tagged array with a string tag"]]
        else
          [%e
            match allow_any_constr with
            | Some allow_any_constr -> allow_any_constr x
            | None -> [%expr RSC.of_rsc_error ~rsc:[%e x] "expected a non-empty tagged array"]]
      else
        [%e
          match allow_any_constr with
          | Some allow_any_constr -> allow_any_constr x
          | None -> [%expr RSC.of_rsc_error ~rsc:[%e x] "expected a non-empty tagged array"]]]

  let derive_of_variant_case derive make c ~allow_any_constr next =
    match c with
    | Vcs_record (n, r) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name r.rcd_ctx) in
        [%expr
          if Stdlib.( = ) tag [%e estring ~loc:n.loc n.txt] then
            [%e
              ensure_array_len ~loc ~allow_any_constr 2 [%expr len] [%expr x]
                ~else_:
                  [%expr
                    let fs = Js.Array.unsafe_get array 1 in
                    [%e ensure_object ~loc [%expr fs]];
                    [%e build_record ~loc derive r.rcd_fields [%expr fs] (fun e -> make (Some e))]]]
          else [%e next]]
    | Vcs_tuple (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.tpl_ctx) in
        let arity = List.length t.tpl_types in
        [%expr
          if Stdlib.( = ) tag [%e estring ~loc:n.loc n.txt] then
            [%e
              ensure_array_len ~loc ~allow_any_constr (arity + 1) [%expr len] [%expr x]
                ~else_:
                  (if Stdlib.( = ) arity 0 then make None
                   else make (Some (build_tuple ~loc derive 1 t.tpl_types [%expr array])))]
          else [%e next]]

  let is_allow_any_constr vcs = vcs_attr_json_allow_any vcs

  let deriving : Ppx_deriving_tools.deriving =
    deriving_of () ~name:"of_rsc"
      ~of_t:(fun ~loc -> [%type: RSC.t])
      ~is_allow_any_constr ~derive_of_tuple ~derive_of_record ~derive_of_variant ~derive_of_variant_case
end

module To_rsc = struct
  let derive_of_tuple derive t es =
    let loc = t.tpl_loc in
    [%expr RSC.Primitives.list_values_to_rsc [%e elist ~loc (List.map2 t.tpl_types es ~f:derive)]]

  let derive_of_record derive t es =
    let loc = t.rcd_loc in
    let ebnds, pbnds =
      let n = gen_symbol ~prefix:"bnds" () in
      (evar ~loc n, pvar ~loc n)
    in
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

  let derive_of_variant_case derive c es =
    match c with
    | Vcs_record (n, r) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name r.rcd_ctx) in
        [%expr
          RSC.Primitives.list_values_to_rsc
            [ RSC.Primitives.string_to_rsc [%e estring ~loc:n.loc n.txt]; [%e derive_of_record derive r es] ]]
    | Vcs_tuple (_n, t) when vcs_attr_json_allow_any t.tpl_ctx -> (
        match es with [ x ] -> x | xs -> failwith (sprintf "expected a tuple of length 1, got %i" (List.length xs)))
    | Vcs_tuple (n, t) ->
        let loc = n.loc in
        let n = Option.value ~default:n (vcs_attr_json_name t.tpl_ctx) in
        [%expr
          RSC.Primitives.list_values_to_rsc
            (RSC.Primitives.string_to_rsc [%e estring ~loc:n.loc n.txt]
            :: [%e elist ~loc (List.map2 t.tpl_types es ~f:derive)])]

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
