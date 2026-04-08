open Printf
open Ppxlib
open Ast_builder.Default
open StdLabels
open Expansion_helpers

let not_supported ~loc what = Location.raise_errorf ~loc "%s are not supported" what
let map_loc f a_loc = { a_loc with txt = f a_loc.txt }

let gen_bindings ~loc prefix n =
  List.split
    (List.init ~len:n ~f:(fun i ->
         let id = sprintf "%s_%i" prefix i in
         let patt = ppat_var ~loc { loc; txt = id } in
         let expr = pexp_ident ~loc { loc; txt = lident id } in
         (patt, expr)))

let gen_tuple ~loc prefix n =
  let ps, es = gen_bindings ~loc prefix n in
  (ps, pexp_tuple ~loc es)

let gen_record ~loc prefix fs =
  let ps, es =
    List.split
      (List.map fs ~f:(fun (n, _attrs, _t) ->
           let id = sprintf "%s_%s" prefix n.txt in
           let patt = ppat_var ~loc { loc = n.loc; txt = id } in
           let expr = pexp_ident ~loc { loc = n.loc; txt = lident id } in
           ((map_loc lident n, patt), expr)))
  in
  let ns, ps = List.split ps in
  (ps, pexp_record ~loc (List.combine ns es) None)

let gen_pat_tuple ~loc prefix n =
  let patts, exprs = gen_bindings ~loc prefix n in
  (ppat_tuple ~loc patts, exprs)

let gen_pat_list ~loc prefix n =
  let patts, exprs = gen_bindings ~loc prefix n in
  let patt = List.fold_left (List.rev patts) ~init:[%pat? []] ~f:(fun prev patt -> [%pat? [%p patt] :: [%p prev]]) in
  (patt, exprs)

let gen_pat_record ~loc prefix ns =
  let xs =
    List.map ns ~f:(fun n ->
        let id = sprintf "%s_%s" prefix n.txt in
        let patt = ppat_var ~loc { loc = n.loc; txt = id } in
        let expr = pexp_ident ~loc { loc = n.loc; txt = lident id } in
        ((map_loc lident n, patt), expr))
  in
  (ppat_record ~loc (List.map xs ~f:fst) Closed, List.map xs ~f:snd)

let ( --> ) pc_lhs pc_rhs = { pc_lhs; pc_rhs; pc_guard = None }
let derive_of_label name = mangle (Suffix name)
let derive_of_longident name = mangle_lid (Suffix name)

let rsc_primitives_ident ~loc name =
  pexp_ident ~loc { loc; txt = Longident.Ldot (Longident.Ldot (Longident.Lident "RSC", "Primitives"), name) }

let builtin_deriver_name suffix = function
  | Longident.Lident "string" -> Some ("string_" ^ suffix)
  | Longident.Lident "bool" -> Some ("bool_" ^ suffix)
  | Longident.Lident "float" -> Some ("float_" ^ suffix)
  | Longident.Lident "int" -> Some ("int_" ^ suffix)
  | Longident.Lident "int64" -> Some ("int64_" ^ suffix)
  | Longident.Lident "char" -> Some ("char_" ^ suffix)
  | Longident.Lident "unit" -> Some ("unit_" ^ suffix)
  | Longident.Lident "option" -> Some ("option_" ^ suffix)
  | Longident.Lident "list" -> Some ("list_" ^ suffix)
  | Longident.Lident "array" -> Some ("array_" ^ suffix)
  | Longident.Lident "result" -> Some ("result_" ^ suffix)
  | Longident.Ldot (Longident.Lident "React", "element") -> Some ("react_element_" ^ suffix)
  | Longident.Ldot (Longident.Ldot (Longident.Lident "Js", "Promise"), "t") -> Some ("promise_" ^ suffix)
  | Longident.Ldot (Longident.Lident "Runtime", "server_function") -> Some ("server_function_" ^ suffix)
  | _ -> None

let ederiver name (lid : Longident.t loc) =
  match builtin_deriver_name name lid.txt with
  | Some builtin -> rsc_primitives_ident ~loc:lid.loc builtin
  | None -> pexp_ident ~loc:lid.loc (map_loc (derive_of_longident name) lid)

