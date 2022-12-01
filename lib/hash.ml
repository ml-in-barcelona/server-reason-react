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
let ( ||| ) = Int64.logor
let ( * ) = Int64.mul
let ( >>> ) = Int64.shift_right
let ( ++ ) = Int64.add
let ( ^ ) = Int64.logxor

(*
    This hashing is a rewrite of @emotion/hash. What's below it's an ongoing effort to match the hashing function, currently not very precise. It's currenlty
    a big WIP and that's why it's full of prints and comments.

    Reference: https://github.com/emotion-js/emotion/blob/main/packages/hash/src/index.js
  *)
let make (str : string) =
  (* Initialize the hash *)
  let len = str |> String.length |> Int64.of_int in
  let h = ref (Int64.mul len len) in

  (* Mix 4 bytes at a time into the hash *)
  let k = ref Int64.zero in
  let i = ref 0 in
  let len = ref (String.length str) in

  let get_int64_char str i = String.get str i |> Char.code |> Int64.of_int in

  while !len >= 4 do
    let first = get_int64_char str !i & 255L in
    let second = (get_int64_char str (!i + 1) & 255L) << 8 in
    let third = (get_int64_char str (!i + 2) & 255L) << 16 in
    let forth = (get_int64_char str (!i + 3) & 255L) << 24 in
    k := first ||| (second ||| (third ||| forth));

    (* print_endline (Int64.to_string first); *)
    (* print_endline (Int64.to_string second); *)
    (* print_endline (Int64.to_string third); *)
    (* print_endline (Int64.to_string forth); *)
    (* print_endline "--"; *)
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

  (* print_endline (Int64.to_string !h); *)

  (* Handle the last few bytes of the input array *)
  (* (h :=
     match !len with
     | 3 -> !h ^ I32.( << ) (get_int64_char str (!i + 2) & 255L) 16
     | 2 -> !h ^ (get_int64_char str (!i + 1) & 255L) << 8
     | 1 ->
         h := I32.( ^ ) !h (get_int64_char str !i & 255L);
         print_endline (Int64.to_string !h);
         print_endline (Int64.to_string (Int64.shift_right !h 16));
         ((!h & 65535L) * 1540483477L) ++ ((!h >>> 16) * 59797L << 16)
     | _ -> !h); *)

  (* Do a few final mixes of the hash to ensure the last few
     * bytes are well-incorporated. *)

  (* h ^= h >>> 13;
     h =
       (h & 0xffff) * 0x5bd1e995 + (((h >>> 16) * 0xe995) << 16);
  *)

  (* Do a few final mixes of the hash to ensure the last few *)
  (* bytes are well-incorporated. *)
  (* print_endline (Int64.to_string (!h >>> 13)); *)
  h := !h ^ I32.( >>> ) !h 13;
  h :=
    I32.( ++ )
      (I32.( * ) (!h & 65535L) 1540483477L)
      (I32.( * ) (!h >>> 16) (59797L << 16));
  h := !h ^ I32.( >>> ) !h 15;

  (* turn to base 36 *)
  (* let result = ((h ^ (h >>> 15)) >>> 0).toString(36); *)
  !h |> Int64.to_string |> String.cat "css-"
