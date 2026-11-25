open Ppxlib

(* Generated code is built with placeholder names, then [structure] and
   [signature] pick the final names. A user name (path parameter, loader
   label, search field, free name in a spliced user expression) never
   shares a string with a generated binder, and a raw module path whose head
   the generated file redefines (a route module, Navigation, ...) goes
   through an alias bound before the redefinition. *)

type kind = Public | Generated | User
type value = { kind : kind; base : string }

let public base = { kind = Public; base }
let generated base = { kind = Generated; base }
let user base = { kind = User; base }
let marker = '\000'

let encode { kind; base } =
  let tag = match kind with Public -> 'p' | Generated -> 'g' | User -> 'u' in
  String.init 2 (function 0 -> marker | _ -> tag) ^ base

let decode name =
  if String.length name < 2 || name.[0] <> marker then None
  else
    let base = String.sub name 2 (String.length name - 2) in
    match name.[1] with
    | 'p' -> Some (`Value (public base))
    | 'g' -> Some (`Value (generated base))
    | 'u' -> Some (`Value (user base))
    | 'o' -> Some (`Own base)
    | _ -> invalid_arg "router: malformed generated name"

let own_module name = String.init 2 (function 0 -> marker | _ -> 'o') ^ name
let evar ~loc value = Ast_builder.Default.pexp_ident ~loc { txt = Lident (encode value); loc }
let pvar ~loc value = Ast_builder.Default.ppat_var ~loc { txt = encode value; loc }

let is_var value expression =
  match expression.pexp_desc with Pexp_ident { txt = Lident name; _ } -> String.equal name (encode value) | _ -> false

let own ~loc module_name path =
  {
    txt = List.fold_left (fun parent name -> Longident.Ldot (parent, name)) (Lident (own_module module_name)) path;
    loc;
  }

let rec head = function Longident.Lident name -> Some name | Ldot (parent, _) -> head parent | Lapply _ -> None

let identifiers expression =
  let names = ref [] in
  (object
     inherit Ast_traverse.iter as super

     method! expression expression =
       (match expression.pexp_desc with
       | Pexp_ident { txt = Lident name; loc } -> names := (name, loc) :: !names
       | _ -> ());
       super#expression expression
  end)
    #expression
    expression;
  List.rev !names

let bound_names expression =
  let names = ref [] in
  (object
     inherit Ast_traverse.iter as super

     method! pattern pattern =
       (match pattern.ppat_desc with
       | Ppat_var { txt; _ } | Ppat_alias (_, { txt; _ }) -> names := txt :: !names
       | _ -> ());
       super#pattern pattern
  end)
    #expression
    expression;
  !names

(* Approximate: a name bound anywhere in an expression counts as bound
   everywhere in it, and names under a local open are skipped. Used only to
   report a clash with a public name; renaming avoids every identifier of a
   user expression. *)
let free_names expressions =
  let outside_opens expression =
    (object
       inherit Ast_traverse.map as super

       method! expression expression =
         match expression.pexp_desc with
         | Pexp_open (_, _) -> Ast_builder.Default.eunit ~loc:expression.pexp_loc
         | _ -> super#expression expression
    end)
      #expression
      expression
  in
  List.concat_map
    (fun expression ->
      let bound = bound_names expression in
      List.filter (fun (name, _) -> not (List.mem name bound)) (identifiers (outside_opens expression)))
    expressions

type scan = { values : (string, value) Hashtbl.t; heads : (string, unit) Hashtbl.t }

let rec scanner ~bound scan =
  let record_head identifier =
    match head identifier with
    | Some name when Option.is_none (decode name) && not (List.mem name bound) -> Hashtbl.replace scan.heads name ()
    | Some _ | None -> ()
  in
  object
    inherit Ast_traverse.iter as super

    method! longident identifier =
      match identifier with
      | Lident name -> (
          match decode name with
          | Some (`Value value) -> Hashtbl.replace scan.values name value
          | Some (`Own _) | None -> ())
      | Ldot _ | Lapply _ ->
          record_head identifier;
          super#longident identifier

    method! module_expr module_expr =
      (match module_expr.pmod_desc with Pmod_ident { txt; _ } -> record_head txt | _ -> ());
      super#module_expr module_expr

    method! expression expression =
      match expression.pexp_desc with
      | Pexp_letmodule ({ txt = Some name; _ }, module_expr, body) ->
          (scanner ~bound scan)#module_expr module_expr;
          (scanner ~bound:(name :: bound) scan)#expression body
      | _ -> super#expression expression

    method! pattern pattern =
      (match pattern.ppat_desc with
      | Ppat_var { txt; _ } -> (
          match decode txt with
          | Some (`Value value) -> Hashtbl.replace scan.values txt value
          | Some (`Own _) | None -> ())
      | _ -> ());
      super#pattern pattern
  end

