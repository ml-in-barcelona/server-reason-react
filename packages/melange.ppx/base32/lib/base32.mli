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
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

(** Base32 RFC4648 implementation.

    Base32 is a group of similar binary-to-text encoding schemes that represent binary data in an ASCII string format by
    translating it into a radix-32 representation. It is specified in RFC 4648.

    {e Release %%VERSION%% - %%PKG_HOMEPAGE%%} *)

type alphabet

type sub = string * int * int
(** Type of sub-string: [str, off, len]. *)

val default_alphabet : alphabet
(** A 32-character alphabet specifying the regular Base32 alphabet. *)

val make_alphabet : string -> alphabet
val length_alphabet : alphabet -> int
val alphabet : alphabet -> int array
val decode_exn : ?alphabet:alphabet -> ?off:int -> ?len:int -> string -> string

val decode_sub : ?alphabet:alphabet -> ?off:int -> ?len:int -> string -> (sub, [> `Msg of string ]) result
(** Same as {!decode_exn} but it returns a result type instead to raise an exception. Then, it returns a {!sub} string.
    Decoded input [(str, off, len)] will starting to [off] and will have [len] bytes - by this way, we ensure to
    allocate only one time result. *)

val decode : ?alphabet:alphabet -> ?off:int -> ?len:int -> string -> (string, [> `Msg of string ]) result
(** Same as {!decode_exn}, but returns an explicit error message {!result} if it fails. *)

val encode : ?pad:bool -> ?alphabet:alphabet -> ?off:int -> ?len:int -> string -> (string, [> `Msg of string ]) result
(** [encode s] encodes the string [s] into base32. If [pad] is false, no trailing padding is added. [pad] defaults to
    [true], and [alphabet] to {!default_alphabet}.

    [encode] fails when [off] and [len] do not designate a valid range of [s]. *)

val encode_string : ?pad:bool -> ?alphabet:alphabet -> string -> string
(** [encode_string s] encodes the string [s] into base32. If [pad] is false, no trailing padding is added. [pad]
    defaults to [true], and [alphabet] to {!default_alphabet}. *)

val encode_sub : ?pad:bool -> ?alphabet:alphabet -> ?off:int -> ?len:int -> string -> (sub, [> `Msg of string ]) result
(** Same as {!encode} but return a {!sub}-string instead a plain result. By this way, we ensure to allocate only one
    time result. *)

val encode_exn : ?pad:bool -> ?alphabet:alphabet -> ?off:int -> ?len:int -> string -> string
(** Same as {!encode} but raises an invalid argument exception if we retrieve an error. *)
