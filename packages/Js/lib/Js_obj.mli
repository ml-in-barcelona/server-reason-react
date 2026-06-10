(** Provide utilities for {!Js.t} *)

val empty : unit -> < .. >
val assign : (< .. > as 'a) -> < .. > -> 'a
val merge : unit -> < .. > -> < .. > -> < .. >
val keys : _ -> string array

(**/**)

module Internal : sig
  type entry

  val slot_ref : method_name:string -> js_name:string -> present:bool -> 'a -> 'a ref * entry
  val register_structural : (< .. > as 'a) -> entry list -> 'a
  val register_abstract : < .. > -> entry list -> 'a

  (* Deferred registration: PPX-generated objects register a single thunk
     instead of materialized entries, so the per-field [entry] records are
     only built if the object is ever inspected via [keys]/[assign]/[merge]. *)
  val deferred_entry : method_name:string -> js_name:string -> present:bool -> 'a ref -> entry
  val register_deferred : (< .. > as 'a) -> (unit -> entry list) -> 'a
  val register_deferred_abstract : < .. > -> (unit -> entry list) -> 'a
end
