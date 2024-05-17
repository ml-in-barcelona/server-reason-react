exception XXH_error

module type XXHASH = sig
  type hash
  type state

  val hash : ?seed:hash -> string -> hash
  val create : unit -> state
  val reset : ?seed:hash -> state -> unit
  val update : state -> string -> unit
  val digest : state -> hash
  val free : state -> unit

  val with_state : ?seed:hash -> (state -> unit) -> hash

  val to_hex: hash -> string
end

let check errorcode =
  if errorcode != 0 then raise XXH_error

module XXHash (Bindings : Xxhash_bindings.BINDINGS) = struct
  type hash = Bindings.hash
  type state = Bindings.state

  let hash ?(seed=Bindings.default_seed) input =
    let length = String.length input |> Unsigned.Size_t.of_int in
    Bindings.internal_of_hash seed
    |> Bindings.hash input length
    |> Bindings.hash_of_internal

  let create () =
    Bindings.create ()

  let reset ?(seed=Bindings.default_seed) state =
    Bindings.internal_of_hash seed
    |> Bindings.reset state
    |> check

  let update state input =
    let length = String.length input |> Unsigned.Size_t.of_int in
    Bindings.update state input length
    |> check

  let digest state =
    Bindings.digest state |> Bindings.hash_of_internal

  let free state =
    Bindings.free state |> check

  let with_state ?(seed=Bindings.default_seed) f =
    let state = create () in
    try
      reset ~seed state;
      f state;
      let h = digest state in
      free state;
      h
    with exn -> free state; raise exn
  let to_hex = Bindings.to_hex
end

module XXH32 : (XXHASH with type hash = nativeint) = XXHash (C.Function.XXH32)
module XXH64 : (XXHASH with type hash = int64) = XXHash (C.Function.XXH64)
module XXH3_64 : (XXHASH with type hash = int64) = XXHash (C.Function.XXH3_64)