let empty_scan () = { values = Hashtbl.create 64; heads = Hashtbl.create 16 }

let fresh ~taken base =
  let rec next index =
    let candidate = base ^ "_" ^ Int.to_string index in
    if Hashtbl.mem taken candidate then next (index + 1)
    else (
      Hashtbl.replace taken candidate ();
      candidate)
  in
  next 1

let assign_values ~free scan =
  let values = Hashtbl.fold (fun encoded value values -> (encoded, value) :: values) scan.values [] in
  let values = List.sort (fun (left, _) (right, _) -> String.compare left right) values in
  let taken = Hashtbl.create 64 in
  List.iter (fun name -> Hashtbl.replace taken name ()) free;
  List.iter (fun (_, value) -> Hashtbl.replace taken value.base ()) values;
  let has kind name = List.exists (fun (_, value) -> value.kind = kind && String.equal value.base name) values in
  let is_free name = List.mem name free in
  let final = Hashtbl.create 64 in
  let assign kind =
    List.iter
      (fun (encoded, value) ->
        if value.kind = kind then
          let renamed =
            match kind with
            | Public -> false
            | Generated -> is_free value.base
            | User -> is_free value.base || has Public value.base || has Generated value.base
          in
          Hashtbl.replace final encoded (if renamed then fresh ~taken value.base else value.base))
      values
  in
  assign Public;
  assign Generated;
  assign User;
  final

let check_public ~free_with_locations scan =
  Hashtbl.iter
    (fun _ (value : value) ->
      if value.kind = Public then
        match List.find_opt (fun (name, _) -> String.equal name value.base) free_with_locations with
        | Some (name, loc) ->
            Location.raise_errorf ~loc
              "router: the generated code defines %s; bind this value under another name or qualify it" name
        | None -> ())
    scan.values

