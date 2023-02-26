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

let to_css (number : Int64.t) = number |> to_base36 |> String.cat "css-"

(*
    This hashing is a rewrite of @emotion/hash. What's below it's an ongoing effort to match the hashing function, currently not very precise. It's currenlty
    a big WIP and that's why it's full of prints and comments.

    Reference: https://github.com/emotion-js/emotion/blob/main/packages/hash/src/index.js
  *)
let murmur2 (str : string) =
  (* Initialize the hash *)
  let len = str |> String.length |> Int64.of_int in
  let h = ref (Int64.mul len len) in

  (* Mix 4 bytes at a time into the hash *)
  let k = ref Int64.zero in
  let i = ref 0 in
  let len = ref (String.length str) in

  while !len >= 4 do
    k :=
      Char.code str.[!i]
      lor (Char.code str.[!i + 1] lsl 8)
      lor (Char.code str.[!i + 2] lsl 16)
      lor (Char.code str.[!i + 3] lsl 24)
      |> Int64.of_int;

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
  (* (match !len with
     | 3 ->
         h :=
           Int64.logxor !h
             (Int64.shift_left (Int64.of_int (Char.code str.[!len - 2])) 16)
     | 2 ->
         h :=
           Int64.logxor !h
             (Int64.shift_left (Int64.of_int (Char.code str.[!len - 1])) 8)
     | 1 -> h := Int64.logxor !h (Int64.of_int (Char.code str.[!len]))
     | _ -> ()); *)

  (* Do a few final mixes of the hash to ensure the last few *)
  (* bytes are well-incorporated. *)
  (* print_endline (Int64.to_string (!h >>> 13)); *)
  h := !h ^ I32.( >>> ) !h 13;
  h :=
    I32.( ++ )
      (I32.( * ) (!h & 65535L) 1540483477L)
      (I32.( * ) (!h >>> 16) (59797L << 16));

  !h ^ I32.( >>> ) !h 15

(* let murmur2 str =
   let h : Int64.t ref = ref 0L in
   let m = 0x5bd1e995 in
   let r = 24 in
   let len = String.length str in
   let rec loop i =
     if len >= 4 then begin
       let k =
         Char.code str.[i]
         lor (Char.code str.[i + 1] lsl 8)
         lor (Char.code str.[i + 2] lsl 16)
         lor (Char.code str.[i + 3] lsl 24)
       in
       let k =
         Int64.mul (Int64.logand k 0xffffL) m
         lor Int64.shift_left (Int64.mul (Int64.shift_right_logical k 16) m) 16
       in
       let k = Int64.logxor k (Int64.shift_right_logical k r) in
       let h' =
         Int64.mul (Int64.logand k 0xffffL) m
         lor Int64.shift_left (Int64.mul (Int64.shift_right_logical k 16) m) 16
       in
       h := Int64.logxor !h h';
       loop (i + 4)
     end
   in
   loop 0;
   begin
     match len with
     | 3 ->
         h :=
           Int64.logxor !h
             (Int64.shift_left (Int64.of_int (Char.code str.[len - 2])) 16)
     | 2 ->
         h :=
           Int64.logxor !h
             (Int64.shift_left (Int64.of_int (Char.code str.[len - 1])) 8)
     | 1 -> h := Int64.logxor !h (Int64.of_int (Char.code str.[len]))
     | _ -> ()
   end;
   h := Int64.logxor !h (Int64.shift_right_logical !h 13);
   h :=
     Int64.mul (Int64.logand !h 0xffffL) m
     lor Int64.shift_left (Int64.mul (Int64.shift_right_logical !h 16) m) 16;
   Int64.logxor !h (Int64.shift_right_logical !h 15)
*)

let make (str : string) =
  let hash = murmur2 str in
  to_css hash
