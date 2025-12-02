(** Contains functions available in the global scope ([window] in a browser context) *)

type intervalId
(** Identify an interval started by {! setInterval} *)

type timeoutId
(** Identify timeout started by {! setTimeout} *)

let clearInterval _intervalId = Js_internal.notImplemented "Js.Global" "clearInterval"
let clearTimeout _timeoutId = Js_internal.notImplemented "Js.Global" "clearTimeout"
let setInterval ~f:_ _ = Js_internal.notImplemented "Js.Global" "setInterval"
let setIntervalFloat ~f:_ _ = Js_internal.notImplemented "Js.Global" "setInterval"
let setTimeout ~f:_ _ = Js_internal.notImplemented "Js.Global" "setTimeout"
let setTimeoutFloat ~f:_ _ = Js_internal.notImplemented "Js.Global" "setTimeout"

module URI = struct
  let int_of_hex_opt str = try Some (Scanf.sscanf str "%x%!" (fun x -> x)) with _ -> None

  let hex_decode str pos =
    if pos + 2 >= String.length str then Error "Expecting Hex digit"
    else
      let first = int_of_hex_opt (Stdlib.String.sub str (pos + 1) 1) in
      let second = int_of_hex_opt (Stdlib.String.sub str (pos + 2) 1) in
      match (first, second) with
      | Some first, Some second -> Ok ((first lsl 4) lor second)
      | _ -> Error "Invalid hex digit"

  let is_uri_reserved c = Stdlib.String.contains ";/?:@&=+$,#" c

  let decode_uri ~component s =
    let buf = Buffer.create (String.length s) in
    let decode_utf8 pos char n c_min =
      let rec loop pos char n =
        if n <= 0 then Some (pos, char)
        else
          match hex_decode s pos with
          | Ok c1 when c1 land 0xc0 = 0x80 -> loop (pos + 3) ((char lsl 6) lor (c1 land 0x3f)) (n - 1)
          | _ -> raise (Invalid_argument "Invalid hex encoding")
      in
      match loop pos char n with
      | Some (new_pos, char) when char >= c_min && char <= 0x10FFFF && (char < 0xd800 || char >= 0xe000) ->
          (new_pos, char)
      | _ -> raise (Invalid_argument "Malformed UTF-8")
    in
    let rec loop pos =
      if pos >= String.length s then Buffer.contents buf
      else
        match Stdlib.String.get s pos with
        | '%' -> (
            match hex_decode s pos with
            | Ok hex when hex >= 0 ->
                if hex < 0x80 then
                  let c = Char.chr hex in
                  if (not component) && is_uri_reserved c then (
                    Buffer.add_char buf '%';
                    Buffer.add_string buf (Stdlib.String.sub s (pos + 1) 2);
                    loop (pos + 3))
                  else (
                    Buffer.add_char buf c;
                    loop (pos + 3))
                else
                  let new_pos, decoded_char =
                    if hex >= 0xc0 && hex <= 0xdf then decode_utf8 (pos + 3) (hex land 0x1f) 1 0x80
                    else if hex >= 0xe0 && hex <= 0xef then decode_utf8 (pos + 3) (hex land 0x0f) 2 0x800
                    else if hex >= 0xf0 && hex <= 0xf7 then decode_utf8 (pos + 3) (hex land 0x07) 3 0x10000
                    else raise (Invalid_argument "Invalid UTF-8 start byte")
                  in
                  Buffer.add_utf_8_uchar buf (Uchar.of_int decoded_char);
                  loop new_pos
            | _ -> raise (Invalid_argument "Invalid hex encoding"))
        | c ->
            Buffer.add_char buf c;
            loop (pos + 1)
    in
    try loop 0 with error -> raise error

  let is_uri_unescaped c is_component =
    c < 0x100
    && ((c >= 0x61 && c <= 0x7a)
       || (c >= 0x41 && c <= 0x5a)
       || (c >= 0x30 && c <= 0x39)
       || Stdlib.String.contains "-_.!~*'()" (Char.chr c)
       || ((not is_component) && is_uri_reserved (Char.chr c)))

  let hex_of_int_opt c =
    let char_code = if c < 10 then Char.code '0' + c else Char.code 'A' + (c - 10) in
    try Some (Char.chr char_code) with _ -> None

  let encode_hex value =
    let first_digit = hex_of_int_opt (value lsr 4) in
    let second_digit = hex_of_int_opt (value land 0x0F) in
    match (first_digit, second_digit) with
    | Some first_digit, Some second_digit -> Ok (Printf.sprintf "%%%c%c" first_digit second_digit)
    | _ -> Error (Printf.sprintf "Invalid hex encoding: %d" value)

  let uri_char_escaped c =
    match c with
    | '\'' -> "'" (* treat single quote as a regular character *)
    | c ->
        (* use Char.escaped for other special characters that need escaping *)
        let escaped = Char.escaped c in
        if c = '\\' then Stdlib.String.sub escaped 1 (String.length escaped - 1) else escaped

  let encode_uri ~component s =
    let buf = Buffer.create (String.length s * 3) in
    let rec loop pos =
      if pos >= String.length s then Buffer.contents buf
      else
        let new_pos, encoded_char =
          let c = Char.code (Stdlib.String.get s pos) in
          let new_pos = pos + 1 in
          if is_uri_unescaped c component then
            let encoded_char =
              try Ok (Char.chr c |> uri_char_escaped) with _ -> raise (Invalid_argument "invalid character")
            in
            (new_pos, encoded_char)
          else if c >= 0xdc00 && c <= 0xdfff then raise (Invalid_argument "invalid character")
          else if c >= 0xd800 && c <= 0xdbff then (
            if new_pos >= String.length s then raise (Invalid_argument "expecting surrogate pair");
            let c1 = Char.code (Stdlib.String.get s new_pos) in
            if c1 < 0xdc00 || c1 > 0xdfff then raise (Invalid_argument "expecting surrogate pair");
            let c = (((c land 0x3ff) lsl 10) lor (c1 land 0x3ff)) + 0x10000 in
            (new_pos + 1, encode_hex c))
          else (new_pos, encode_hex c)
        in

        match encoded_char with
        | Ok encoded_char ->
            Buffer.add_string buf encoded_char;
            loop new_pos
        | Error msg -> raise (Invalid_argument msg)
    in
    loop 0