let rec rewriter ~values ~aliases =
  let rename name =
    match decode name with
    | Some (`Value _) -> (
        match Hashtbl.find_opt values name with
        | Some final -> final
        | None -> invalid_arg "router: generated name was not assigned")
    | Some (`Own module_name) -> module_name
    | None -> ( match List.assoc_opt name aliases with Some alias -> alias | None -> name)
  in
  object (self)
    inherit Ast_traverse.map as super

    method! longident identifier =
      match identifier with
      | Lident name -> ( match decode name with Some _ -> Lident (rename name) | None -> identifier)
      | Ldot (parent, name) -> Ldot (self#longident_head parent, name)
      | Lapply (left, right) -> Lapply (self#longident left, self#longident right)

    method private longident_head identifier =
      match identifier with
      | Lident name -> Lident (rename name)
      | Ldot (parent, name) -> Ldot (self#longident_head parent, name)
      | Lapply (left, right) -> Lapply (self#longident_head left, self#longident right)

    method! module_expr module_expr =
      match module_expr.pmod_desc with
      | Pmod_ident { txt; loc } -> { module_expr with pmod_desc = Pmod_ident { txt = self#longident_head txt; loc } }
      | _ -> super#module_expr module_expr

    method! expression expression =
      match expression.pexp_desc with
      | Pexp_letmodule (({ txt = Some name; _ } as binding), module_expr, body) ->
          let body = (rewriter ~values ~aliases:(List.remove_assoc name aliases))#expression body in
          { expression with pexp_desc = Pexp_letmodule (binding, self#module_expr module_expr, body) }
      | _ -> super#expression expression

    method! pattern pattern =
      match pattern.ppat_desc with
      | Ppat_var { txt; loc } when Option.is_some (decode txt) ->
          { pattern with ppat_desc = Ppat_var { txt = rename txt; loc } }
      | _ -> super#pattern pattern
  end

let assert_resolved =
  let check name =
    if String.length name > 0 && name.[0] = marker then invalid_arg "router: unresolved generated name"
  in
  object
    inherit Ast_traverse.iter as super

    method! longident identifier =
      (match identifier with Lident name | Ldot (_, name) -> check name | Lapply _ -> ());
      super#longident identifier

    method! pattern pattern =
      (match pattern.ppat_desc with Ppat_var { txt; _ } -> check txt | _ -> ());
      super#pattern pattern
  end

type plan = { values : (string, string) Hashtbl.t; aliases : (string * string) list }

let plan ~user_expressions ~defined_modules scans =
  let scan = empty_scan () in
  List.iter
    (fun (other : scan) ->
      Hashtbl.iter (Hashtbl.replace scan.values) other.values;
      Hashtbl.iter (Hashtbl.replace scan.heads) other.heads)
    scans;
  check_public ~free_with_locations:(free_names user_expressions) scan;
  let identifiers = List.concat_map (fun expression -> List.map fst (identifiers expression)) user_expressions in
  let values = assign_values ~free:identifiers scan in
  let module_taken = Hashtbl.create 16 in
  List.iter (fun name -> Hashtbl.replace module_taken name ()) defined_modules;
  Hashtbl.iter (fun name () -> Hashtbl.replace module_taken name ()) scan.heads;
  let aliases =
    Hashtbl.fold (fun name () heads -> name :: heads) scan.heads []
    |> List.filter (fun name -> List.mem name defined_modules)
    |> List.sort String.compare
    |> List.map (fun name -> (name, fresh ~taken:module_taken name))
  in
  { values; aliases }

let scan_structure structure =
  let scan = empty_scan () in
  (scanner ~bound:[] scan)#structure structure;
  scan

let scan_signature signature =
  let scan = empty_scan () in
  (scanner ~bound:[] scan)#signature signature;
  scan

(* The component and JSX ppxes run on the generated file and expand to paths
   such as Stdlib.ref, React.componentLike and Js.t. Inside each module
   listed in [restore_in], every aliased name of such a module is bound back
   to its original, so those expansions see the originals. *)
let structure ~loc ~restore_in plan structure =
  let module B = Ast_builder.Default in
  let aliases =
    List.map
      (fun (name, alias) ->
        B.pstr_module ~loc
          (B.module_binding ~loc ~name:{ txt = Some alias; loc } ~expr:(B.pmod_ident ~loc { txt = Lident name; loc })))
      plan.aliases
  in
  let restored = List.filter (fun (name, _) -> List.mem name restore_in) plan.aliases in
  let restore =
    match restored with
    | [] -> []
    | aliases ->
        [
          B.pstr_open ~loc
            {
              popen_expr =
                B.pmod_structure ~loc
                  (List.map
                     (fun (name, alias) ->
                       B.pstr_module ~loc
                         (B.module_binding ~loc ~name:{ txt = Some name; loc }
                            ~expr:(B.pmod_ident ~loc { txt = Lident alias; loc })))
                     aliases);
              popen_override = Fresh;
              popen_loc = loc;
              popen_attributes = [];
            };
        ]
  in
  let restore_item item =
    match item.pstr_desc with
    | Pstr_module
        ({ pmb_name = { txt = Some name; _ }; pmb_expr = { pmod_desc = Pmod_structure items; _ } as expr; _ } as binding)
      when List.mem name restore_in ->
        {
          item with
          pstr_desc = Pstr_module { binding with pmb_expr = { expr with pmod_desc = Pmod_structure (restore @ items) } };
        }
    | _ -> item
  in
  let structure =
    aliases @ List.map restore_item ((rewriter ~values:plan.values ~aliases:plan.aliases)#structure structure)
  in
  assert_resolved#structure structure;
  structure

let signature ~loc ~restore_in plan signature =
  let module B = Ast_builder.Default in
  let aliases =
    List.map
      (fun (name, alias) ->
        B.psig_module ~loc
          (B.module_declaration ~loc ~name:{ txt = Some alias; loc }
             ~type_:(B.pmty_alias ~loc { txt = Lident name; loc })))
      plan.aliases
  in
  let restore =
    List.filter (fun (name, _) -> List.mem name restore_in) plan.aliases
    |> List.map (fun (name, alias) ->
        B.psig_modsubst ~loc
          (B.module_substitution ~loc ~name:{ txt = name; loc } ~manifest:{ txt = Lident alias; loc }))
  in
  let restore_item item =
    match item.psig_desc with
    | Psig_module
        ({ pmd_name = { txt = Some name; _ }; pmd_type = { pmty_desc = Pmty_signature items; _ } as typ; _ } as
         declaration)
      when List.mem name restore_in ->
        {
          item with
          psig_desc =
            Psig_module { declaration with pmd_type = { typ with pmty_desc = Pmty_signature (restore @ items) } };
        }
    | _ -> item
  in
  let signature =
    aliases @ List.map restore_item ((rewriter ~values:plan.values ~aliases:plan.aliases)#signature signature)
  in
  assert_resolved#signature signature;
  signature
