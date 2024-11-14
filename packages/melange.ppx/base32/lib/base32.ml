(*
 * Copyright (c) 2006-2009 Citrix Systems Inc.
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.com>
 * Copyright (c) 2014-2016 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2016 David Kaloper Meršinjak
 * Copyright (c) 2018 Romain Calascibetta <romain.calascibetta@gmail.com>
 * Copyright (c) 2021 pukkamustard <pukkamustard@posteo.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS  OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

type alphabet = { emap : int array; dmap : int array }
type sub = string * int * int

let ( // ) x y =
  if y < 1 then raise Division_by_zero;
  if x > 0 then 1 + ((x - 1) / y) else 0
[@@inline]

let unsafe_get_uint8 input off = String.unsafe_get input off |> Char.code
let unsafe_set_uint8 input off v = v |> Char.chr |> Bytes.unsafe_set input off
let none = -1

(* We mostly want to have an optional array for [dmap] (e.g. [int option
   array]). So we consider the [none] value as [-1]. *)

let make_alphabet alphabet =
  if String.length alphabet <> 32 then invalid_arg "Length of alphabet must be 32";
  if String.contains alphabet '=' then invalid_arg "Alphabet can not contain padding character";
  let emap = Array.init (String.length alphabet) (fun i -> Char.code alphabet.[i]) in
  let dmap = Array.make 256 none in
  String.iteri (fun idx chr -> dmap.(Char.code chr) <- idx) alphabet;
  { emap; dmap }

let length_alphabet { emap; _ } = Array.length emap
let alphabet { emap; _ } = emap
let default_alphabet = make_alphabet "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
let padding = int_of_char '='
let error_msgf fmt = Format.ksprintf (fun err -> Error (`Msg err)) fmt

let encode_sub pad { emap; _ } ?(off = 0) ?len input =
  let len = match len with Some len -> len | None -> String.length input - off in

  if len < 0 || off < 0 || off > String.length input - len then error_msgf "Invalid bounds"
  else
    let n = len in
    let n' = n // 5 * 8 in
    let res = Bytes.make n' (Char.chr 0) in

    let emap i = Array.unsafe_get emap i in

    (* the bit magic - takes 5 bytes and reads 5-bits at a time *)
    let emit b1 b2 b3 b4 b5 i =
      unsafe_set_uint8 res i (emap ((0b11111000 land b1) lsr 3));
      unsafe_set_uint8 res (i + 1) (emap (((0b00000111 land b1) lsl 2) lor ((0b11000000 land b2) lsr 6)));
      unsafe_set_uint8 res (i + 2) (emap ((0b00111110 land b2) lsr 1));
      unsafe_set_uint8 res (i + 3) (emap (((0b00000001 land b2) lsl 4) lor ((0b11110000 land b3) lsr 4)));
      unsafe_set_uint8 res (i + 4) (emap (((0b00001111 land b3) lsl 1) lor ((0b10000000 land b4) lsr 7)));
      unsafe_set_uint8 res (i + 5) (emap ((0b01111100 land b4) lsr 2));
      unsafe_set_uint8 res (i + 6) (emap (((0b00000011 land b4) lsl 3) lor ((0b11100000 land b5) lsr 5)));
      unsafe_set_uint8 res (i + 7) (emap (0b00011111 land b5))
    in

    let rec enc j i =
      if i = len then ()
      else if i = n - 1 then emit (unsafe_get_uint8 input (off + i)) 0 0 0 0 j
      else if i = n - 2 then emit (unsafe_get_uint8 input (off + i)) (unsafe_get_uint8 input (off + i + 1)) 0 0 0 j
      else if i = n - 3 then
        emit
          (unsafe_get_uint8 input (off + i))
          (unsafe_get_uint8 input (off + i + 1))
          (unsafe_get_uint8 input (off + i + 2))
          0 0 j
      else if i = n - 4 then
        emit
          (unsafe_get_uint8 input (off + i))
          (unsafe_get_uint8 input (off + i + 1))
          (unsafe_get_uint8 input (off + i + 2))
          (unsafe_get_uint8 input (off + i + 3))
          0 j
      else (
        emit
          (unsafe_get_uint8 input (off + i))
          (unsafe_get_uint8 input (off + i + 1))
          (unsafe_get_uint8 input (off + i + 2))
          (unsafe_get_uint8 input (off + i + 3))
          (unsafe_get_uint8 input (off + i + 4))
          j;
        enc (j + 8) (i + 5))
    in

    let rec unsafe_fix = function
      | 0 -> ()
      | i ->
          unsafe_set_uint8 res (n' - i) padding;
          unsafe_fix (i - 1)
    in

    enc 0 0;

    (* amount of padding required *)
    let pad_to_write = match n mod 5 with 0 -> 0 | 1 -> 6 | 2 -> 4 | 3 -> 3 | 4 -> 1 | _ -> 0 in

    if pad then (
      unsafe_fix pad_to_write;
      Ok (Bytes.unsafe_to_string res, 0, n'))
    else Ok (Bytes.unsafe_to_string res, 0, n' - pad_to_write)

let encode ?(pad = true) ?(alphabet = default_alphabet) ?off ?len input =
  match encode_sub pad alphabet ?off ?len input with
  | Ok (res, off, len) -> Ok (String.sub res off len)
  | Error _ as err -> err

let encode_string ?pad ?alphabet input =
  match encode ?pad ?alphabet input with Ok res -> res | Error _ -> assert false

let encode_sub ?(pad = true) ?(alphabet = default_alphabet) ?off ?len input = encode_sub pad alphabet ?off ?len input

let encode_exn ?pad ?alphabet ?off ?len input =
  match encode ?pad ?alphabet ?off ?len input with Ok v -> v | Error (`Msg err) -> invalid_arg err

let decode_sub { dmap; _ } ?(off = 0) ?len input =
  let len = match len with Some len -> len | None -> String.length input - off in

  if len < 0 || off < 0 || off > String.length input - len then error_msgf "Invalid bounds"
  else
    let n = len // 8 * 8 in
    let n' = n // 8 * 5 in
    let res = Bytes.create n' in

    let get_uint8 t i = if i < len then Char.code (String.unsafe_get t (off + i)) else padding in

    let set_uint8 t off v =
      (* Format.printf "set_uint8 %d\n" (v land 0xff); *)
      if off < 0 || off >= Bytes.length t then () else unsafe_set_uint8 t off (v land 0xff)
    in

    let emit b0 b1 b2 b3 b4 b5 b6 b7 j =
      set_uint8 res j ((b0 lsl 3) lor (b1 lsr 2));
      set_uint8 res (j + 1) ((b1 lsl 6) lor (b2 lsl 1) lor (b3 lsr 4));
      set_uint8 res (j + 2) ((b3 lsl 4) lor (b4 lsr 1));
      set_uint8 res (j + 3) ((b4 lsl 7) lor (b5 lsl 2) lor (b6 lsr 3));
      set_uint8 res (j + 4) ((b6 lsl 5) lor b7)
    in

    let dmap i = Array.unsafe_get dmap i in

    let get_uint8_with_padding t i padding =
      let x = get_uint8 t i in
      if x = 61 then (0, padding)
      else
        let v = dmap x in
        if v >= 0 then (v, 0) else raise Not_found
    in

    let rec dec j i =
      if i = n then 0
      else
        let b0, pad0 = get_uint8_with_padding input i 5 in
        let b1, pad1 = get_uint8_with_padding input (i + 1) 5 in
        let b2, pad2 = get_uint8_with_padding input (i + 2) 4 in
        let b3, pad3 = get_uint8_with_padding input (i + 3) 4 in
        let b4, pad4 = get_uint8_with_padding input (i + 4) 3 in
        let b5, pad5 = get_uint8_with_padding input (i + 5) 2 in
        let b6, pad6 = get_uint8_with_padding input (i + 6) 2 in
        let b7, pad7 = get_uint8_with_padding input (i + 7) 1 in
        let pad = List.fold_left max 0 [ pad0; pad1; pad2; pad3; pad4; pad5; pad6; pad7 ] in

        (* Format.printf "emit %d %d %d %d %d %d %d %d\n" b0 b1 b2 b3 b4 b5 b6 b7; *)
        emit b0 b1 b2 b3 b4 b5 b6 b7 j;
        if pad == 0 then dec (j + 5) (i + 8) else pad
    in

    match dec 0 0 with
    | pad -> Ok (Bytes.unsafe_to_string res, 0, n' - pad)
    | exception Not_found -> error_msgf "Malformed input"

let decode ?(alphabet = default_alphabet) ?off ?len input =
  match decode_sub alphabet ?off ?len input with
  | Ok (res, off, len) -> Ok (String.sub res off len)
  | Error _ as err -> err

let decode_sub ?(alphabet = default_alphabet) ?off ?len input = decode_sub alphabet ?off ?len input

let decode_exn ?alphabet ?off ?len input =
  match decode ?alphabet ?off ?len input with Ok res -> res | Error (`Msg err) -> invalid_arg err
