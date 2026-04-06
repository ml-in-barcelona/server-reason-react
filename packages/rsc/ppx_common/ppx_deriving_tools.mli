(** A collection of tools to make it easy to build ppx deriving plugins. *)

open Ppxlib

(** A deriver is represented by this api *)
class virtual deriving : object
  method virtual name : label
  (** name of the deriver *)

  method virtual extension : loc:location -> path:label -> core_type -> expression
  (** a deriver can be applied to as type expression as extension node. *)

  method virtual str_type_decl : ctxt:Expansion_context.Deriver.t -> rec_flag * type_declaration list -> structure
  (** or it can be attached to a type declaration. *)

  method virtual sig_type_decl : ctxt:Expansion_context.Deriver.t -> rec_flag * type_declaration list -> signature
end

val register : ?deps:Deriving.t list -> deriving -> Deriving.t
(** handles registration of the deriver *)

val register_combined : ?deps:Deriving.t list -> label -> deriving list -> Deriving.t
(** multiple derivers can be registered under the same name *)

(** A common scheme to define data conversions (like to_json/of_json). *)
module Conv : sig
  (** A simplified parsetree representation.

      We define a few types to represent the data we want to derive conversions for. Such types are less verbose but
      less precise than the original parsetree, though it is enough for conversion purposes.

      The types still keep the original parsetree nodes as context (this is also needed to play well with
      Ppxlib.Attributes API). *)

  type 'ctx tuple = { tpl_loc : location; tpl_types : core_type list; tpl_ctx : 'ctx }
  type 'ctx record = { rcd_loc : location; rcd_fields : label_declaration list; rcd_ctx : 'ctx }

  type variant_case =
    | Vcs_tuple of label loc * variant_case_ctx tuple
    | Vcs_record of label loc * variant_case_ctx record

  and variant_case_ctx = Vcs_ctx_variant of constructor_declaration | Vcs_ctx_polyvariant of row_field

  type variant = { vrt_loc : location; vrt_cases : variant_case list; vrt_ctx : variant_ctx }
  and variant_ctx = Vrt_ctx_variant of type_declaration | Vrt_ctx_polyvariant of core_type

  type derive_of_core_type := core_type -> expression -> expression

  val deriving_to :
    name:label ->
    t_to:(loc:location -> core_type) ->
    derive_of_tuple:(derive_of_core_type -> core_type tuple -> expression list -> expression) ->
    derive_of_record:(derive_of_core_type -> type_declaration record -> expression list -> expression) ->
    derive_of_variant_case:(derive_of_core_type -> variant_case -> expression list -> expression) ->
    unit ->
    deriving
  (** Define a serializer. *)

  val deriving_of :
    name:label ->
    of_t:(loc:location -> core_type) ->
    is_allow_any_constr:(variant_case_ctx -> bool) ->
    derive_of_tuple:(derive_of_core_type -> core_type tuple -> expression -> expression) ->
    derive_of_record:(derive_of_core_type -> type_declaration record -> expression -> expression) ->
    derive_of_variant:
      (derive_of_core_type ->
      variant ->
      allow_any_constr:(expression -> expression) option ->
      expression ->
      expression ->
      expression) ->
    derive_of_variant_case:
      (derive_of_core_type ->
      (expression option -> expression) ->
      variant_case ->
      allow_any_constr:(expression -> expression) option ->
      expression ->
      expression) ->
    unit ->
    deriving
  (** Define a deserializer. *)

  val deriving_of_match :
    name:label ->
    of_t:(loc:location -> core_type) ->
    cmp_sort_vcs:(variant_case_ctx -> variant_case_ctx -> int) ->
    derive_of_tuple:(derive_of_core_type -> core_type tuple -> expression -> expression) ->
    derive_of_record:(derive_of_core_type -> type_declaration record -> expression -> expression) ->
    derive_of_variant_case:(derive_of_core_type -> (expression option -> expression) -> variant_case -> case) ->
    unit ->
    deriving
  (** Define a deserializer using pattern matching.

      This is a less general but more compact variant of [deriving_of], for cases where the serialized data can be
      inspected with pattern matching. *)
end

val not_supported : loc:location -> string -> 'a
(** [not_supported what] terminates ppx with an error message telling [what] unsupported. *)

val gen_tuple : loc:location -> label -> int -> pattern list * expression
(** [let patts, expr = gen_tuple label n in ...] creates a tuple expression and a corresponding list of patterns. *)

(** Auxiliary functions to generate record expressions and patterns. *)

val gen_record : loc:location -> label -> (label loc * attributes * 'a) list -> pattern list * expression
(** [let patts, expr = gen_tuple label n in ...] creates a record expression and a corresponding list of patterns. *)

val gen_pat_tuple : loc:location -> string -> int -> pattern * expression list
(** [let patt, exprs = gen_pat_tuple ~loc prefix n in ...] generates a pattern to match a tuple of size [n] and a list
    of expressions [exprs] to refer to names bound in this pattern. *)

val gen_pat_record : loc:location -> string -> label loc list -> pattern * expression list
(** [let patt, exprs = gen_pat_record ~loc prefix fs in ...] generates a pattern to match record with fields [fs] and a
    list of expressions [exprs] to refer to names bound in this pattern. *)

val gen_pat_list : loc:location -> string -> int -> pattern * expression list
(** [let patt, exprs = gen_pat_list ~loc prefix n in ...] generates a pattern to match a list of size [n] and a list of
    expressions [exprs] to refer to names bound in this pattern. *)

val ( --> ) : pattern -> expression -> case
(** A shortcut to define a pattern matching case. *)

val map_loc : ('a -> 'b) -> 'a loc -> 'b loc
(** Map over data with location, useful to lift derive_of_label, derive_of_longident *)

(** Low-level deriver classes. *)

(** 1-arity deriver *)
class virtual deriving1 : object
  inherit deriving

  method virtual t : loc:location -> label loc -> core_type -> core_type
  (** the type of the term generated by the deriver *)

  (** ESSENTIAL METHODS *)

  method derive_of_polyvariant : core_type -> row_field list -> expression -> expression
  method derive_of_record : type_declaration -> label_declaration list -> expression -> expression
  method derive_of_tuple : core_type -> core_type list -> expression -> expression
  method derive_of_variant : type_declaration -> constructor_declaration list -> expression -> expression

  (** LOW-LEVEL METHODS *)

  method derive_type_ref : loc:location -> label -> longident loc -> core_type list -> expression -> expression
  method derive_of_core_type : core_type -> expression -> expression
  method derive_of_type_declaration : type_declaration -> value_binding list
end
