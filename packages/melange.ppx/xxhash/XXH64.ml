module ULLong = Unsigned.ULLong

let prime1 = ULLong.of_int64 0x9E3779B185EBCA87L
let prime2 = ULLong.of_int64 0xC2B2AE3D27D4EB4FL
let prime3 = Unsigned.ULLong.of_int64 0x165667B19E3779F9L
let prime4 = Unsigned.ULLong.of_int64 0x85EBCA77C2B2AE63L
let prime5 = Unsigned.ULLong.of_int64 0x27D4EB2F165667C5L

let rotl x r =
  ULLong.logor (ULLong.shift_left x r) (ULLong.shift_right x (64 - r))

let mix1 v p =
  let v = ULLong.add v (ULLong.mul p prime2) in
  let v = rotl v 31 in
  ULLong.mul v prime1

let mix2 v p =
  let v = ULLong.add v p in
  let v = rotl v 27 in
  ULLong.add (ULLong.mul v prime1) prime4

let finalize h =
  let h = ULLong.logxor h (ULLong.shift_right h 33) in
  let h = ULLong.mul h prime2 in
  let h = ULLong.logxor h (ULLong.shift_right h 29) in
  let h = ULLong.mul h prime3 in
  ULLong.logxor h (ULLong.shift_right h 32)

let string_to_uint64 input =
  let len = String.length input in
  let num_bytes = min len 8 in
  let value = ref ULLong.zero in
  for i = 0 to num_bytes - 1 do
    value :=
      ULLong.logor
        (ULLong.shift_left !value 8)
        (ULLong.of_int (Char.code input.[i]))
  done;
  !value

(* https://github.com/Cyan4973/xxHash/blob/dev/doc/xxhash_spec.md#xxh64-algorithm-description *)

let ( += ) r v = r := !r + v

let ( <<< ) x n =
  let a = Int64.shift_left x n in
  let b = Int64.shift_right_logical x (64 - n) in
  Int64.logor a b

let ( >> ) = Int64.shift_right_logical
let ( + ) = Int64.add
let ( * ) = Int64.mul
let ( - ) = Int64.sub
let prime64_1 = 0x9E3779B185EBCA87L
(* 0b1001111000110111011110011011000110000101111010111100101010000111 *)

let prime64_2 = 0xC2B2AE3D27D4EB4FL
(* 0b1100001010110010101011100011110100100111110101001110101101001111 *)

let prime64_3 = 0x165667B19E3779F9L
(* 0b0001011001010110011001111011000110011110001101110111100111111001 *)

let prime64_4 = 0x85EBCA77C2B2AE63L
(* 0b1000010111101011110010100111011111000010101100101010111001100011 *)

let prime64_5 = 0x27D4EB2F165667C5L
(* 0b0010011111010100111010110010111100010110010101100110011111000101 *)

(*
round(accN,laneN):
  accN = accN + (laneN * PRIME64_2);
  accN = accN <<< 31;
  return accN * PRIME64_1;
*)
let round acc lane = (acc + (lane * prime64_2) <<< 31) * prime64_1

let hash ?(seed = Int64.zero) input =
  let len = String.length input in
  let pos = ref 0 in
  let have n = Int.add !pos n <= len in
  let acc =
    if len < 32 then seed + prime64_5
    else
      let acc1 = ref @@ (seed + prime64_1 + prime64_2) in
      let acc2 = ref @@ (seed + prime64_2) in
      let acc3 = ref @@ seed in
      let acc4 = ref @@ (seed - prime64_1) in

      while have 32 do
        acc1 := round !acc1 (String.get_int64_le input !pos);
        pos += 8;
        acc2 := round !acc2 (String.get_int64_le input !pos);
        pos += 8;
        acc3 := round !acc3 (String.get_int64_le input !pos);
        pos += 8;
        acc4 := round !acc4 (String.get_int64_le input !pos);
        pos += 8
      done;

      (*
    mergeAccumulator(acc,accN):
      acc  = acc xor round(0, accN);
      acc  = acc * PRIME64_1;
      return acc + PRIME64_4;
      acc = (acc1 <<< 1) + (acc2 <<< 7) + (acc3 <<< 12) + (acc4 <<< 18);
      acc = mergeAccumulator(acc, acc1);
      acc = mergeAccumulator(acc, acc2);
      acc = mergeAccumulator(acc, acc3);
      acc = mergeAccumulator(acc, acc4);
    *)
      let merge accN acc =
        (Int64.logxor acc (round Int64.zero !accN) * prime64_1) + prime64_4
      in
      let acc =
        (!acc1 <<< 1) + (!acc2 <<< 7) + (!acc3 <<< 12) + (!acc4 <<< 18)
      in
      acc |> merge acc1 |> merge acc2 |> merge acc3 |> merge acc4
  in

  let acc = ref @@ (acc + Int64.of_int len) in

  while have 8 do
    let lane = String.get_int64_le input !pos in
    acc :=
      ((Int64.logxor !acc (round Int64.zero lane) <<< 27) * prime64_1)
      + prime64_4;
    pos += 8
  done;

  while have 4 do
    let lane =
      (* TODO unsigned *) Int64.of_int32 @@ String.get_int32_le input !pos
    in
    acc :=
      ((Int64.logxor !acc (lane * prime64_1) <<< 23) * prime64_2) + prime64_3;
    pos += 4
  done;

  while have 1 do
    let lane =
      (* unsigned *) Int64.of_int @@ Char.code @@ String.get input !pos
    in
    acc := (Int64.logxor !acc (lane * prime64_5) <<< 11) * prime64_1;
    pos += 1
  done;

  let acc = Int64.logxor !acc (!acc >> 33) in
  let acc = acc * prime64_2 in
  let acc = Int64.logxor acc (acc >> 29) in
  let acc = acc * prime64_3 in
  Int64.logxor acc (acc >> 32)

let to_hex hash = Printf.sprintf "%Lx" hash
