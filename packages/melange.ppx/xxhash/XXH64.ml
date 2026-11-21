module UInt64 = Unsigned.UInt64

let ( += ) r v = r := !r + v
let ( -= ) r v = r := !r - v

let ( <<< ) x n =
  let a = UInt64.shift_left x n in
  let b = UInt64.shift_right x (64 - n) in
  UInt64.logor a b

let ( >> ) = UInt64.shift_right
let ( + ) = UInt64.add
let ( * ) = UInt64.mul
let ( - ) = UInt64.sub
let logxor = UInt64.logxor
let prime64_1 = UInt64.of_int64 0x9E3779B185EBCA87L
let prime64_2 = UInt64.of_int64 0xC2B2AE3D27D4EB4FL
let prime64_3 = UInt64.of_int64 0x165667B19E3779F9L
let prime64_4 = UInt64.of_int64 0x85EBCA77C2B2AE63L
let prime64_5 = UInt64.of_int64 0x27D4EB2F165667C5L
let round acc lane = (acc + (lane * prime64_2) <<< 31) * prime64_1
let get_int64_le str i = UInt64.of_int64 (String.get_int64_le str i)
let merge accN acc = (logxor acc (round UInt64.zero !accN) * prime64_1) + prime64_4

let hash ?(seed = Int64.zero) input =
  let seed = UInt64.of_int64 seed in
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
        acc1 := round !acc1 (get_int64_le input !pos);
        pos += 8;
        acc2 := round !acc2 (get_int64_le input !pos);
        pos += 8;
        acc3 := round !acc3 (get_int64_le input !pos);
        pos += 8;
        acc4 := round !acc4 (get_int64_le input !pos);
        pos += 8
      done;

      let acc = (!acc1 <<< 1) + (!acc2 <<< 7) + (!acc3 <<< 12) + (!acc4 <<< 18) in
      acc |> merge acc1 |> merge acc2 |> merge acc3 |> merge acc4
  in

  let acc = ref @@ (acc + UInt64.of_int len) in

  while have 8 do
    let lane = get_int64_le input !pos in
    acc := ((logxor !acc (round UInt64.zero lane) <<< 27) * prime64_1) + prime64_4;
    pos += 8
  done;

  if have 4 then (
    let lane =
      UInt64.logand (UInt64.of_int64 0xFF_FF_FF_FFL)
      @@ (String.get_int32_le input !pos |> Int64.of_int32 |> UInt64.of_int64)
    in
    acc := ((logxor !acc (lane * prime64_1) <<< 23) * prime64_2) + prime64_3;
    pos += 4)
  else ();

  while have 1 do
    let lane = UInt64.of_int @@ Char.code @@ String.get input !pos in
    acc := (logxor !acc (lane * prime64_5) <<< 11) * prime64_1;
    pos += 1
  done;

  let acc = logxor !acc (!acc >> 33) in
  let acc = acc * prime64_2 in
  let acc = logxor acc (acc >> 29) in
  let acc = acc * prime64_3 in
  UInt64.to_int64 (logxor acc (acc >> 32))

let to_hex hash = Printf.sprintf "%Lx" hash
