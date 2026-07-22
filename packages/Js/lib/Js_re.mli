type t
type result

val index : result -> int
val input : result -> string
val fromString : string -> t
val fromStringWithFlags : string -> flags:string -> t
val flags : t -> string
val global : t -> bool
val ignoreCase : t -> bool
val lastIndex : t -> int
val setLastIndex : t -> int -> unit
val multiline : t -> bool
val source : t -> string
val sticky : t -> bool
val unicode : t -> bool

val dotAll : t -> bool
(** Returns whether the dotAll (s) flag is set *)

val exec : str:string -> t -> result option
val test : str:string -> t -> bool
val captures : result -> string Js_internal.nullable array

module Prepared : sig
  type input
  type match_

  val make : string -> input
  val exec : input -> t -> match_ option
  val captures : match_ -> string Js_internal.nullable array
  val range : match_ -> int * int
  val byte_range : input -> start:int -> end_:int -> (int * int) option
  val substring : input -> start:int -> end_:int -> string
  val advance_index : input -> unicode:bool -> int -> int
end

val groups : result -> (string * string option) list
(** Returns all named capture groups as a list of (name, value) pairs. The value is [None] when the group did not
    participate in the match. *)

val group : string -> result -> string option
(** Returns the value of a named capture group, or None if not found *)
