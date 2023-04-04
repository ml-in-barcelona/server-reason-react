(* This monstruosity runs a few bitwise operations as Int32 while the rest
   of the algorithm is on Int64. *)
module I32 = struct
  let ( << ) a b = Int32.shift_left (Int64.to_int32 a) b |> Int64.of_int32

  let ( * ) a b =
    Int32.mul (Int64.to_int32 a) (Int64.to_int32 b) |> Int64.of_int32

  let ( >>> ) a b = Int32.shift_right (Int64.to_int32 a) b |> Int64.of_int32

  let ( ++ ) a b =
    Int32.add (Int64.to_int32 a) (Int64.to_int32 b) |> Int64.of_int32

  let ( ^ ) a b =
    Int32.logxor (Int64.to_int32 a) (Int64.to_int32 b) |> Int64.of_int32
end

let ( << ) = Int64.shift_left
let ( & ) = Int64.logand

(* let ( ||| ) = Int64.logor *)
let ( * ) = Int64.mul
let ( >>> ) = Int64.shift_right
let ( ++ ) = Int64.add
let ( ^ ) = Int64.logxor

let to_base36 (num : Int64.t) =
  let rec to_base36' (num : Int64.t) =
    if num = 0L then []
    else
      let quotient = Int64.div num 36L in
      let remainder = Int64.rem num 36L in
      (match remainder with
      | 10L -> "a"
      | 11L -> "b"
      | 12L -> "c"
      | 13L -> "d"
      | 14L -> "e"
      | 15L -> "f"
      | 16L -> "g"
      | 17L -> "h"
      | 18L -> "i"
      | 19L -> "j"
      | 20L -> "k"
      | 21L -> "l"
      | 22L -> "m"
      | 23L -> "n"
      | 24L -> "o"
      | 25L -> "p"
      | 26L -> "q"
      | 27L -> "r"
      | 28L -> "s"
      | 29L -> "t"
      | 30L -> "u"
      | 31L -> "v"
      | 32L -> "w"
      | 33L -> "x"
      | 34L -> "y"
      | 35L -> "z"
      | _ -> string_of_int (Int64.to_int remainder))
      :: to_base36' quotient
  in
  num |> to_base36' |> List.rev |> String.concat ""

let to_css (number : Int64.t) = number |> to_base36

(*
    The murmur2 hashing is based on @emotion/hash, which is based on
    https://github.com/garycourt/murmurhash-js and ported from
    https://github.com/aappleby/smhasher/blob/61a0530f28277f2e850bfc39600ce61d02b518de/src/MurmurHash2.cpp#L37-L86.

    It's an ongoing effort to match the hashing function, currently not very precise.
    It's a big WIP and that's why it's full of prints and comments.

    Reference: https://github.com/emotion-js/emotion/blob/main/packages/hash/src/index.js
  *)
let murmur2 (str : string) =
  let length = String.length str in
  (* Initialize the hash *)
  let seed = 123456789L in
  let h = ref seed in

  (* Mix 4 bytes at a time into the hash *)
  let k = ref Int64.zero in
  let i = ref 0 in
  let len = ref length in

  while !len >= 4 do
    k :=
      Char.code str.[!i]
      lor (Char.code str.[!i + 1] lsl 8)
      lor (Char.code str.[!i + 2] lsl 16)
      lor (Char.code str.[!i + 3] lsl 24)
      |> Int64.of_int;

    (* print_endline (Int64.to_string first); *)
    let k_one = !k & 65535L in
    (* print_endline (Int64.to_string k_one); *)
    (* print_endline (Int64.to_string (k_one * 1540483477L)); *)
    let k_pre_16 = I32.( * ) (!k >>> 16) 59797L in
    (* print_endline (Int64.to_string k_pre_16); *)
    let k_16 = I32.( << ) k_pre_16 16 in
    (* print_endline (Int64.to_string k_16); *)
    k := (k_one * 1540483477L) ++ k_16;

    (* print_endline (Int64.to_string !k); *)

    (* k ^= k >>> 24; *)
    (* k ^= /* k >>> r: */ k >>> 24; *)
    k := I32.( ^ ) !k (I32.( >>> ) !k 24);

    (* print_endline (Int64.to_string !k); *)
    (* print_endline "--"; *)
    let first_h =
      ((!k & 65535L) * 1540483477L)
      ++ I32.( << ) (I32.( >>> ) !k 16 * 59797L) 16
    in
    let second_h =
      ((!h & 65535L) * 1540483477L)
      ++ I32.( << ) (I32.( >>> ) !h 16 * 59797L) 16
    in

    h := I32.( ^ ) first_h second_h;
    (* print_endline
       (Int64.to_string
          (I32.( << ) (I32.( >>> ) !k 16 * 59797L) 16)) *)
    (* print_endline (Int64.to_string ((!h & 65535L) * 1540483477L)); *)
    (* print_endline (Int64.to_string !h) *)
    len := !len - 4;
    i := !i + 1
  done;

  print_endline (Printf.sprintf "hash: %d" (Int64.to_int !h));

  (* print_endline (Printf.sprintf "len: %d" !len); *)

  (* Handle the last few bytes of the input array *)
  (match !len with
  | 3 ->
      (* print_endline (Printf.sprintf "char: %c" str.[length - 2]); *)
      let temp = Int64.of_int (Char.code str.[length - 2]) & 255L in
      (* print_endline (Printf.sprintf "temp: %d" (Int64.to_int temp)); *)
      h := I32.( ^ ) !h (Int64.shift_left temp 16)
      (* print_endline (Printf.sprintf "hash: %d" (Int64.to_int !h)) *)
  | 2 ->
      print_endline (Printf.sprintf "char: %c" str.[length - 1]);
      let temp = Int64.of_int (Char.code str.[length - 1]) & 255L in
      h := I32.( ^ ) !h (Int64.shift_left temp 8)
  | 1 ->
      h := !h ^ (Int64.of_int (Char.code str.[length - 1]) & 255L);
      h :=
        I32.( * ) (!h & 65535L) 1540483477L ++ (I32.( >>> ) !h 16 * 59797L << 16)
  | _ -> ());

  (* Do a few final mixes of the hash to ensure the last few *)
  (* bytes are well-incorporated. *)
  (* print_endline (Int64.to_string (!h >>> 13)); *)
  h := !h ^ I32.( >>> ) !h 13;
  h :=
    I32.( ++ )
      (I32.( * ) (!h & 65535L) 1540483477L)
      (I32.( * ) (!h >>> 16) 59797L << 16);

  h := !h ^ I32.( >>> ) !h 15;
  !h >>> 0

(*
  h =
    /* Math.imul(h, m): */
    (h & 0xffff) * 0x5bd1e995 + (((h >>> 16) * 0xe995) << 16)

  return ((h ^ (h >>> 15)) >>> 0).toString(36) *)

(*
   h = (((h & 0xffff) * 0x5bd1e995) + ((((h >>> 16) * 0x5bd1e995) & 0xffff) << 16));
   h ^= h >>> 15; *)

let make (str : string) = str |> murmur2 |> to_css

(* Re-export as default since we want to compile it with Melange and match
   the same interface as @emotion/hash *)
let default = make
