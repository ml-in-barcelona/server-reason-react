type t
type of_rsc_error = Rsc_error of string | Unexpected_variant of string

exception Of_rsc_error of of_rsc_error

val of_rsc_error_to_string : of_rsc_error -> string
val of_rsc_error : ?depth:int -> ?width:int -> rsc:t -> string -> 'a
val of_rsc_msg_error : string -> 'a
val of_rsc_unexpected_variant : ?depth:int -> ?width:int -> rsc:t -> string -> 'a
val of_rsc_msg_unexpected_variant : string -> 'a

module Primitives : sig
  val string_of_rsc : t -> string
  val bool_of_rsc : t -> bool
  val float_of_rsc : t -> float
  val int_of_rsc : t -> int
  val int64_of_rsc : t -> int64
  val char_of_rsc : t -> char
  val option_of_rsc : (t -> 'a) -> t -> 'a option
  val unit_of_rsc : t -> unit
  val result_of_rsc : (t -> 'a) -> (t -> 'b) -> t -> ('a, 'b) result
  val list_of_rsc : (t -> 'a) -> t -> 'a list
  val array_of_rsc : (t -> 'a) -> t -> 'a array
  val tuple2_of_rsc : (t -> 'a) -> (t -> 'b) -> t -> 'a * 'b
  val tuple3_of_rsc : (t -> 'a) -> (t -> 'b) -> (t -> 'c) -> t -> 'a * 'b * 'c
  val tuple4_of_rsc : (t -> 'a) -> (t -> 'b) -> (t -> 'c) -> (t -> 'd) -> t -> 'a * 'b * 'c * 'd
  val react_element_of_rsc : t -> React.element
  val promise_of_rsc : (t -> 'a) -> t -> 'a Js.Promise.t
  val server_function_of_rsc : t -> 'callback Runtime.server_function
  val list_values_to_rsc : t list -> t
  val assoc_to_rsc : (string * t) list -> t
  val string_to_rsc : string -> t
  val bool_to_rsc : bool -> t
  val float_to_rsc : float -> t
  val int_to_rsc : int -> t
  val int64_to_rsc : int64 -> t
  val char_to_rsc : char -> t
  val option_to_rsc : ('a -> t) -> 'a option -> t
  val unit_to_rsc : unit -> t
  val result_to_rsc : ('a -> t) -> ('b -> t) -> ('a, 'b) result -> t
  val list_to_rsc : ('a -> t) -> 'a list -> t
  val array_to_rsc : ('a -> t) -> 'a array -> t
  val tuple2_to_rsc : ('a -> t) -> ('b -> t) -> 'a * 'b -> t
  val tuple3_to_rsc : ('a -> t) -> ('b -> t) -> ('c -> t) -> 'a * 'b * 'c -> t
  val tuple4_to_rsc : ('a -> t) -> ('b -> t) -> ('c -> t) -> ('d -> t) -> 'a * 'b * 'c * 'd -> t
  val react_element_to_rsc : React.element -> t
  val promise_to_rsc : ('a -> t) -> 'a Js.Promise.t -> t
  val server_function_to_rsc : 'callback Runtime.server_function -> t
end
