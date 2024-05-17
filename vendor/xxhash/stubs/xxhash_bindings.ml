open Ctypes

module type BINDINGS = sig
  type hash
  type internal

  val default_seed : hash
  val hash_of_internal : internal -> hash
  val internal_of_hash : hash -> internal

  val hash : string -> Unsigned.size_t -> internal -> internal

  type state

  val create : unit -> state
  val free : state -> int

  val reset : state -> internal -> int
  val update : state -> string -> Unsigned.size_t -> int
  val digest : state -> internal

  val to_hex: hash -> string
end

module Functions (F : Cstubs.FOREIGN) = struct
  open F

  module XXH32 = struct
    type hash = nativeint
    type internal = Unsigned.uint

    let default_seed = Nativeint.zero
    let hash_of_internal i = Unsigned.UInt.to_int64 i |> Int64.to_nativeint
    let internal_of_hash h = Int64.of_nativeint h |> Unsigned.UInt.of_int64

    let hash = F.foreign "XXH32" (string @-> size_t @-> uint @-> returning uint)

    type state_s
    type state = state_s structure ptr

    let state_t : state_s structure typ = structure "XXH32_state_s"

    let create = F.foreign "XXH32_createState" (void @-> returning (ptr state_t))
    let free = F.foreign "XXH32_freeState" (ptr state_t @-> returning int)

    let reset = F.foreign "XXH32_reset" (ptr state_t @-> uint @-> returning int)
    let update = F.foreign "XXH32_update" (ptr state_t @-> string @-> size_t @-> returning int)
    let digest = F.foreign "XXH32_digest" (ptr state_t @-> returning uint)

    let to_hex hash = Printf.sprintf "%nx" hash
  end

  module XXH64 = struct
    type hash = int64
    type internal = Unsigned.ullong

    let default_seed = 0L
    let hash_of_internal = Unsigned.ULLong.to_int64
    let internal_of_hash = Unsigned.ULLong.of_int64

    let hash = F.foreign "XXH64" (string @-> size_t @-> ullong @-> returning ullong)

    type state_s
    type state = state_s structure ptr

    let state_t : state_s structure typ = structure "XXH64_state_s"

    let create = F.foreign "XXH64_createState" (void @-> returning (ptr state_t))
    let free = F.foreign "XXH64_freeState" (ptr state_t @-> returning int)

    let reset = F.foreign "XXH64_reset" (ptr state_t @-> ullong @-> returning int)
    let update = F.foreign "XXH64_update" (ptr state_t @-> string @-> size_t @-> returning int)
    let digest = F.foreign "XXH64_digest" (ptr state_t @-> returning ullong)

    let to_hex hash = Printf.sprintf "%Lx" hash
  end

  type xxh3_state_s
  type xxh3_state = xxh3_state_s structure ptr
  let xxh3_state_t : xxh3_state_s structure typ = structure "XXH3_state_s"
  let xxh3_create = F.foreign "XXH3_createState" (void @-> returning (ptr xxh3_state_t))
  let xxh3_free = F.foreign "XXH3_freeState" (ptr xxh3_state_t @-> returning int)

  module XXH3_64 = struct
    type hash = int64
    type internal = Unsigned.ullong

    let default_seed = 0L
    let hash_of_internal = Unsigned.ULLong.to_int64
    let internal_of_hash = Unsigned.ULLong.of_int64

    let hash = F.foreign "XXH3_64bits_withSeed" (string @-> size_t @-> ullong @-> returning ullong)

    type nonrec state = xxh3_state
    let state_t = xxh3_state_t

    let create = xxh3_create
    let free = xxh3_free

    let reset = F.foreign "XXH3_64bits_reset_withSeed" (ptr state_t @-> ullong @-> returning int)
    let update = F.foreign "XXH3_64bits_update" (ptr state_t @-> string @-> size_t @-> returning int)
    let digest = F.foreign "XXH3_64bits_digest" (ptr state_t @-> returning ullong)

    let to_hex hash = Printf.sprintf "%Lx" hash
  end

  (* module XXH3_128 = struct
    type hash = {low64: int64; high64: int64} 
    
    type internal
    let xxh128_hash_t: internal structure typ = structure "XXH128_hash_t"

    let low64  = field xxh128_hash_t "low64" ullong
    let high64 = field xxh128_hash_t "high64" ullong
    let () = seal xxh128_hash_t

    let default_seed = {low64 = 0L; high64 = 0L}

    let hash_of_internal internal = 
      let low64 = Unsigned.ULLong.to_int64(getf internal low64) in
      let high64 = Unsigned.ULLong.to_int64(getf internal high64) in
      {low64 ; high64}

    let internal_of_hash hash = 
      let v = make xxh128_hash_t in
      setf v low64 (Unsigned.ULLong.of_int64 hash.low64);
      setf v high64 (Unsigned.ULLong.of_int64 hash.high64);
      v 

    let hash = F.foreign "XXH3_128bits_withSeed" (string @-> size_t @-> ullong @-> returning (ptr xxh128_hash_t))

    type nonrec state = xxh3_state
    let state_t = xxh3_state_t

    let create = xxh3_create
    let free = xxh3_free

    let reset = F.foreign "XXH3_128bits_reset_withSeed" (ptr state_t @-> ullong @-> returning int)
    let update = F.foreign "XXH3_128bits_update" (ptr state_t @-> string @-> size_t @-> returning int)
    let digest = F.foreign "XXH3_128bits_digest" (ptr state_t @-> returning (ptr xxh128_hash_t))
  end *)
end
