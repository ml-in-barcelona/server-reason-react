(** JavaScript String API *)

type t = string

let make _whatever = Js_internal.notImplemented "Js.String" "make"
let fromCharCode code = Quickjs.String.from_char_code [| code |]
let fromCharCodeMany codes = Quickjs.String.from_char_code codes
let fromCodePoint code_point = Quickjs.String.from_code_point [| code_point |]
let fromCodePointMany code_points = Quickjs.String.from_code_point code_points
let length str = Quickjs.String.Prototype.length str
let get str index = Quickjs.String.Prototype.char_at index str
let charAt ~index str = Quickjs.String.Prototype.char_at index str

let charCodeAt ~index str =
  match Quickjs.String.Prototype.char_code_at index str with Some code -> float_of_int code | None -> nan

let codePointAt ~index str = Quickjs.String.Prototype.code_point_at index str
let concat ~other:str2 str1 = str1 ^ str2

let concatMany ~strings:many original =
  let many_list = Stdlib.Array.to_list many in
  Stdlib.String.concat "" (original :: many_list)

let endsWith ~suffix ?len str =
  match len with
  | None -> Quickjs.String.Prototype.ends_with suffix str
  | Some len -> Quickjs.String.Prototype.ends_with_at suffix len str

let includes ~search ?start str =
  match start with
  | None -> Quickjs.String.Prototype.includes search str
  | Some start -> Quickjs.String.Prototype.includes_from search start str

let indexOf ~search ?start str =
  match start with
  | None -> Quickjs.String.Prototype.index_of search str
  | Some start -> Quickjs.String.Prototype.index_of_from search start str

let lastIndexOf ~search ?start str =
  match start with
  | None -> Quickjs.String.Prototype.last_index_of search str
  | Some start -> Quickjs.String.Prototype.last_index_of_from search start str

let localeCompare ~other:_ _ = Js_internal.notImplemented "Js.String" "localeCompare"

(* Removes the given flag from a JavaScript flags string, e.g. [remove_flag 'g' "gi"] is ["i"]. *)
let remove_flag flag flags =
  Stdlib.String.to_seq flags |> Stdlib.Seq.filter (fun c -> c <> flag) |> Stdlib.String.of_seq

let match_ ~regexp str =
  if Js_re.global regexp then (
    (* JavaScript's String.prototype.match with a global regexp returns every
       full match (without capture groups) and leaves lastIndex at 0. *)
    let flags = remove_flag 'g' (Js_re.flags regexp) in
    let matches = Quickjs.String.Prototype.match_global ~flags (Js_re.source regexp) str in
    Js_re.setLastIndex regexp 0;
    if Stdlib.Array.length matches = 0 then None else Some (Stdlib.Array.map (fun m -> Some m) matches))
  else match Js_re.exec ~str regexp with None -> None | Some result -> Some (Js_re.captures result)

let normalize ?(form = `NFC) str =
  let normalization =
    match form with
    | `NFC -> Quickjs.String.NFC
    | `NFD -> Quickjs.String.NFD
    | `NFKC -> Quickjs.String.NFKC
    | `NFKD -> Quickjs.String.NFKD
  in
  match Quickjs.String.Prototype.normalize normalization str with Some s -> s | None -> str

let repeat ~count str = Quickjs.String.Prototype.repeat count str
let replace ~search ~replacement str = Quickjs.String.Prototype.replace search replacement str

(* Expands the replacement patterns of String.prototype.replace ($$, $&, $`,
   $', $1..$99) as specified by GetSubstitution (ECMA-262 22.1.3.20.1).
   [matches] is the captures array (entry 0 is the full match); [prefix] and
   [suffix] are the portions of the original string before and after the
   match. *)
