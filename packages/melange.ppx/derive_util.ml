(** Shared utilities for record type derivers (jsProperties, getSet).

    These helpers handle common operations like checking for optional attributes and extracting type information from
    type declarations. *)

open Ppxlib
module Builder = Ast_builder.Default

(** Returns [true] if the attribute list contains [[@mel.optional]] or [[@bs.optional]]. *)
let has_mel_optional attrs =
  List.exists (fun { attr_name = { txt; _ }; _ } -> txt = "mel.optional" || txt = "bs.optional") attrs

(** Extracts the inner type from an optional field.

    For fields marked with [[@mel.optional]], this unwraps the [option] type to get the inner type. For example,
    [int option] becomes [int].

    Raises an error if [[@mel.optional]] is used on a non-option type. *)
let get_pld_type pld_type ~attrs =
  let is_optional = has_mel_optional attrs in
  match is_optional with
  | true -> (
      match pld_type.ptyp_desc with
      | Ptyp_constr ({ txt = Lident "option"; _ }, [ inner_type ]) -> inner_type
      | _ -> Location.raise_errorf ~loc:pld_type.ptyp_loc "`[@mel.optional]' must appear on an option type (`_ option')"
      )
  | false -> pld_type

(** Constructs a core type from a type declaration.

    Given [type 'a t = ...], this returns the core type ['a t] that can be used in function signatures. Handles type
    parameters correctly. *)
let core_type_of_type_declaration (tdcl : type_declaration) =
  match tdcl with
  | { ptype_name = { txt; loc }; ptype_params; _ } ->
      Builder.ptyp_constr ~loc { txt = Lident txt; loc } (List.map fst ptype_params)
