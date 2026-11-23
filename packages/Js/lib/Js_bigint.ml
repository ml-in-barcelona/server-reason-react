type t = Z.t

let of_int = Z.of_int
let of_int64 = Z.of_int64
let is_whitespace c = c = ' ' || c = '\t' || c = '\n' || c = '\r'

let trim s =
  let len = String.length s in
  let i = ref 0 in
  while !i < len && is_whitespace (String.get s !i) do
    incr i
  done;
  let j = ref (len - 1) in
  while !j >= !i && is_whitespace (String.get s !j) do
    decr j
  done;
  if !i > !j then "" else String.sub s !i (!j - !i + 1)

let is_valid_for_base s base start_idx =
  let valid_char c =
    match base with
    | 2 -> c = '0' || c = '1'
    | 8 -> c >= '0' && c <= '7'
    | 10 -> c >= '0' && c <= '9'
    | 16 -> (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
    | _ -> false
  in
  let len = String.length s in
  if start_idx >= len then false
  else
    let result = ref true in
    for i = start_idx to len - 1 do
      if not (valid_char (String.get s i)) then result := false
    done;
    !result

let of_string_exn s =
  let s = trim s in
  let len = String.length s in
  if len = 0 then failwith "BigInt: cannot convert empty string";
  if s = "+" || s = "-" then failwith "BigInt: cannot convert sign-only string";
  if String.contains s '\x00' then failwith "BigInt: invalid character";
  let negative = len > 0 && String.get s 0 = '-' in
  let has_sign = len > 0 && (String.get s 0 = '-' || String.get s 0 = '+') in
  let start = if has_sign then 1 else 0 in
  if start >= len then failwith "BigInt: invalid format";
  let has_prefix =
    len > start + 1
    && String.get s start = '0'
    &&
    let c = String.get s (start + 1) in
    c = 'x' || c = 'X' || c = 'b' || c = 'B' || c = 'o' || c = 'O'
  in
  let base, num_start =
    if has_prefix then
      let c = String.get s (start + 1) in
      match c with
      | 'x' | 'X' -> (16, start + 2)
      | 'b' | 'B' -> (2, start + 2)
      | 'o' | 'O' -> (8, start + 2)
      | _ -> (10, start)
    else (10, start)
  in
  if num_start >= len then failwith "BigInt: missing digits after prefix";
  if not (is_valid_for_base s base num_start) then failwith "BigInt: invalid characters for base";
  let num_str = String.sub s num_start (len - num_start) in
  let abs_value = Z.of_string_base base num_str in
  if negative then Z.neg abs_value else abs_value

let of_string s =
  let s = trim s in
  if String.length s = 0 then Z.zero else try of_string_exn s with Failure _ -> Z.zero

let digit_to_char d = if d < 10 then Char.chr (d + Char.code '0') else Char.chr (d - 10 + Char.code 'a')

let to_string ?(radix = 10) n =
  if radix < 2 || radix > 36 then invalid_arg "to_string: radix must be between 2 and 36";
  if radix = 10 then Z.to_string n
  else if Z.equal n Z.zero then "0"
  else
    let negative = Z.sign n < 0 in
    let n = Z.abs n in
    let radix_z = Z.of_int radix in
    let buf = Buffer.create 64 in
    let rec loop n =
      if Z.equal n Z.zero then ()
      else
        let q, r = Z.div_rem n radix_z in
        Buffer.add_char buf (digit_to_char (Z.to_int r));
        loop q
    in
    loop n;
    if negative then Buffer.add_char buf '-';
    let s = Buffer.contents buf in
    let len = String.length s in
    String.init len (fun i -> String.get s (len - 1 - i))

let toString = to_string ~radix:10
let to_float = Z.to_float
let neg = Z.neg
let abs = Z.abs
let add = Z.add
let sub = Z.sub
let mul = Z.mul
let div a b = if Z.equal b Z.zero then raise Division_by_zero else Z.div a b
let rem a b = if Z.equal b Z.zero then raise Division_by_zero else Z.rem a b

let pow base exp =
  if Z.sign exp < 0 then invalid_arg "BigInt.pow: negative exponent"
  else
    let exp_int = Z.to_int exp in
    Z.pow base exp_int

let logand = Z.logand
let logor = Z.logor
let logxor = Z.logxor
let lognot = Z.lognot
let shift_left = Z.shift_left
let shift_right = Z.shift_right

let compare a b =
  let c = Z.compare a b in
  if c < 0 then -1 else if c > 0 then 1 else 0

let equal = Z.equal
let lt a b = Z.compare a b < 0
let le a b = Z.compare a b <= 0
let gt a b = Z.compare a b > 0
let ge a b = Z.compare a b >= 0

let as_uint_n bits x =
  if bits = 0 then Z.zero
  else
    let modulus = Z.shift_left Z.one bits in
    Z.erem x modulus

let as_int_n bits x =
  if bits = 0 then Z.zero
  else
    let modulus = Z.shift_left Z.one bits in
    let half = Z.shift_left Z.one (bits - 1) in
    let wrapped = Z.erem x modulus in
    if Z.compare wrapped half >= 0 then Z.sub wrapped modulus else wrapped

let asIntN ~precision x = as_int_n precision x
let asUintN ~precision x = as_uint_n precision x

type toLocaleStringOptions = { style : string; currency : string }

let toLocaleString ~locale:_ ?options:_ x = toString x
let make _ = Js_internal.notImplemented "Js.Bigint" "make"