end

let encodeURI = URI.encode_uri ~component:false
let decodeURI = URI.decode_uri ~component:false
let encodeURIComponent = URI.encode_uri ~component:true
let decodeURIComponent = URI.decode_uri ~component:true

let is_js_whitespace c =
  (* JavaScript whitespace characters per ECMAScript spec *)
  match c with
  | '\x09' (* Tab *)
  | '\x0A' (* Line feed *)
  | '\x0B' (* Vertical tab *)
  | '\x0C' (* Form feed *)
  | '\x0D' (* Carriage return *)
  | '\x20' (* Space *)
  | '\xA0' (* No-break space (Latin-1 encoded) *) ->
      true
  | _ -> false

let strip_leading_js_whitespace str =
  (* Strip leading JavaScript whitespace from string *)
  let len = String.length str in
  let rec find_start i =
    if i >= len then len
    else
      let c = String.get str i in
      if is_js_whitespace c then find_start (i + 1)
      else if c = '\xC2' && i + 1 < len && String.get str (i + 1) = '\xA0' then
        (* UTF-8 encoded non-breaking space U+00A0 *)
        find_start (i + 2)
      else if c = '\xEF' && i + 2 < len && String.get str (i + 1) = '\xBB' && String.get str (i + 2) = '\xBF' then
        (* UTF-8 BOM *)
        find_start (i + 3)
      else i
  in
  let start = find_start 0 in
  if start >= len then "" else String.sub str start (len - start)

let parseFloat str =
  (* JavaScript's parseFloat behavior:
     - Skip leading whitespace (JS whitespace, not just ASCII)
     - Parse as much as valid number as possible
     - Return NaN if no valid number at start *)
  let trimmed = strip_leading_js_whitespace str in
  match Quickjs.Global.parse_float trimmed with Some f -> f | None -> nan

let parseInt ?radix str =
  (* JavaScript's parseInt behavior:
     - Skip leading whitespace (JS whitespace, not just ASCII)
     - Auto-detect hex from 0x/0X prefix when radix not specified
     - Does NOT accept 0o/0b prefixes (unlike ES6 literals)
     - Parse as much as valid number as possible
     - Return NaN if no valid number at start *)
  let trimmed = strip_leading_js_whitespace str in
  let radix =
    match radix with
    | Some r -> Some r
    | None ->
        (* Check for 0x/0X prefix for hex auto-detection *)
        let len = String.length trimmed in
        if len >= 2 then
          let first = String.get trimmed 0 in
          let second = String.get trimmed 1 in
          if first = '0' && (second = 'x' || second = 'X') then Some 16
          else if (first = '-' || first = '+') && len >= 3 then
            let third = String.get trimmed 2 in
            if String.get trimmed 1 = '0' && (third = 'x' || third = 'X') then Some 16 else None
          else None
        else None
  in
  match Quickjs.Global.parse_int ?radix trimmed with Some i -> Float.of_int i | None -> nan