let process_replacement ~replacement ~matches ~prefix ~suffix =
  let len = Stdlib.String.length replacement in
  let buf = Buffer.create len in
  let i = ref 0 in
  while !i < len do
    if replacement.[!i] = '$' && !i + 1 < len then (
      let next = replacement.[!i + 1] in
      match next with
      | '$' ->
          (* $$ -> literal $ *)
          Buffer.add_char buf '$';
          i := !i + 2
      | '&' ->
          (* $& -> the matched substring *)
          let matched = Stdlib.Array.get matches 0 |> Stdlib.Option.value ~default:"" in
          Buffer.add_string buf matched;
          i := !i + 2
      | '`' ->
          (* $` -> portion before the match *)
          Buffer.add_string buf prefix;
          i := !i + 2
      | '\'' ->
          (* $' -> portion after the match *)
          Buffer.add_string buf suffix;
          i := !i + 2
      | '0' .. '9' ->
          (* $n or $nn -> capturing group *)
          let start_digit = !i + 1 in
          (* Check for two-digit group number *)
          let group_num, advance =
            if !i + 2 < len then
              match replacement.[!i + 2] with
              | '0' .. '9' ->
                  let two_digit = int_of_string (Stdlib.String.sub replacement start_digit 2) in
                  if two_digit < Stdlib.Array.length matches then (two_digit, 3)
                  else (Stdlib.Char.code next - Stdlib.Char.code '0', 2)
              | _ -> (Stdlib.Char.code next - Stdlib.Char.code '0', 2)
            else (Stdlib.Char.code next - Stdlib.Char.code '0', 2)
          in
          if group_num > 0 && group_num < Stdlib.Array.length matches then
            let group_value = Stdlib.Array.get matches group_num |> Stdlib.Option.value ~default:"" in
            Buffer.add_string buf group_value
          else (
            (* Invalid group reference, keep as literal *)
            Buffer.add_char buf '$';
            Buffer.add_char buf next;
            if advance = 3 then Buffer.add_char buf replacement.[!i + 2]);
          i := !i + advance
      | _ ->
          (* Unknown $ sequence, keep as literal *)
          Buffer.add_char buf '$';
          incr i)
    else (
      Buffer.add_char buf replacement.[!i];
      incr i)
  done;
  Buffer.contents buf

(* AdvanceStringIndex (ECMA-262 22.2.7.3): the position after [index], in
   UTF-16 code units. With the unicode flag, an index pointing at the high
   surrogate of a surrogate pair advances past the whole code point. *)
let advance_string_index str index unicode =
  if not unicode then index + 1
  else
    let is_high c = c >= 0xD800 && c <= 0xDBFF in
    let is_low c = c >= 0xDC00 && c <= 0xDFFF in
    match (Quickjs.String.Prototype.char_code_at index str, Quickjs.String.Prototype.char_code_at (index + 1) str) with
    | Some high, Some low when is_high high && is_low low -> index + 2
    | _ -> index + 1

let is_full_unicode regexp =
  let flags = Js_re.flags regexp in
  Stdlib.String.contains flags 'u' || Stdlib.String.contains flags 'v'

let replaceByRe ~regexp ~replacement str =
  let str_byte_length = Stdlib.String.length str in
  let add_replacement buf ~matches ~match_start_byte ~match_end_byte =
    let prefix = Stdlib.String.sub str 0 match_start_byte in
    let suffix = Stdlib.String.sub str match_end_byte (str_byte_length - match_end_byte) in
    Buffer.add_string buf (process_replacement ~replacement ~matches ~prefix ~suffix)
  in
  if Js_re.global regexp then (
    (* RegExp.prototype[Symbol.replace] (ECMA-262 22.2.6.11): with the global
       flag, start from 0 and iterate with exec (which advances lastIndex to
       the end of each match); on an empty match, advance lastIndex manually
       with AdvanceStringIndex. The final failing exec resets the caller's
       lastIndex to 0, as in JavaScript. *)
    Js_re.setLastIndex regexp 0;
    let unicode = is_full_unicode regexp in
    let buf = Buffer.create str_byte_length in
    let previous_end_byte = ref 0 in
    let rec loop () =
      match Js_re.exec ~str regexp with
      | None -> ()
      | Some result ->
          let match_start = Js_re.index result in
          let match_end = Js_re.lastIndex regexp in
          let match_start_byte = Quickjs.String.byte_index_of_utf16 str match_start in
          let match_end_byte = Quickjs.String.byte_index_of_utf16 str match_end in
          Buffer.add_string buf (Stdlib.String.sub str !previous_end_byte (match_start_byte - !previous_end_byte));
          add_replacement buf ~matches:(Js_re.captures result) ~match_start_byte ~match_end_byte;
          previous_end_byte := match_end_byte;
          if match_end = match_start then Js_re.setLastIndex regexp (advance_string_index str match_start unicode);
          loop ()
    in
    loop ();
    Buffer.add_string buf (Stdlib.String.sub str !previous_end_byte (str_byte_length - !previous_end_byte));
    Buffer.contents buf)
  else
    (* Without the global flag only the first match is replaced. exec is used
       directly on the caller's regexp so sticky (y) lastIndex semantics are
       preserved. *)
    match Js_re.exec ~str regexp with
    | None -> str
    | Some result ->
        let matches = Js_re.captures result in
        let matched = Stdlib.Array.get matches 0 |> Stdlib.Option.value ~default:"" in
        let match_start = Js_re.index result in
        (* The UTF-16 length of the matched text is used to find the match end:
           it is stable even when the engine substitutes U+FFFD for unpaired
           surrogates (both occupy one UTF-16 unit). *)
        let match_end = match_start + Quickjs.String.Prototype.length matched in
        let match_start_byte = Quickjs.String.byte_index_of_utf16 str match_start in
        let match_end_byte = Quickjs.String.byte_index_of_utf16 str match_end in
        let buf = Buffer.create str_byte_length in
        Buffer.add_string buf (Stdlib.String.sub str 0 match_start_byte);
        add_replacement buf ~matches ~match_start_byte ~match_end_byte;
        Buffer.add_string buf (Stdlib.String.sub str match_end_byte (str_byte_length - match_end_byte));
        Buffer.contents buf

let unsafeReplaceBy0 ~regexp:_ ~f:_ _ = Js_internal.notImplemented "Js.String" "unsafeReplaceBy0"
let unsafeReplaceBy1 ~regexp:_ ~f:_ _ = Js_internal.notImplemented "Js.String" "unsafeReplaceBy1"
let unsafeReplaceBy2 ~regexp:_ ~f:_ _ = Js_internal.notImplemented "Js.String" "unsafeReplaceBy2"
let unsafeReplaceBy3 ~regexp:_ ~f:_ _ = Js_internal.notImplemented "Js.String" "unsafeReplaceBy3"

let search ~regexp str =
  (* RegExp.prototype[Symbol.search] (ECMA-262 22.2.6.12): search from 0 and
     restore the caller's lastIndex afterwards. *)
  let saved_last_index = Js_re.lastIndex regexp in
  Js_re.setLastIndex regexp 0;
  let result = match Js_re.exec ~str regexp with Some result -> Js_re.index result | None -> -1 in
  Js_re.setLastIndex regexp saved_last_index;
  result

let slice ?start ?end_ str =
  match (start, end_) with
  | None, None -> str
  | Some start, None -> Quickjs.String.Prototype.slice_from start str
  | None, Some end_ -> Quickjs.String.Prototype.slice ~start:0 ~end_ str
  | Some start, Some end_ -> Quickjs.String.Prototype.slice ~start ~end_ str

(* String.prototype.split coerces limit with ToUint32: negative values wrap to
   huge positive values and behave as "no limit". *)
let to_uint32 limit = limit land 0xFFFFFFFF

let split ?sep ?limit str =
  match sep with
  (* JavaScript's str.split(undefined, limit) never splits: it is [str] alone,
     or [] when the limit is 0. *)
  | None -> ( match limit with Some limit when to_uint32 limit = 0 -> [||] | _ -> [| str |])
  | Some sep -> (
      if str = "" && sep <> "" then
        (* JavaScript: "".split(sep) is [""] for any non-empty separator. *)
        match limit with
        | Some limit when to_uint32 limit = 0 -> [||]
        | _ -> [| str |]
      else
        match limit with
        | None -> Quickjs.String.Prototype.split sep str
        | Some limit -> Quickjs.String.Prototype.split_limit sep limit str)

let splitByRe ~regexp ?limit str =
  (* RegExp.prototype[Symbol.split] (ECMA-262 22.2.6.14). The regexp is
     recompiled with the global flag added (JavaScript clones it with the
     sticky flag), so the caller's lastIndex is never touched. *)
  let limit = match limit with None -> 0xFFFFFFFF | Some limit -> to_uint32 limit in
  if limit = 0 then [||]
  else
    (* The spec clones with the sticky flag and probes every position one by
       one; scanning forward with a global, non-sticky regexp is equivalent. *)
    let flags = remove_flag 'y' (Js_re.flags regexp) in
    let flags = if Stdlib.String.contains flags 'g' then flags else flags ^ "g" in
    let splitter = Js_re.fromStringWithFlags (Js_re.source regexp) ~flags in
    let unicode = is_full_unicode regexp in
    let size = Quickjs.String.Prototype.length str in
    if size = 0 then match Js_re.exec ~str splitter with Some _ -> [||] | None -> [| Some str |]
    else
      let substring_between start_u16 end_u16 =
        let start_byte = Quickjs.String.byte_index_of_utf16 str start_u16 in
        let end_byte = Quickjs.String.byte_index_of_utf16 str end_u16 in
        Stdlib.String.sub str start_byte (end_byte - start_byte)
      in
      let out = ref [] in
      let count = ref 0 in
      let exception Limit_reached in
      let push entry =
        out := entry :: !out;
        incr count;
        if !count = limit then raise Limit_reached
      in
      let segment_start = ref 0 in
      let reached_limit =
        try
          let rec loop () =
            match Js_re.exec ~str splitter with
            | None -> ()
            | Some result ->
                let match_start = Js_re.index result in
                (* The loop in the spec only probes positions before the end of
                   the string: a match starting at the very end is ignored. *)
                if match_start < size then
                  let match_end = Stdlib.min (Js_re.lastIndex splitter) size in
                  if match_end = !segment_start then (
                    (* Empty match at the current segment start: no split here,
                       advance and keep searching. *)
                    Js_re.setLastIndex splitter (advance_string_index str match_start unicode);
                    loop ())
                  else (
                    push (Some (substring_between !segment_start match_start));
                    let captures = Js_re.captures result in
                    for i = 1 to Stdlib.Array.length captures - 1 do
                      push (Stdlib.Array.get captures i)
                    done;
                    segment_start := match_end;
                    loop ())
          in
          loop ();
          false
        with Limit_reached -> true
      in
      if not reached_limit then out := Some (substring_between !segment_start size) :: !out;
      Stdlib.Array.of_list (Stdlib.List.rev !out)

let startsWith ~prefix ?start str =
  match start with
  | None -> Quickjs.String.Prototype.starts_with prefix str
  | Some start -> Quickjs.String.Prototype.starts_with_from prefix start str

let substr ?start ?len str =
  match (start, len) with
  | None, None -> str
  | Some start, None -> Quickjs.String.Prototype.substr_from start str
  | None, Some len -> Quickjs.String.Prototype.substr ~start:0 ~length:len str
  | Some start, Some len -> Quickjs.String.Prototype.substr ~start ~length:len str

let substring ?start ?end_ str =
  match (start, end_) with
  | None, None -> str
  | Some start, None -> Quickjs.String.Prototype.substring_from start str
  | None, Some end_ -> Quickjs.String.Prototype.substring ~start:0 ~end_ str
  | Some start, Some end_ -> Quickjs.String.Prototype.substring ~start ~end_ str

let toLowerCase str = Quickjs.String.Prototype.to_lower_case str
let toLocaleLowerCase _ = Js_internal.notImplemented "Js.String" "toLocaleLowerCase"
let toUpperCase str = Quickjs.String.Prototype.to_upper_case str
let toLocaleUpperCase _ = Js_internal.notImplemented "Js.String" "toLocaleUpperCase"
let trim str = Quickjs.String.Prototype.trim str
let anchor ~name:_ _ = Js_internal.notImplemented "Js.String" "anchor"
let link ~href:_ _ = Js_internal.notImplemented "Js.String" "link"
