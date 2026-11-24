type intervalId = unit Lwt.t
type timeoutId = unit Lwt.t

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
  let hex_value = function
    | '0' .. '9' as c -> Char.code c - Char.code '0'
    | 'a' .. 'f' as c -> Char.code c - Char.code 'a' + 10
    | 'A' .. 'F' as c -> Char.code c - Char.code 'A' + 10
    | _ -> -1

  let hex_decode str pos =
    if pos + 2 >= String.length str then Error "Expecting Hex digit"
    else
      let first = hex_value (String.unsafe_get str (pos + 1)) in
      let second = hex_value (String.unsafe_get str (pos + 2)) in
      if first < 0 || second < 0 then Error "Invalid hex digit" else Ok ((first lsl 4) lor second)

  let is_uri_reserved c = Stdlib.String.contains ";/?:@&=+$,#" c

  let decode_uri ~component s =
    let buf = Buffer.create (String.length s) in
    let decode_utf8 pos char n c_min =
      let rec loop pos char n =
        if n <= 0 then Some (pos, char)
        else if pos >= String.length s || s.[pos] <> '%' then raise (Invalid_argument "Invalid hex encoding")
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
    loop 0

  let is_uri_unescaped c is_component =
    c < 0x100
    && ((c >= 0x61 && c <= 0x7a)
       || (c >= 0x41 && c <= 0x5a)
       || (c >= 0x30 && c <= 0x39)
       || Stdlib.String.contains "-_.!~*'()" (Char.chr c)
       || ((not is_component) && is_uri_reserved (Char.chr c)))

  let hex = "0123456789ABCDEF"

  (* JavaScript throws URIError for a lone surrogate, the only text it cannot
     encode; native strings are bytes, so invalid UTF-8 is the counterpart. *)
  let encode_uri ~component s =
    if not (Stdlib.String.is_valid_utf_8 s) then raise (Invalid_argument "URI malformed");
    let buf = Buffer.create (String.length s * 3) in
    String.iter
      (fun ch ->
        let c = Char.code ch in
        if is_uri_unescaped c component then Buffer.add_char buf ch
        else (
          Buffer.add_char buf '%';
          Buffer.add_char buf (String.unsafe_get hex (c lsr 4));
          Buffer.add_char buf (String.unsafe_get hex (c land 0x0f))))
      s;
    Buffer.contents buf
end

let encodeURI = URI.encode_uri ~component:false
let decodeURI = URI.decode_uri ~component:false
let encodeURIComponent = URI.encode_uri ~component:true
let decodeURIComponent = URI.decode_uri ~component:true
let parseFloat str = match Quickjs.Global.parse_float str with Some f -> f | None -> nan
let parseInt ?radix str = match Quickjs.Global.parse_int_float ?radix str with Some f -> f | None -> nan
