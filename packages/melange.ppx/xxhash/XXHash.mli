(** xxHash - Extremely fast hash algorithm *)

exception XXH_error

module type XXHASH = sig
  type hash
  type state

  (** {2 Short input} *)

  val hash : ?seed:hash -> string -> hash
  (** [hash ~seed input] returns the hash of [input]. This is equivalent to
      {[let state = create () in
reset ~seed state;
update state input;
let hash = digest state in
free state;
hash]}
  *)

  (** {2 Streaming} *)

  val create : unit -> state
  (** [create ()] returns an uninitialized state. *)

  val reset : ?seed:hash -> state -> unit
  (** [reset ~seed state] resets [state] with an optional seed. *)

  val update : state -> string -> unit
  (** [update state input] adds [input] to [state]. *)

  val digest : state -> hash
  (** [digest state] returns the hash all input added to [state]. *)

  val free : state -> unit
  (** [free state] releases the memory used by [state]. *)

  val with_state : ?seed:hash -> (state -> unit) -> hash
  (** [with_state ~seed f] returns the hash of all input added to [state] by [f].

      [with_state (fun state -> update state input)] is equivalent to [hash input].
  *)

  val to_hex : hash -> string
end

module XXH32 : XXHASH with type hash = nativeint
module XXH64 : XXHASH with type hash = int64
module XXH3_64 : XXHASH with type hash = int64
