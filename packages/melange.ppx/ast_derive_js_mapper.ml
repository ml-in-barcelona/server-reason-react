(* Based on melange version:
   https://github.com/melange-re/melange/blob/482112aa4988634bf4102955c47fbe8f0538b4f3/ppx/ast_derive/ast_derive_js_mapper.ml
*)

open Ppxlib
open Ast_helper
module String = Melstd.String

module Mel_ast_invariant = struct
  let is_mel_attribute txt =
    let len = String.length txt in
    (len = 1 && String.unsafe_get txt 0 = 'u')
    || len >= 5
       && String.unsafe_get txt 0 = 'm'
       && String.unsafe_get txt 1 = 'e'
       && String.unsafe_get txt 2 = 'l'
       && String.unsafe_get txt 3 = '.'
end

module Ast_payload = struct
  let is_single_string (x : payload) =
    match x with
    (* TODO also need detect empty phrase case *)
    | PStr
        [
          {
            pstr_desc =
              Pstr_eval
                ( { pexp_desc = Pexp_constant (Pconst_string (name, _, dec)); _ },
                  _ );
            _;
          };
        ] ->
        Some (name, dec)
    | _ -> None
end

module Ast_attributes = struct
  let mel_get_index =
    {
      attr_name = { txt = "mel.get_index"; loc = Location.none };
      attr_payload = PStr [];
      attr_loc = Location.none;
    }

  let error_if_bs_or_non_namespaced ~loc txt =
    match txt with
    | "bs" ->
        Location.raise_errorf ~loc
          "The `[@bs]' attribute has been removed in favor of `[@u]'."
    | other ->
        if
          String.starts_with ~prefix:"bs." other
          || not (Mel_ast_invariant.is_mel_attribute txt)
        then
          Location.raise_errorf ~loc
            "`[@bs.*]' and non-namespaced attributes have been removed in \
             favor of `[@mel.*]' attributes."

  let iter_process_mel_string_as attrs : string option =
    let st = ref None in
    List.iter
      (fun { attr_name = { txt; loc }; attr_payload = payload; _ } ->
        match txt with
        | "mel.as" | "bs.as" | "as" ->
            error_if_bs_or_non_namespaced ~loc txt;
            if !st = None then
              match Ast_payload.is_single_string payload with
              | None -> Location.raise_errorf ~loc "Expected a string literal"
              | Some (v, _dec) ->
                  (* We let the Melange ppx do this job
                     Mel_ast_invariant.mark_used_mel_attribute attr; *)
                  st := Some v
            else Location.raise_errorf ~loc "Duplicate `@mel.as'"
        | _ -> ())
      attrs;
    !st
end

