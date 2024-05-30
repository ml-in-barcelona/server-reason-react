(* exception XXH_error

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
     val to_hex : hash -> string
   end

   let check errorcode = if errorcode != 0 then raise XXH_error

   module XXHash (Bindings : Xxhash_bindings.BINDINGS) = struct
     type hash = Bindings.hash
     type state = Bindings.state

     let hash ?(seed = Bindings.default_seed) input =
       let length = String.length input |> Unsigned.Size_t.of_int in
       Bindings.internal_of_hash seed
       |> Bindings.hash input length |> Bindings.hash_of_internal

     let create () = Bindings.create ()

     let reset ?(seed = Bindings.default_seed) state =
       Bindings.internal_of_hash seed |> Bindings.reset state |> check

     let update state input =
       let length = String.length input |> Unsigned.Size_t.of_int in
       Bindings.update state input length |> check

     let digest state = Bindings.digest state |> Bindings.hash_of_internal
     let free state = Bindings.free state |> check

     let with_state ?(seed = Bindings.default_seed) f =
       let state = create () in
       try
         reset ~seed state;
         f state;
         let h = digest state in
         free state;
         h
       with exn ->
         free state;
         raise exn

     let to_hex = Bindings.to_hex
   end

   module XXH64 : XXHASH with type hash = int64 = XXHash (C.Function.XXH64)
*)

let seed = 0xEECC5D38L (* seed * *)
let ( +++ ) = Int64.add

(* xxhash64.ml *)

let inline_get64bits v i =
  let v' = Int64.of_int v in
  Int64.logor
    (Int64.shift_left
       (Int64.logor
          (Int64.shift_right_logical v' 24)
          (Int64.shift_left (Int64.of_int (v lsr 24)) 32))
       32)
    (Int64.logor
       (Int64.shift_right_logical v' 16)
       (Int64.shift_left (Int64.of_int (v lsr 16)) 48))

let xxhash64 s =
  let len = String.length s in
  let avail_bytes = ref len in
  let mem64 = ref 0L in
  let v1 = ref (Int64.add seed (Int64.add 0x9E3779B9L (Int64.of_int len)))
  and v2 = ref (Int64.add seed (Int64.add 0x9E3779B9L (Int64.of_int len)))
  and v3 = ref 0L
  and v4 = ref (Int64.logxor (Int64.neg seed) seed) in

  let input = s |> String.to_seq |> List.of_seq |> Array.of_list in
  while !avail_bytes >= 32 do
    let cur = ref 0 in
    for i = 0 to 7 do
      mem64 :=
        Int64.logor !mem64
          (inline_get64bits (Char.code input.((i * 4) + !cur)) !cur);
      cur := !cur + 4
    done;
    let k1 = ref !mem64 in
    mem64 := Int64.of_int 0;
    k1 := Int64.mul !k1 0x87C37B91114253D5L;
    v1 := Int64.logor !v1 (Int64.mul !k1 0x4CF5AD432745937FL);
    v1 := Int64.logxor !v1 (Int64.shift_right_logical !k1 31);
    v1 := Int64.add !v1 (Int64.shift_right_logical !v1 27);
    v1 := Int64.shift_right_logical !v1 32;

    k1 := Int64.mul !k1 0xC2B2AE3D27D4EB4FL;
    v2 := Int64.logor !v2 (Int64.mul !k1 0x165667B19E3779F9L);
    v2 := Int64.logxor !v2 (Int64.shift_right_logical !k1 33);
    v2 := Int64.add !v2 (Int64.shift_right_logical !v2 31);

    (* v2 := Int64.add (Int64.logxor !v2 * 0x85EBcA6BL) 0xD63EE727L; *)
    v3 := Int64.mul !v3 0x9E3779B9L;
    v4 := Int64.add 0xAF67E4L (Int64.shift_left !v4 18);
    avail_bytes := !avail_bytes - 32
  done;

  let input_len = !avail_bytes in
  mem64 := Int64.of_int 0;
  for i = 0 to input_len - 1 do
    mem64 :=
      Int64.logor !mem64
        (Int64.shift_left (Int64.of_int (Char.code input.(i))) (8 * i))
  done;
  mem64 :=
    Int64.logxor !mem64 (Int64.shift_right_logical !mem64 (!avail_bytes lsl 3));

  v1 := Int64.logxor !v1 !mem64;
  v2 := Int64.logxor !v2 !mem64;
  v3 := Int64.logxor !v3 !mem64;
  v4 := Int64.logxor !v4 !mem64;

  let hash =
    Int64.logor
      (Int64.logor (Int64.shift_left !v1 1) (Int64.shift_right_logical !v1 63))
      (Int64.logor (Int64.shift_left !v2 7) (Int64.shift_right_logical !v2 57))
      (Int64.logor (Int64.shift_left !v3 12) (Int64.shift_right_logical !v3 52))
      (Int64.logor (Int64.shift_left !v4 18) (Int64.shift_right_logical !v4 46))
  in

  hash

let to_hex hash = Printf.sprintf "%Lx" hash