type deriver = As_fun of (expression -> expression) | As_val of expression

let as_val ~loc deriver x = match deriver with As_fun f -> f x | As_val f -> [%expr [%e f] [%e x]]
let as_fun ~loc deriver = match deriver with As_fun f -> [%expr fun x -> [%e f [%expr x]]] | As_val f -> f

class virtual deriving =
  object
    method virtual name : label
    method virtual extension : loc:location -> path:label -> core_type -> expression
    method virtual str_type_decl : ctxt:Expansion_context.Deriver.t -> rec_flag * type_declaration list -> structure
    method virtual sig_type_decl : ctxt:Expansion_context.Deriver.t -> rec_flag * type_declaration list -> signature
  end

let register ?deps deriving =
  let args = Deriving.Args.empty in
  let str_type_decl = deriving#str_type_decl in
  let sig_type_decl = deriving#sig_type_decl in
  Deriving.add deriving#name ~extension:deriving#extension
    ~str_type_decl:(Deriving.Generator.V2.make ?deps args str_type_decl)
    ~sig_type_decl:(Deriving.Generator.V2.make ?deps args sig_type_decl)

let register_combined ?deps name derivings =
  let args = Deriving.Args.empty in
  let str_type_decl ~ctxt bindings =
    List.fold_left derivings ~init:[] ~f:(fun str d -> d#str_type_decl ~ctxt bindings @ str)
  in
  let sig_type_decl ~ctxt bindings =
    List.fold_left derivings ~init:[] ~f:(fun str d -> d#sig_type_decl ~ctxt bindings @ str)
  in
  Deriving.add name
    ~str_type_decl:(Deriving.Generator.V2.make ?deps args str_type_decl)
    ~sig_type_decl:(Deriving.Generator.V2.make ?deps args sig_type_decl)

module Schema = struct
  let repr_row_field field =
    match field.prf_desc with
    | Rtag (id, _, []) -> `Rtag (id, [])
    | Rtag (id, _, [ { ptyp_desc = Ptyp_tuple ts; _ } ]) -> `Rtag (id, ts)
    | Rtag (id, _, [ t ]) -> `Rtag (id, [ t ])
    | Rtag (_, _, _ :: _) -> not_supported ~loc:field.prf_loc "polyvariant constructor with more than one argument"
    | Rinherit { ptyp_desc = Ptyp_constr (id, ts); _ } -> `Rinherit (id, ts)
    | Rinherit _ -> not_supported ~loc:field.prf_loc "this polyvariant inherit"

  let repr_core_type ty =
    let loc = ty.ptyp_loc in
    match ty.ptyp_desc with
    | Ptyp_tuple ts -> `Ptyp_tuple ts
    | Ptyp_constr (id, ts) -> `Ptyp_constr (id, ts)
    | Ptyp_var txt -> `Ptyp_var { txt; loc = ty.ptyp_loc }
    | Ptyp_variant (fs, Closed, None) -> `Ptyp_variant fs
    | Ptyp_variant _ -> not_supported ~loc "non closed polyvariants"
    | Ptyp_arrow _ -> not_supported ~loc "function types"
    | Ptyp_open _ -> not_supported ~loc "open type expressions"
    | Ptyp_any -> not_supported ~loc "type placeholders"
    | Ptyp_object _ -> not_supported ~loc "object types"
    | Ptyp_class _ -> not_supported ~loc "class types"
    | Ptyp_poly _ -> not_supported ~loc "polymorphic type expressions"
    | Ptyp_package _ -> not_supported ~loc "packaged module types"
    | Ptyp_extension _ -> not_supported ~loc "extension nodes"
    | Ptyp_alias _ -> not_supported ~loc "type aliases"

  let repr_type_declaration td =
    let loc = td.ptype_loc in
    match (td.ptype_kind, td.ptype_manifest) with
    | Ptype_abstract, None -> not_supported ~loc "abstract types"
    | Ptype_abstract, Some t -> `Ptype_core_type t
    | Ptype_variant ctors, _ -> `Ptype_variant ctors
    | Ptype_record fs, _ -> `Ptype_record fs
    | Ptype_open, _ -> not_supported ~loc "open types"

  let gen_type_ascription (td : type_declaration) =
    let loc = td.ptype_loc in
    ptyp_constr ~loc
      { loc; txt = lident td.ptype_name.txt }
      (List.map td.ptype_params ~f:(fun (p, _) ->
           match p.ptyp_desc with
           | Ptyp_var name -> ptyp_var ~loc name
           | Ptyp_any -> ptyp_any ~loc
           | _ -> Location.raise_errorf ~loc "this cannot be a type parameter"))

  let derive_sig_type_decl ~derive_t ~derive_label ~ctxt (_rec_flag, tds) =
    let loc = Expansion_context.Deriver.derived_item_loc ctxt in
    List.map tds ~f:(fun td ->
        let name = td.ptype_name in
        let type_ = derive_t ~loc name (gen_type_ascription td) in
        let type_ =
          List.fold_left (List.rev td.ptype_params) ~init:type_ ~f:(fun acc (t, _) ->
              let loc = t.ptyp_loc in
              let name =
                match t.ptyp_desc with
                | Ptyp_var txt -> { txt; loc }
                | _ -> Location.raise_errorf ~loc "type variable is not a variable"
              in
              let t = derive_t ~loc name t in
              ptyp_arrow ~loc Nolabel t acc)
        in
        psig_value ~loc (value_description ~loc ~prim:[] ~name:(derive_label name) ~type_))

  class virtual deriving1 =
    object (self)
      inherit deriving
      method virtual t : loc:location -> label loc -> core_type -> core_type

      method derive_of_tuple : core_type -> core_type list -> expression -> expression =
        fun t _ _ ->
          let loc = t.ptyp_loc in
          not_supported "tuple types" ~loc

      method derive_of_record : type_declaration -> label_declaration list -> expression -> expression =
        fun td _ _ ->
          let loc = td.ptype_loc in
          not_supported "record types" ~loc

      method derive_of_variant : type_declaration -> constructor_declaration list -> expression -> expression =
        fun td _ _ ->
          let loc = td.ptype_loc in
          not_supported "variant types" ~loc

      method derive_of_polyvariant : core_type -> row_field list -> expression -> expression =
        fun t _ _ ->
          let loc = t.ptyp_loc in
          not_supported "polyvariant types" ~loc

      method private derive_type_ref_name : label -> longident loc -> expression = fun name n -> ederiver name n

      method private derive_type_ref' ~loc name n ts =
        let f = self#derive_type_ref_name name n in
        match n.txt with
        | Longident.Ldot (Longident.Lident "Runtime", "server_function") -> As_val f
        | _ ->
            let args =
              List.fold_left (List.rev ts) ~init:[] ~f:(fun args a ->
                  let a = as_fun ~loc (self#derive_of_core_type' a) in
                  (Nolabel, a) :: args)
            in
            As_val (pexp_apply ~loc f args)

      method derive_type_ref ~loc name n ts x = as_val ~loc (self#derive_type_ref' ~loc name n ts) x

      method private derive_of_core_type' t =
        let loc = t.ptyp_loc in
        match repr_core_type t with
        | `Ptyp_tuple ts -> As_fun (self#derive_of_tuple t ts)
        | `Ptyp_var label -> As_val (ederiver self#name (map_loc lident label))
        | `Ptyp_constr (id, ts) -> self#derive_type_ref' self#name ~loc id ts
        | `Ptyp_variant fs -> As_fun (self#derive_of_polyvariant t fs)

      method derive_of_core_type t x =
        let loc = x.pexp_loc in
        as_val ~loc (self#derive_of_core_type' t) x

      method private derive_type_decl_label name = map_loc (derive_of_label self#name) name

      method derive_of_type_declaration td =
        let loc = td.ptype_loc in
        let name = td.ptype_name in
        let rev_params =
          List.rev_map td.ptype_params ~f:(fun (t, _) ->
              match t.ptyp_desc with
              | Ptyp_var txt -> { txt; loc = t.ptyp_loc }
              | Ptyp_any -> { txt = gen_symbol ~prefix:"_" (); loc = t.ptyp_loc }
              | _ -> Location.raise_errorf ~loc "type variable is not a variable")
        in
        let x = [%expr x] in
        let expr =
          match repr_type_declaration td with
          | `Ptype_core_type t -> self#derive_of_core_type t x
          | `Ptype_variant ctors -> self#derive_of_variant td ctors x
          | `Ptype_record fs -> self#derive_of_record td fs x
        in
        let expr = [%expr (fun x -> [%e expr] : [%t self#t ~loc name (gen_type_ascription td)])] in
        let expr =
          List.fold_left rev_params ~init:expr ~f:(fun body param ->
              pexp_fun ~loc Nolabel None (ppat_var ~loc (map_loc (derive_of_label self#name) param)) body)
        in
        [ value_binding ~loc ~pat:(ppat_var ~loc (self#derive_type_decl_label name)) ~expr ]

      method extension : loc:location -> path:label -> core_type -> expression =
        fun ~loc:_ ~path:_ ty ->
          let loc = ty.ptyp_loc in
          as_fun ~loc (self#derive_of_core_type' ty)

      method str_type_decl : ctxt:Expansion_context.Deriver.t -> rec_flag * type_declaration list -> structure =
        fun ~ctxt (_rec_flag, tds) ->
          let loc = Expansion_context.Deriver.derived_item_loc ctxt in
          let bindings = List.concat_map tds ~f:self#derive_of_type_declaration in
          [%str
            [@@@ocaml.warning "-39-11-27"]

            [%%i pstr_value ~loc Recursive bindings]]

      method sig_type_decl : ctxt:Expansion_context.Deriver.t -> rec_flag * type_declaration list -> signature =
        derive_sig_type_decl ~derive_t:self#t ~derive_label:self#derive_type_decl_label
    end
end

let rec get_variant_names ~loc c =
  match Schema.repr_row_field c with
  | `Rtag (name, ts) ->
      [ Printf.sprintf {|["%s"%s]|} name.txt (ts |> List.map ~f:(fun _ -> ", _") |> String.concat ~sep:"") ]
  | `Rinherit (n, ts) -> (
      match Schema.repr_core_type (ptyp_constr ~loc:n.loc n ts) with
      | `Ptyp_variant fields -> List.concat_map fields ~f:(get_variant_names ~loc)
      | _ -> [])

let get_constructor_names cs =
  List.map cs ~f:(fun c ->
      let name = c.pcd_name in
      match c.pcd_args with
      | Pcstr_record _fs -> Printf.sprintf {|["%s", { _ }]|} name.txt
      | Pcstr_tuple li ->
          Printf.sprintf {|["%s"%s]|} name.txt (li |> List.map ~f:(fun _ -> ", _") |> String.concat ~sep:""))

module Conv = struct
  type 'ctx tuple = { tpl_loc : location; tpl_types : core_type list; tpl_ctx : 'ctx }
  type 'ctx record = { rcd_loc : location; rcd_fields : label_declaration list; rcd_ctx : 'ctx }

  type variant_case =
    | Vcs_tuple of label loc * variant_case_ctx tuple
    | Vcs_record of label loc * variant_case_ctx record

  and variant_case_ctx = Vcs_ctx_variant of constructor_declaration | Vcs_ctx_polyvariant of row_field

  type variant = { vrt_loc : location; vrt_cases : variant_case list; vrt_ctx : variant_ctx }
  and variant_ctx = Vrt_ctx_variant of type_declaration | Vrt_ctx_polyvariant of core_type

  let repr_polyvariant_cases cs = List.rev cs |> List.map ~f:(fun c -> (c, Schema.repr_row_field c))
  let repr_variant_cases cs = List.rev cs

  let deriving_of ~name ~of_t ~is_allow_any_constr ~derive_of_tuple ~derive_of_record ~derive_of_variant
      ~derive_of_variant_case () =
    (object (self)
       inherit Schema.deriving1
       method name = name
       method t ~loc _name t = [%type: [%t of_t ~loc] -> [%t t]]

       method! derive_of_tuple t ts x =
         let t = { tpl_loc = t.ptyp_loc; tpl_types = ts; tpl_ctx = t } in
         derive_of_tuple self#derive_of_core_type t x

       method! derive_of_record td fs x =
         let t = { rcd_loc = td.ptype_loc; rcd_fields = fs; rcd_ctx = td } in
         derive_of_record self#derive_of_core_type t x

       method! derive_of_variant td cs x =
         let loc = td.ptype_loc in
         let cs = repr_variant_cases cs in
         let allow_any_constr =
           cs
           |> List.find_opt ~f:(fun cs -> is_allow_any_constr (Vcs_ctx_variant cs))
           |> Option.map (fun cs e -> econstruct cs (Some e))
         in
         let cs = List.filter ~f:(fun cs -> not (is_allow_any_constr (Vcs_ctx_variant cs))) cs in
         let body, cases =
           List.fold_left cs
             ~init:
               (match allow_any_constr with
               | Some allow_any_constr -> (allow_any_constr x, [])
               | None ->
                   let error_message =
                     Printf.sprintf "expected %s" (get_constructor_names cs |> String.concat ~sep:" or ")
                   in
                   ([%expr RSC.of_rsc_error ~rsc:[%e x] [%e estring ~loc error_message]], []))
             ~f:(fun (next, cases) c ->
               let make (n : label loc) arg = pexp_construct (map_loc lident n) ~loc:n.loc arg in
               let ctx = Vcs_ctx_variant c in
               let n = c.pcd_name in
               match c.pcd_args with
               | Pcstr_record fs ->
                   let t =
                     let t = { rcd_loc = loc; rcd_fields = fs; rcd_ctx = ctx } in
                     Vcs_record (n, t)
                   in
                   let next = derive_of_variant_case self#derive_of_core_type (make n) t ~allow_any_constr next in
                   (next, t :: cases)
               | Pcstr_tuple ts ->
                   let case =
                     let t = { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx } in
                     Vcs_tuple (n, t)
                   in
                   let next = derive_of_variant_case self#derive_of_core_type (make n) case ~allow_any_constr next in
                   (next, case :: cases))
         in
         let t = { vrt_loc = loc; vrt_cases = cases; vrt_ctx = Vrt_ctx_variant td } in
         derive_of_variant self#derive_of_core_type t ~allow_any_constr body x

       method! derive_of_polyvariant t (cs : row_field list) x =
         let loc = t.ptyp_loc in
         let allow_any_constr =
           cs
           |> List.find_opt ~f:(fun cs -> is_allow_any_constr (Vcs_ctx_polyvariant cs))
           |> Option.map (fun cs ->
               match cs.prf_desc with
               | Rinherit _ -> failwith "[@allow_any] placed on inherit clause"
               | Rtag (n, _, _) -> fun e -> pexp_variant ~loc:n.loc n.txt (Some e))
         in
         let cs = List.filter ~f:(fun cs -> not (is_allow_any_constr (Vcs_ctx_polyvariant cs))) cs in
         let cases = repr_polyvariant_cases cs in
         let body, cases =
           List.fold_left cases
             ~init:
               (match allow_any_constr with
               | Some allow_any_constr -> (allow_any_constr x, [])
               | None ->
                   let error_message =
                     Printf.sprintf "expected %s"
                       (cs |> List.concat_map ~f:(get_variant_names ~loc) |> String.concat ~sep:" or ")
                   in
                   ([%expr RSC.of_rsc_unexpected_variant ~rsc:x [%e estring ~loc error_message]], []))
             ~f:(fun (next, cases) (c, r) ->
               let ctx = Vcs_ctx_polyvariant c in
               match r with
               | `Rtag (n, ts) ->
                   let make arg = pexp_variant ~loc:n.loc n.txt arg in
                   let case =
                     let t = { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx } in
                     Vcs_tuple (n, t)
                   in
                   let next = derive_of_variant_case self#derive_of_core_type make case ~allow_any_constr next in
                   (next, case :: cases)
               | `Rinherit (n, ts) ->
                   let maybe_e = self#derive_type_ref ~loc self#name n ts x in
                   let t = ptyp_variant ~loc cs Closed None in
                   let next =
                     [%expr
                       match [%e maybe_e] with
                       | e -> (e :> [%t t])
                       | exception RSC.Of_rsc_error (RSC.Unexpected_variant _) -> [%e next]]
                   in
                   (next, cases))
         in
         let t = { vrt_loc = loc; vrt_cases = cases; vrt_ctx = Vrt_ctx_polyvariant t } in
         derive_of_variant self#derive_of_core_type t ~allow_any_constr body x
     end
      :> deriving)

  let deriving_of_match ~name ~of_t ~cmp_sort_vcs ~derive_of_tuple ~derive_of_record ~derive_of_variant_case () =
    (object (self)
       inherit Schema.deriving1
       method name = name
       method t ~loc _name t = [%type: [%t of_t ~loc] -> [%t t]]

       method! derive_of_tuple t ts x =
         let t = { tpl_loc = t.ptyp_loc; tpl_types = ts; tpl_ctx = t } in
         derive_of_tuple self#derive_of_core_type t x

       method! derive_of_record td fs x =
         let t = { rcd_loc = td.ptype_loc; rcd_fields = fs; rcd_ctx = td } in
         derive_of_record self#derive_of_core_type t x

       method! derive_of_variant td cs x =
         let loc = td.ptype_loc in
         let error_message = Printf.sprintf "expected %s" (get_constructor_names cs |> String.concat ~sep:" or ") in
         let cs = repr_variant_cases cs in
         let cs =
           List.stable_sort
             ~cmp:(fun cs1 cs2 ->
               let vcs1 = Vcs_ctx_variant cs1 and vcs2 = Vcs_ctx_variant cs2 in
               cmp_sort_vcs vcs1 vcs2)
             cs
         in
         let cases =
           List.fold_left cs
             ~init:[ [%pat? _] --> [%expr RSC.of_rsc_error ~rsc:x [%e estring ~loc error_message]] ]
             ~f:(fun next (c : constructor_declaration) ->
               let ctx = Vcs_ctx_variant c in
               let make (n : label loc) arg = pexp_construct (map_loc lident n) ~loc:n.loc arg in
               let n = c.pcd_name in
               match c.pcd_args with
               | Pcstr_record fs ->
                   let t =
                     let r = { rcd_loc = loc; rcd_fields = fs; rcd_ctx = ctx } in
                     Vcs_record (n, r)
                   in
                   derive_of_variant_case self#derive_of_core_type (make n) t :: next
               | Pcstr_tuple ts ->
                   let t =
                     let t = { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx } in
                     Vcs_tuple (n, t)
                   in
                   derive_of_variant_case self#derive_of_core_type (make n) t :: next)
         in
         pexp_match ~loc x cases

       method! derive_of_polyvariant t (cs : row_field list) x =
         let loc = t.ptyp_loc in
         let cases = repr_polyvariant_cases cs in
         let cases =
           List.stable_sort
             ~cmp:(fun (cs1, _) (cs2, _) ->
               let vcs1 = Vcs_ctx_polyvariant cs1 and vcs2 = Vcs_ctx_polyvariant cs2 in
               cmp_sort_vcs vcs1 vcs2)
             cases
         in
         let ctors, inherits =
           List.partition_map cases ~f:(fun (c, r) ->
               let ctx = Vcs_ctx_polyvariant c in
               match r with
               | `Rtag (n, ts) ->
                   let t = { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx } in
                   Left (n, Vcs_tuple (n, t))
               | `Rinherit (n, ts) -> Right (n, ts))
         in
         let catch_all =
           [%pat? x]
           --> List.fold_left (List.rev inherits)
                 ~init:
                   (let error_message =
                      Printf.sprintf "expected %s"
                        (cs |> List.concat_map ~f:(get_variant_names ~loc) |> String.concat ~sep:" or ")
                    in
                    [%expr RSC.of_rsc_unexpected_variant ~rsc:x [%e estring ~loc error_message]])
                 ~f:(fun next (n, ts) ->
                   let maybe = self#derive_type_ref ~loc self#name n ts x in
                   let t = ptyp_variant ~loc cs Closed None in
                   [%expr
                     match [%e maybe] with
                     | x -> (x :> [%t t])
                     | exception RSC.Of_rsc_error (RSC.Unexpected_variant _) -> [%e next]])
         in
         let cases =
           List.fold_left ctors ~init:[ catch_all ] ~f:(fun next ((n : label loc), t) ->
               let make arg = pexp_variant ~loc:n.loc n.txt arg in
               derive_of_variant_case self#derive_of_core_type make t :: next)
         in
         pexp_match ~loc x cases
     end
      :> deriving)

  let deriving_to ~name ~t_to ~derive_of_tuple ~derive_of_record ~derive_of_variant_case () =
    (object (self)
       inherit Schema.deriving1
       method name = name
       method t ~loc _name t = [%type: [%t t] -> [%t t_to ~loc]]

       method! derive_of_tuple t ts x =
         let loc = t.ptyp_loc in
         let t = { tpl_loc = loc; tpl_types = ts; tpl_ctx = t } in
         let n = List.length ts in
         let p, es = gen_pat_tuple ~loc "x" n in
         pexp_match ~loc x [ p --> derive_of_tuple self#derive_of_core_type t es ]

       method! derive_of_record td fs x =
         let t = { rcd_loc = td.ptype_loc; rcd_fields = fs; rcd_ctx = td } in
         let loc = td.ptype_loc in
         let p, es = gen_pat_record ~loc "x" (List.map fs ~f:(fun f -> f.pld_name)) in
         pexp_match ~loc x [ p --> derive_of_record self#derive_of_core_type t es ]

       method! derive_of_variant td cs x =
         let loc = td.ptype_loc in
         let ctor_pat (n : label loc) pat = ppat_construct ~loc:n.loc (map_loc lident n) pat in
         let cs = repr_variant_cases cs in
         pexp_match ~loc x
           (List.rev_map cs ~f:(fun c ->
                let n = c.pcd_name in
                let ctx = Vcs_ctx_variant c in
                match c.pcd_args with
                | Pcstr_record fs ->
                    let p, es = gen_pat_record ~loc "x" (List.map fs ~f:(fun f -> f.pld_name)) in
                    let t =
                      let t = { rcd_loc = loc; rcd_fields = fs; rcd_ctx = ctx } in
                      Vcs_record (n, t)
                    in
                    ctor_pat n (Some p) --> derive_of_variant_case self#derive_of_core_type t es
                | Pcstr_tuple ts ->
                    let arity = List.length ts in
                    let t =
                      let t = { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx } in
                      Vcs_tuple (n, t)
                    in
                    let p, es = gen_pat_tuple ~loc "x" arity in
                    ctor_pat n (if arity = 0 then None else Some p)
                    --> derive_of_variant_case self#derive_of_core_type t es))

       method! derive_of_polyvariant t (cs : row_field list) x =
         let loc = t.ptyp_loc in
         let cases = repr_polyvariant_cases cs in
         let cases =
           List.rev_map cases ~f:(fun (c, r) ->
               let ctx = Vcs_ctx_polyvariant c in
               match r with
               | `Rtag (n, []) ->
                   let t =
                     let t = { tpl_loc = loc; tpl_types = []; tpl_ctx = ctx } in
                     Vcs_tuple (n, t)
                   in
                   ppat_variant ~loc n.txt None --> derive_of_variant_case self#derive_of_core_type t []
               | `Rtag (n, ts) ->
                   let t = { tpl_loc = loc; tpl_types = ts; tpl_ctx = ctx } in
                   let ps, es = gen_pat_tuple ~loc "x" (List.length ts) in
                   ppat_variant ~loc n.txt (Some ps)
                   --> derive_of_variant_case self#derive_of_core_type (Vcs_tuple (n, t)) es
               | `Rinherit (n, ts) ->
                   [%pat? [%p ppat_type ~loc n] as x]
                   --> self#derive_of_core_type (ptyp_constr ~loc:n.loc n ts) [%expr x])
         in
         pexp_match ~loc x cases
     end
      :> deriving)
end

include Schema
