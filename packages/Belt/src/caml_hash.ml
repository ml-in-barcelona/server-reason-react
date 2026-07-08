[@@@ocaml.text " "]

let ( << ) = Int32.shift_left [@@ocaml.text " "]

let ( >>> ) = Int32.shift_right_logical
let ( |~ ) = Int32.logor
let ( ^ ) = Int32.logxor
let ( *~ ) = Int32.mul
let ( +~ ) = Int32.add
let rotl32 (x : int32) n = x << n |~ (x >>> 32 - n)

let caml_hash_mix_int h d =
  let d = ref d in
  d := !d *~ 0xcc9e2d51l;
  d := rotl32 !d 15;
  d := !d *~ 0x1b873593l;
  let h = ref (h ^ !d) in
  h := rotl32 !h 13;
  !h +~ (!h << 2) +~ 0xe6546b64l

let caml_hash_final_mix h =
  let h = ref (h ^ (h >>> 16)) in
  h := !h *~ 0x85ebca6bl;
  h := !h ^ (!h >>> 13);
  h := !h *~ 0xc2b2ae35l;
  !h ^ (!h >>> 16)

let caml_hash_mix_string h s =
  let len = String.length s in
  let block = (len / 4) - 1 in
  let hash = ref h in
  for i = 0 to block do
    let j = 4 * i in
    let w =
      Char.code s.[j] lor (Char.code s.[j + 1] lsl 8) lor (Char.code s.[j + 2] lsl 16) lor (Char.code s.[j + 3] lsl 24)
    in
    hash := caml_hash_mix_int !hash (Int32.of_int w)
  done;
  let modulo = len land 3 in
  (if modulo <> 0 then
     let w =
       if modulo = 3 then (Char.code s.[len - 1] lsl 16) lor (Char.code s.[len - 2] lsl 8) lor Char.code s.[len - 3]
       else if modulo = 2 then (Char.code s.[len - 1] lsl 8) lor Char.code s.[len - 2]
       else Char.code s.[len - 1]
     in
     hash := caml_hash_mix_int !hash (Int32.of_int w));
  hash := !hash ^ Int32.of_int len;
  !hash
