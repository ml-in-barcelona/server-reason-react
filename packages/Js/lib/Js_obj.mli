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
end
