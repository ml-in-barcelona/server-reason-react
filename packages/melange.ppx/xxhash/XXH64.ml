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

let hash2 input =
  let len = String.length input in
  let seed = ULLong.of_int64 0L in
  let h =
    if len >= 32 then
      let v1 = ULLong.add seed prime1 in
      let v2 = ULLong.add seed prime2 in
      let v3 = ULLong.add seed prime3 in
      let v4 = ULLong.add seed prime4 in
      let rec loop i v1 v2 v3 v4 =
        if i <= len - 32 then
          let p1 = String.sub input i 8 |> string_to_uint64 in
          let p2 = String.sub input (i + 8) 8 |> string_to_uint64 in
          let p3 = String.sub input (i + 16) 8 |> string_to_uint64 in
          let p4 = String.sub input (i + 24) 8 |> string_to_uint64 in
          loop (i + 32) (mix1 v1 p1) (mix1 v2 p2) (mix1 v3 p3) (mix1 v4 p4)
        else (v1, v2, v3, v4)
      in
      let v1, v2, v3, v4 = loop 0 v1 v2 v3 v4 in
      let h = ULLong.add (rotl v1 1) (rotl v2 7) in
      let h = ULLong.add h (rotl v3 12) in
      ULLong.add h (rotl v4 18)
    else ULLong.add seed prime5
  in
  let h = ULLong.add h (ULLong.of_int len) in
  let rec process_remaining i h =
    if i <= len - 8 then
      let p = String.sub input i 8 |> string_to_uint64 in
      process_remaining (i + 8) (mix2 h p)
    else h
  in
  let h = process_remaining 0 h in
  let rec process_final i h =
    if i < len then
      let p = ULLong.of_int (Char.code (String.get input i)) in
      process_final (i + 1) (ULLong.add h (ULLong.mul p prime5))
    else h
  in
  finalize (process_final 0 h)

let hash a =
  try hash2 a
  with err ->
    Printf.eprintf "Error";
    Printf.eprintf "Error: %s\n" (Printexc.to_string err);
    failwith "Error in hash function"

let to_hex hash = ULLong.to_hexstring hash

let hash_for_filename bytes =
  String.sub (Base32.encode_string (Bytes.to_string bytes)) 0 8

let sum hex_str =
  (* Convert hexadecimal string to Int64 *)
  let int64_value = Int64.of_string ("0x" ^ hex_str) in

  (* Create an 8-byte buffer *)
  let bytes = Bytes.create 8 in

  (* Fill the buffer with the bytes of the Int64 value *)
  for i = 0 to 7 do
    let byte =
      Int64.(to_int (shift_right_logical int64_value (8 * (7 - i)))) land 0xFF
    in
    Bytes.set bytes i (char_of_int byte)
  done;

  bytes

let full content =
  let hash = hash content in
  let b = sum (to_hex hash) in
  hash_for_filename b