module Melange_ffi = struct
  module External_ffi_prims = struct
    type module_bind_name =
      | Phint_name of string
      (* explicit hint name *)
      | Phint_nothing

    type external_module_name = {
      bundle : string;
      module_bind_name : module_bind_name;
    }

    type arg_type = External_arg_spec.attr
    type arg_label = External_arg_spec.label

    type external_spec =
      | Js_var of {
          name : string;
          external_module_name : external_module_name option;
          scopes : string list;
        }
      | Js_module_as_var of external_module_name
      | Js_module_as_fn of {
          external_module_name : external_module_name;
          variadic : bool;
        }
      | Js_module_as_class of external_module_name
      | Js_call of {
          name : string;
          external_module_name : external_module_name option;
          variadic : bool;
          scopes : string list;
        }
      | Js_send of {
          name : string;
          variadic : bool;
          pipe : bool;
          new_ : bool;
          js_send_scopes : string list;
        }
        (* we know it is a js send, but what will happen if you pass an ocaml objct *)
      | Js_new of {
          name : string;
          external_module_name : external_module_name option;
          variadic : bool;
          scopes : string list;
        }
      | Js_set of { js_set_name : string; js_set_scopes : string list }
      | Js_get of { js_get_name : string; js_get_scopes : string list }
      | Js_get_index of { js_get_index_scopes : string list }
      | Js_set_index of { js_set_index_scopes : string list }

    type return_wrapper =
      | Return_unset
      | Return_identity
      | Return_undefined_to_opt
      | Return_null_to_opt
      | Return_null_undefined_to_opt
      | Return_replaced_with_unit

    type params = Params of External_arg_spec.params | Param_number of int

    type t = private
      | Ffi_mel of params * return_wrapper * external_spec
      | Ffi_obj_create of External_arg_spec.obj_params
      | Ffi_inline_const of Lam_constant.t
      | Ffi_normal

    let to_string (t : t) = Marshal.to_string t []

    let ffi_obj_as_prims obj_params =
      [ ""; to_string (Ffi_obj_create obj_params) ]
  end

  module External_arg_spec : sig
    type cst = private
      | Arg_int_lit of int
      | Arg_string_lit of string
      | Arg_js_literal of string

    type label = private
      | Obj_label of { name : string }
      | Obj_empty
      | Obj_optional of { name : string; for_sure_no_nested_option : bool }
          (** it will be ignored , side effect will be recorded *)

    type attr =
      | Poly_var_string of { descr : (string * string) list }
      | Poly_var of { descr : (string * string) list option }
      | Int of (string * int) list (* ([`a | `b ] [@mel.int])*)
      | Arg_cst of cst
      | Fn_uncurry_arity of int
          (** annotated with [@mel.uncurry ] or [@mel.uncurry 2]*)
      (* maybe we can improve it as a combination of {!Asttypes.constant} and tuple *)
      | Extern_unit
      | Nothing
      | Ignore
      | Unwrap

    type label_noname = Arg_label | Arg_empty | Arg_optional
    type obj_param = { obj_arg_type : attr; obj_arg_label : label }
    type param = { arg_type : attr; arg_label : label_noname }
    type obj_params = obj_param list
    type params = param list

    val cst_obj_literal : string -> cst
    val cst_int : int -> cst
    val cst_string : string -> cst
    val empty_label : label

    (* val empty_lit : cst -> label  *)
    val obj_label : string -> label
    val optional : bool -> string -> label
    val empty_kind : attr -> obj_param
    val dummy : param
  end = struct
    (** type definitions for external argument *)

    type cst =
      | Arg_int_lit of int
      | Arg_string_lit of string
      | Arg_js_literal of string

    type label_noname = Arg_label | Arg_empty | Arg_optional

    type label =
      | Obj_label of { name : string }
      | Obj_empty
      | Obj_optional of { name : string; for_sure_no_nested_option : bool }

    (* it will be ignored , side effect will be recorded *)

    (* This type is used to give some meta info on each argument *)
    type attr =
      | Poly_var_string of {
          descr : (string * string) list;
              (* introduced by attributes @string
                 and @as
              *)
        }
      | Poly_var of {
          descr : (string * string) list option;
              (* introduced by attributes @string
                 and @as
              *)
        }
      (* `a does not have any value*)
      | Int of (string * int) list (* ([`a | `b ] [@int])*)
      | Arg_cst of cst (* Constant argument *)
      | Fn_uncurry_arity of int (* annotated with [@uncurry ] or [@uncurry 2]*)
      (* maybe we can improve it as a combination of {!Asttypes.constant} and tuple *)
      | Extern_unit
      | Nothing
      | Ignore
      | Unwrap

    type param = { arg_type : attr; arg_label : label_noname }
    type obj_param = { obj_arg_type : attr; obj_arg_label : label }
    type obj_params = obj_param list
    type params = param list

    let cst_obj_literal s = Arg_js_literal s
    let cst_int i = Arg_int_lit i
    let cst_string s = Arg_string_lit s
    let empty_label = Obj_empty
    let obj_label name = Obj_label { name }

    let optional for_sure_no_nested_option name =
      Obj_optional { name; for_sure_no_nested_option }

    let empty_kind obj_arg_type = { obj_arg_label = empty_label; obj_arg_type }
    let dummy = { arg_type = Nothing; arg_label = Arg_empty }
  end

  module Lam_methname = struct
    (* Copied from [ocaml/parsing/lexer.mll] *)
    let key_words =
      String.Hash_set.of_array
        [|
          "and";
          "as";
          "assert";
          "begin";
          "class";
          "constraint";
          "do";
          "done";
          "downto";
          "else";
          "end";
          "exception";
          "external";
          "false";
          "for";
          "fun";
          "function";
          "functor";
          "if";
          "in";
          "include";
          "inherit";
          "initializer";
          "lazy";
          "let";
          "match";
          "method";
          "module";
          "mutable";
          "new";
          "nonrec";
          "object";
          "of";
          "open";
          "or";
          (*  "parser", PARSER; *)
          "private";
          "rec";
          "sig";
          "struct";
          "then";
          "to";
          "true";
          "try";
          "type";
          "val";
          "virtual";
          "when";
          "while";
          "with";
          "mod";
          "land";
          "lor";
          "lxor";
          "lsl";
          "lsr";
          "asr";
        |]

    let double_underscore = "__"

    (*https://caml.inria.fr/pub/docs/manual-ocaml/lex.html
      {[

        label-name	::=	 lowercase-ident
      ]}
    *)
    let valid_start_char x =
      match x with '_' | 'a' .. 'z' -> true | _ -> false

    let translate name =
      assert (String.length name > 0);
      let i = String.rfind ~sub:double_underscore name in
      if i < 0 then
        let name_len = String.length name in
        if name.[0] = '_' then
          let try_key_word = String.sub name ~pos:1 ~len:(name_len - 1) in
          if
            name_len > 1
            && ((not (valid_start_char try_key_word.[0]))
               || String.Hash_set.mem key_words try_key_word)
          then try_key_word
          else name
        else name
      else if i = 0 then name
      else String.sub name ~pos:0 ~len:i
  end
end

module Ast_external_mk = struct
  let local_external_obj loc ?(pval_attributes = []) ~pval_prim ~pval_type
      ?(local_module_name = "J") ?(local_fun_name = "unsafe_expr") args :
      expression_desc =
    Pexp_letmodule
      ( { txt = Some local_module_name; loc },
        {
          pmod_desc =
            Pmod_structure
              [
                {
                  pstr_desc =
                    Pstr_primitive
                      {
                        pval_name = { txt = local_fun_name; loc };
                        pval_type;
                        pval_loc = loc;
                        pval_prim;
                        pval_attributes;
                      };
                  pstr_loc = loc;
                };
              ];
          pmod_loc = loc;
          pmod_attributes = [];
        },
        Exp.apply
          ({
             pexp_desc =
               Pexp_ident
                 { txt = Ldot (Lident local_module_name, local_fun_name); loc };
             pexp_attributes = [];
             pexp_loc = loc;
             pexp_loc_stack = [ loc ];
           }
            : expression)
          (List.map (fun (l, a) -> (Asttypes.Labelled l, a)) args)
          ~loc )

  let pval_prim_of_labels (labels : string Asttypes.loc list) =
    let arg_kinds =
      List.fold_right
        (fun p arg_kinds ->
          let obj_arg_label =
            Melange_ffi.External_arg_spec.obj_label
              (Melange_ffi.Lam_methname.translate p.txt)
          in
          {
            Melange_ffi.External_arg_spec.obj_arg_type = Nothing;
            obj_arg_label;
          }
          :: arg_kinds)
        labels []
    in
    Melange_ffi.External_ffi_types.ffi_obj_as_prims arg_kinds

  let record_as_js_object ~loc
      (label_exprs : (Longident.t Asttypes.loc * expression) list) :
      expression_desc =
    let labels, args, arity =
      List.fold_right
        (fun ({ txt; loc }, e) (labels, args, i) ->
          match txt with
          | Lident obj_label ->
              let obj_label =
                Ast_attributes.iter_process_mel_string_as e.pexp_attributes
                |> Option.value ~default:obj_label
              in
              ( { Asttypes.loc; txt = obj_label } :: labels,
                (obj_label, e) :: args,
                i + 1 )
          | Ldot _ | Lapply _ ->
              Location.raise_errorf ~loc
                "`%%mel.obj' literals only support simple labels")
        label_exprs ([], [], 0)
    in
    local_external_obj loc
      ~pval_prim:(pval_prim_of_labels labels)
      ~pval_type:(from_labels ~loc arity labels)
      args
end

module U = struct
  let core_type_of_type_declaration (tdcl : type_declaration) =
    match tdcl with
    | { ptype_name = { txt; loc }; ptype_params; _ } ->
        Typ.constr { txt = Lident txt; loc } (List.map fst ptype_params)

  let new_type_of_type_declaration (tdcl : type_declaration) newName =
    match tdcl with
    | { ptype_name = { loc; _ }; ptype_params; _ } ->
        ( Typ.constr { txt = Lident newName; loc } (List.map fst ptype_params),
          {
            ptype_params = tdcl.ptype_params;
            ptype_name = { txt = newName; loc };
            ptype_kind = Ptype_abstract;
            ptype_attributes = [];
            ptype_loc = tdcl.ptype_loc;
            ptype_cstrs = [];
            ptype_private = Public;
            ptype_manifest = None;
          } )

  let notApplicable derivingName =
    derivingName ^ " is not applicable to this type"
end

let js_field o m =
  let loc = o.pexp_loc in
  [%expr
    [%e Exp.ident { txt = Lident "##"; loc = o.pexp_loc }]
      [%e o] [%e Exp.ident m]]

let noloc = Location.none

(* [eraseType] will be instrumented, be careful about the name conflict*)
let eraseTypeLit = "_eraseType"
let eraseTypeExp = Exp.ident { loc = noloc; txt = Lident eraseTypeLit }

let eraseType x =
  let loc = noloc in
  [%expr [%e eraseTypeExp] [%e x]]

let eraseTypeStr =
  let loc = noloc in
  Str.primitive
    (Val.mk ~prim:[ "%identity" ]
       { loc = noloc; txt = eraseTypeLit }
       [%type: _ -> _])

let unsafeIndex = "_index"

let unsafeIndexGet =
  let loc = noloc in
  Str.primitive
    (Val.mk ~prim:[ "" ]
       { loc = noloc; txt = unsafeIndex }
       ~attrs:[ Ast_attributes.mel_get_index ]
       [%type: _ -> _ -> _])

let unsafeIndexGetExp = Exp.ident { loc = noloc; txt = Lident unsafeIndex }

(* JavaScript has allowed trailing commas in array literals since the beginning,
   and later added them to object literals (ECMAScript 5) and most recently (ECMAScript 2017)
   to function parameters. *)
let add_key_value buf key value last =
  Buffer.add_char buf '"';
  Buffer.add_string buf key;
  Buffer.add_string buf "\":\"";
  Buffer.add_string buf value;
  if last then Buffer.add_string buf "\"" else Buffer.add_string buf "\","

let buildMap (row_fields : row_field list) =
  let has_mel_as = ref false in
  let data, revData =
    let buf = Buffer.create 50 in
    let revBuf = Buffer.create 50 in
    Buffer.add_string buf "{";
    Buffer.add_string revBuf "{";
    let rec aux (row_fields : row_field list) =
      match row_fields with
      | [] -> ()
      | tag :: rest ->
          (match tag.prf_desc with
          | Rtag ({ txt; _ }, _, []) ->
              let name : string =
                match
                  Ast_attributes.iter_process_mel_string_as tag.prf_attributes
                with
                | Some name ->
                    has_mel_as := true;
                    name
                | None -> txt
              in
              let last = rest = [] in
              add_key_value buf txt name last;
              add_key_value revBuf name txt last
          | _ -> assert false (* checked by [is_enum_polyvar] *));
          aux rest
    in
    aux row_fields;
    Buffer.add_string buf "}";
    Buffer.add_string revBuf "}";
    (Buffer.contents buf, Buffer.contents revBuf)
  in
  (data, revData, !has_mel_as)

let ( <=~ ) a b =
  let loc = noloc in
  [%expr [%e a] <= [%e b]]

let ( -~ ) a b =
  let loc = noloc in
  [%expr Stdlib.( - ) [%e a] [%e b]]

let ( +~ ) a b =
  let loc = noloc in
  [%expr Stdlib.( + ) [%e a] [%e b]]

let ( &&~ ) a b =
  let loc = noloc in
  [%expr Stdlib.( && ) [%e a] [%e b]]

let ( ->~ ) a b =
  let loc = noloc in
  [%type: [%t a] -> [%t b]]

let jsMapperRt = Longident.Lident "Js__Js_mapper_runtime"

let fromInt len array exp =
  let loc = noloc in
  [%expr
    [%e Exp.ident { loc = noloc; txt = Longident.Ldot (jsMapperRt, "fromInt") }]
      [%e len] [%e array] [%e exp]]

let fromIntAssert len array exp =
  let loc = noloc in
  [%expr
    [%e
      Exp.ident
        { loc = noloc; txt = Longident.Ldot (jsMapperRt, "fromIntAssert") }]
      [%e len] [%e array] [%e exp]]

let raiseWhenNotFound x =
  let loc = noloc in
  [%expr
    [%e
      Exp.ident
        { loc = noloc; txt = Longident.Ldot (jsMapperRt, "raiseWhenNotFound") }]
      [%e x]]

let derivingName = "jsConverter"
let assertExp e = Exp.assert_ e

let single_non_rec_value name exp =
  Str.value Nonrecursive [ Vb.mk (Pat.var name) exp ]

let derive_structure =
  let handle_tdcl ~createType (tdcl : type_declaration) =
    let core_type = U.core_type_of_type_declaration tdcl in
    let name = tdcl.ptype_name.txt in
    let toJs = name ^ "ToJs" in
    let fromJs = name ^ "FromJs" in
    let constantArray = "jsMapperConstantArray" in
    let loc = tdcl.ptype_loc in
    let patToJs = { Asttypes.loc; txt = toJs } in
    let patFromJs = { Asttypes.loc; txt = fromJs } in
    let param = "param" in

    let ident_param = { Asttypes.txt = Longident.Lident param; loc } in
    let pat_param = { Asttypes.loc; txt = param } in
    let exp_param = Exp.ident ident_param in
    let newType, newTdcl =
      U.new_type_of_type_declaration tdcl ("abs_" ^ name)
    in
    let newTypeStr =
      (* Abstract type *)
      { pstr_loc = loc; pstr_desc = Pstr_type (Nonrecursive, [ newTdcl ]) }
    in
    let toJsBody body =
      Str.value Nonrecursive
        [
          Vb.mk (Pat.var patToJs)
            (Exp.fun_ Nolabel None
               (Pat.constraint_ (Pat.var pat_param) core_type)
               body);
        ]
    in
    let ( +> ) a ty = Exp.constraint_ (eraseType a) ty in
    let ( +: ) a ty = eraseType (Exp.constraint_ a ty) in
    let coerceResultToNewType e = if createType then e +> newType else e in
    match tdcl.ptype_kind with
    | Ptype_record label_declarations ->
        let exp =
          coerceResultToNewType
            (Exp.mk ~loc
               (Ast_external_mk.record_as_js_object ~loc
                  (List.map
                     (fun { pld_name = { loc; txt }; _ } ->
                       let label =
                         { Asttypes.loc; txt = Longident.Lident txt }
                       in
                       (label, Exp.field exp_param label))
                     label_declarations)))
        in
        let toJs = toJsBody exp in
        let obj_exp =
          Exp.record
            (List.map
               (fun { pld_name = { loc; txt }; _ } ->
                 let label = { Asttypes.loc; txt = Longident.Lident txt } in
                 (label, js_field exp_param label))
               label_declarations)
            None
        in
        let fromJs =
          Str.value Nonrecursive
            [
              Vb.mk (Pat.var patFromJs)
                (Exp.fun_ Nolabel None (Pat.var pat_param)
                   (if createType then
                      Exp.let_ Nonrecursive
                        [ Vb.mk (Pat.var pat_param) (exp_param +: newType) ]
                        (Exp.constraint_ obj_exp core_type)
                    else Exp.constraint_ obj_exp core_type));
            ]
        in
        let rest = [ toJs; fromJs ] in
        if createType then eraseTypeStr :: newTypeStr :: rest else rest
    | Ptype_abstract -> (
        match Ast_polyvar.is_enum_polyvar tdcl with
        | Some row_fields ->
            let map, revMap = ("_map", "_revMap") in
            let expMap = Exp.ident { loc; txt = Lident map } in
            let revExpMap = Exp.ident { loc; txt = Lident revMap } in
            let data, revData, has_mel_as = buildMap row_fields in

            let v =
              [
                eraseTypeStr;
                unsafeIndexGet;
                single_non_rec_value { loc; txt = map }
                  (Ast_extensions.handle_raw ~kind:Raw_exp loc
                     (PStr [ Str.eval (Exp.constant (Const.string data)) ]));
                single_non_rec_value { loc; txt = revMap }
                  (if has_mel_as then
                     Ast_extensions.handle_raw ~kind:Raw_exp loc
                       (PStr [ Str.eval (Exp.constant (Const.string revData)) ])
                   else expMap);
                toJsBody
                  (if has_mel_as then
                     [%expr [%e unsafeIndexGetExp] [%e expMap] [%e exp_param]]
                   else [%expr [%e eraseTypeExp] [%e exp_param]]);
                single_non_rec_value patFromJs
                  (Exp.fun_ Nolabel None (Pat.var pat_param)
                     (let result =
                        [%expr
                          [%e unsafeIndexGetExp] [%e revExpMap] [%e exp_param]]
                      in
                      if createType then raiseWhenNotFound result else result));
              ]
            in
            if createType then newTypeStr :: v else v
        | None ->
            let loc = tdcl.ptype_loc in
            [
              [%stri
                [%%ocaml.error
                [%e
                  Exp.constant
                    (Pconst_string (U.notApplicable derivingName, loc, None))]]];
            ])
    | Ptype_variant ctors ->
        if Ast_polyvar.is_enum_constructors ctors then
          let xs = Ast_polyvar.map_constructor_declarations_into_ints ctors in
          match xs with
          | `New xs ->
              let constantArrayExp =
                Exp.ident { loc; txt = Lident constantArray }
              in
              let exp_len =
                Exp.constant
                  (Pconst_integer (string_of_int (List.length ctors), None))
              in
              let v =
                [
                  unsafeIndexGet;
                  eraseTypeStr;
                  single_non_rec_value
                    { loc; txt = constantArray }
                    (Ast_helper.Exp.array
                       (List.map
                          ~f:(fun x ->
                            Exp.constant
                              (Pconst_integer (string_of_int x, None)))
                          xs));
                  toJsBody
                    [%expr
                      [%e unsafeIndexGetExp] [%e constantArrayExp]
                        [%e exp_param]];
                  single_non_rec_value patFromJs
                    (Exp.fun_ Nolabel None (Pat.var pat_param)
                       (if createType then
                          fromIntAssert exp_len constantArrayExp
                            (exp_param +: newType)
                          +> core_type
                        else
                          fromInt exp_len constantArrayExp exp_param
                          +> Ast_core_type.lift_option_type core_type));
                ]
              in
              if createType then newTypeStr :: v else v
          | `Offset offset ->
              let v =
                [
                  eraseTypeStr;
                  toJsBody
                    (coerceResultToNewType
                       (eraseType exp_param
                       +~ Exp.constant
                            (Pconst_integer (string_of_int offset, None))));
                  (let len = List.length ctors in
                   let range_low =
                     Exp.constant
                       (Pconst_integer (string_of_int (offset + 0), None))
                   in
                   let range_upper =
                     Exp.constant
                       (Pconst_integer (string_of_int (offset + len - 1), None))
                   in

                   single_non_rec_value { loc; txt = fromJs }
                     (Exp.fun_ Nolabel None (Pat.var pat_param)
                        (if createType then
                           Exp.let_ Nonrecursive
                             [
                               Vb.mk (Pat.var pat_param) (exp_param +: newType);
                             ]
                             (Exp.sequence
                                (assertExp
                                   (exp_param <=~ range_upper
                                  &&~ (range_low <=~ exp_param)))
                                (exp_param
                                -~ Exp.constant
                                     (Pconst_integer (string_of_int offset, None))
                                ))
                           +> core_type
                         else
                           Exp.ifthenelse
                             (exp_param <=~ range_upper
                            &&~ (range_low <=~ exp_param))
                             (Exp.construct
                                { loc; txt = Ast_literal.predef_some }
                                (Some
                                   (exp_param
                                   -~ Exp.constant
                                        (Pconst_integer
                                           (string_of_int offset, None)))))
                             (Some
                                (Exp.construct
                                   { loc; txt = Ast_literal.predef_none }
                                   None))
                           +> Ast_core_type.lift_option_type core_type)));
                ]
              in
              if createType then newTypeStr :: v else v
        else
          let loc = tdcl.ptype_loc in
          [
            [%stri
              [%%ocaml.error
              [%e
                Exp.constant
                  (Pconst_string (U.notApplicable derivingName, loc, None))]]];
          ]
    | Ptype_open ->
        let loc = tdcl.ptype_loc in
        [
          [%stri
            [%%ocaml.error
            [%e
              Exp.constant
                (Pconst_string (U.notApplicable derivingName, loc, None))]]];
        ]
  in
  fun ~newType:createType (tdcls : type_declaration list) ->
    List.concat_map ~f:(handle_tdcl ~createType) tdcls

let derive_signature =
  let handle_tdcl ~createType tdcl =
    let core_type = U.core_type_of_type_declaration tdcl in
    let name = tdcl.ptype_name.txt in
    let toJs = name ^ "ToJs" in
    let fromJs = name ^ "FromJs" in
    let loc = tdcl.ptype_loc in
    let patToJs = { Asttypes.loc; txt = toJs } in
    let patFromJs = { Asttypes.loc; txt = fromJs } in
    let toJsType result =
      Sig.value (Val.mk patToJs [%type: [%t core_type] -> [%t result]])
    in
    let newType, newTdcl =
      U.new_type_of_type_declaration tdcl ("abs_" ^ name)
    in
    let newTypeStr = Sig.type_ Nonrecursive [ newTdcl ] in
    let ( +? ) v rest = if createType then v :: rest else rest in
    match tdcl.ptype_kind with
    | Ptype_record label_declarations ->
        let objType flag =
          Ast_core_type.to_js_type ~loc
            (Typ.object_
               (List.map
                  ~f:(fun { pld_name; pld_type; _ } -> Of.tag pld_name pld_type)
                  label_declarations)
               flag)
        in
        newTypeStr
        +? [
             toJsType (if createType then newType else objType Closed);
             Sig.value
               (Val.mk patFromJs
                  ((if createType then newType else objType Open) ->~ core_type));
           ]
    | Ptype_abstract -> (
        match Ast_polyvar.is_enum_polyvar tdcl with
        | Some _ ->
            let ty1 = if createType then newType else [%type: string] in
            let ty2 =
              if createType then core_type
              else Ast_core_type.lift_option_type core_type
            in
            newTypeStr
            +? [ toJsType ty1; Sig.value (Val.mk patFromJs (ty1 ->~ ty2)) ]
        | None ->
            let loc = tdcl.ptype_loc in
            [
              [%sigi:
                [%%ocaml.error
                [%e
                  Exp.constant
                    (Pconst_string (U.notApplicable derivingName, loc, None))]]];
            ])
    | Ptype_variant ctors ->
        if Ast_polyvar.is_enum_constructors ctors then
          let ty1 = if createType then newType else [%type: int] in
          let ty2 =
            if createType then core_type
            else Ast_core_type.lift_option_type core_type
          in
          newTypeStr
          +? [ toJsType ty1; Sig.value (Val.mk patFromJs (ty1 ->~ ty2)) ]
        else
          let loc = tdcl.ptype_loc in
          [
            [%sigi:
              [%%ocaml.error
              [%e
                Exp.constant
                  (Pconst_string (U.notApplicable derivingName, loc, None))]]];
          ]
    | Ptype_open ->
        let loc = tdcl.ptype_loc in
        [
          [%sigi:
            [%%ocaml.error
            [%e
              Exp.constant
                (Pconst_string (U.notApplicable derivingName, loc, None))]]];
        ]
  in
  fun ~newType:createType tdcls ->
    List.concat_map ~f:(handle_tdcl ~createType) tdcls
