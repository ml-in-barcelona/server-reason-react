(** Contains functions available in the global scope ([window] in a browser context) *)

(* Timers are scheduled on the Lwt event loop: callbacks only fire while an
   Lwt main loop is running (Lwt_main.run, Dream, etc.), which every
   server-reason-react deployment does. Like node, an exception raised inside
   a timer callback reaches Lwt.async_exception_hook and terminates the
   process by default. JS timers clamp negative delays to 0. *)

type intervalId = unit Lwt.t
(** Identify an interval started by {! setInterval} *)

type timeoutId = unit Lwt.t
(** Identify timeout started by {! setTimeout} *)

let sleep_seconds_of_millis millis = if millis <= 0. then 0. else millis /. 1000.

let start_timeout ~f millis : timeoutId =
  let task =
    let%lwt () = Lwt_unix.sleep (sleep_seconds_of_millis millis) in
    f ();
    Lwt.return_unit
  in
  Lwt.async (fun () -> Lwt.catch (fun () -> task) (function Lwt.Canceled -> Lwt.return_unit | exn -> raise exn));
  task

let start_interval ~f millis : intervalId =
  let delay = sleep_seconds_of_millis millis in
  let rec loop () =
    let%lwt () = Lwt_unix.sleep delay in
    f ();
    loop ()
  in
  let task = loop () in
  Lwt.async (fun () -> Lwt.catch (fun () -> task) (function Lwt.Canceled -> Lwt.return_unit | exn -> raise exn));
  task

let clearInterval (intervalId : intervalId) = Lwt.cancel intervalId
let clearTimeout (timeoutId : timeoutId) = Lwt.cancel timeoutId
let setInterval ~f millis : intervalId = start_interval ~f (Stdlib.float_of_int millis)
let setIntervalFloat ~f millis : intervalId = start_interval ~f millis
let setTimeout ~f millis : timeoutId = start_timeout ~f (Stdlib.float_of_int millis)
let setTimeoutFloat ~f millis : timeoutId = start_timeout ~f millis

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
let parseFloat str = match Quickjs.Global.parse_float str with Some f -> f | None -> nan
let parseInt ?radix str = match Quickjs.Global.parse_int_float ?radix str with Some f -> f | None -> nan
