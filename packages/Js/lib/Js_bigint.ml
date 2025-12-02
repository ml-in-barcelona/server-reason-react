(** Provide utilities for bigint *)

type t = Z.t

(* {1 Constructors} *)

let of_int = Z.of_int
let of_int64 = Z.of_int64

(* Helper to check if a character is whitespace *)
let is_whitespace c = c = ' ' || c = '\t' || c = '\n' || c = '\r'

(* Trim whitespace from both ends of a string *)
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

(* Check if string contains only valid chars for given base, after sign *)
let is_valid_for_base s base start_idx =
  let valid_char c =
    match base with
    | 2 -> c = '0' || c = '1'
    | 8 -> c >= '0' && c <= '7'
    | 10 -> c >= '0' && c <= '9'
    | 16 ->
        (c >= '0' && c <= '9')
        || (c >= 'a' && c <= 'f')
        || (c >= 'A' && c <= 'F')
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

(* Parse string with JS BigInt semantics (strict version that raises) *)
let of_string_exn s =
  let s = trim s in
  let len = String.length s in
  if len = 0 then failwith "BigInt: cannot convert empty string";
  (* Check for sign-only strings *)
  if s = "+" || s = "-" then failwith "BigInt: cannot convert sign-only string";
  (* Check for null character *)
  if String.contains s '\x00' then failwith "BigInt: invalid character";
  (* Check for decimal point or scientific notation *)
  if String.contains s '.' then failwith "BigInt: cannot have decimal point";
  if String.contains s 'e' || String.contains s 'E' then
    failwith "BigInt: cannot use scientific notation";
  (* Determine sign and starting position *)
  let negative = len > 0 && String.get s 0 = '-' in
  let has_sign = len > 0 && (String.get s 0 = '-' || String.get s 0 = '+') in
  let start = if has_sign then 1 else 0 in
  if start >= len then failwith "BigInt: invalid format";
  (* Check for radix prefix *)
  let has_prefix =
    len > start + 1
    && String.get s start = '0'
    && (let c = String.get s (start + 1) in
        c = 'x' || c = 'X' || c = 'b' || c = 'B' || c = 'o' || c = 'O')
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
  (* Validate the numeric part *)
  if num_start >= len then failwith "BigInt: missing digits after prefix";
  if not (is_valid_for_base s base num_start) then
    failwith "BigInt: invalid characters for base";
  (* Parse the number *)
  let num_str = String.sub s num_start (len - num_start) in
  let abs_value = Z.of_string_base base num_str in
  if negative then Z.neg abs_value else abs_value

(* Parse string with JS BigInt semantics (lenient version) *)
let of_string s =
  let s = trim s in
  if String.length s = 0 then Z.zero
  else
    try of_string_exn s
    with Failure _ ->
      (* For the lenient version, invalid strings just return 0 *)
      Z.zero

(* {1 Conversions} *)

(* Convert a digit to its character representation for bases up to 36 *)
let digit_to_char d =
  if d < 10 then Char.chr (d + Char.code '0')
  else Char.chr (d - 10 + Char.code 'a')

(* Convert BigInt to string with given radix *)
let to_string ?(radix = 10) n =
  if radix < 2 || radix > 36 then
    invalid_arg "to_string: radix must be between 2 and 36";
  if Z.equal n Z.zero then "0"
  else
    let negative = Z.sign n < 0 in
    let n = Z.abs n in
    let radix_z = Z.of_int radix in
    let buf = Buffer.create 64 in
    let rec loop n =
      if Z.equal n Z.zero then ()
      else begin
        let q, r = Z.div_rem n radix_z in
        Buffer.add_char buf (digit_to_char (Z.to_int r));
        loop q
      end
    in
    loop n;
    if negative then Buffer.add_char buf '-';
    (* Reverse the buffer contents *)
    let s = Buffer.contents buf in
    let len = String.length s in
    String.init len (fun i -> String.get s (len - 1 - i))

let toString = to_string ~radix:10
let to_float = Z.to_float

(* {1 Arithmetic operations} *)

let neg = Z.neg
let abs = Z.abs
let add = Z.add
let sub = Z.sub
let mul = Z.mul

(* Division truncating toward zero - this is what Z.div does *)
let div a b =
  if Z.equal b Z.zero then raise Division_by_zero else Z.div a b

(* Remainder with sign following dividend - this is what Z.rem does *)
let rem a b =
  if Z.equal b Z.zero then raise Division_by_zero else Z.rem a b

(* Power - raises on negative exponent *)
let pow base exp =
  if Z.sign exp < 0 then invalid_arg "BigInt.pow: negative exponent"
  else
    let exp_int = Z.to_int exp in
    Z.pow base exp_int

(* {1 Bitwise operations} *)

let logand = Z.logand
let logor = Z.logor
let logxor = Z.logxor
let lognot = Z.lognot
let shift_left = Z.shift_left
let shift_right = Z.shift_right

(* {1 Comparison operations} *)

let compare a b =
  let c = Z.compare a b in
  if c < 0 then -1 else if c > 0 then 1 else 0

let equal = Z.equal
let lt a b = Z.compare a b < 0
let le a b = Z.compare a b <= 0
let gt a b = Z.compare a b > 0
let ge a b = Z.compare a b >= 0

(* {1 Bit width conversion} *)

(* asUintN: wrap to unsigned n-bit integer *)
let as_uint_n bits x =
  if bits = 0 then Z.zero
  else
    let modulus = Z.shift_left Z.one bits in
    Z.erem x modulus

(* asIntN: wrap to signed n-bit integer *)
let as_int_n bits x =
  if bits = 0 then Z.zero
  else
    let modulus = Z.shift_left Z.one bits in
    let half = Z.shift_left Z.one (bits - 1) in
    let wrapped = Z.erem x modulus in
    (* If wrapped >= 2^(bits-1), subtract 2^bits to get negative *)
    if Z.compare wrapped half >= 0 then Z.sub wrapped modulus else wrapped
