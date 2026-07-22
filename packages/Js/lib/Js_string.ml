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

(* No locale-aware collation (ICU) on the server: byte-wise comparison.
   Diverges from JS for case-mixed and non-ASCII strings. *)
let localeCompare ~other str = Stdlib.float_of_int (Stdlib.compare (Stdlib.String.compare str other) 0)

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

let add_source_range buf ~prepared ~source ~start ~end_ =
  match Js_re.Prepared.byte_range prepared ~start ~end_ with
  | Some (start_byte, end_byte) -> Buffer.add_substring buf source start_byte (end_byte - start_byte)
  | None -> Buffer.add_string buf (Js_re.Prepared.substring prepared ~start ~end_)

(* Expands the replacement patterns of String.prototype.replace ($$, $&, $`,
   $', $1..$99) directly into [buf], as specified by GetSubstitution
   (ECMA-262 22.1.3.20.1). *)
let process_replacement ~buf ~prepared ~source ~source_length ~replacement ~matches ~match_start ~match_end =
  let len = Stdlib.String.length replacement in
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
          add_source_range buf ~prepared ~source ~start:0 ~end_:match_start;
          i := !i + 2
      | '\'' ->
          (* $' -> portion after the match *)
          add_source_range buf ~prepared ~source ~start:match_end ~end_:source_length;
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
  done

let is_full_unicode regexp =
  let flags = Js_re.flags regexp in
  Stdlib.String.contains flags 'u' || Stdlib.String.contains flags 'v'

(* Shared driver for RegExp.prototype[Symbol.replace] (ECMA-262 22.2.6.11).
   Global matches are collected before replacements are evaluated, so callback
   mutations of lastIndex cannot affect which matches are replaced. *)
let replace_driver ~regexp str ~add_replacement =
  let str_byte_length = Stdlib.String.length str in
  let str_length = Quickjs.String.Prototype.length str in
  let prepared = Js_re.Prepared.make str in
  let render matches =
    match matches with
    | [] -> str
    | _ ->
        let buf = Buffer.create str_byte_length in
        let previous_end = ref 0 in
        Stdlib.List.iter
          (fun match_ ->
            let match_start, match_end = Js_re.Prepared.range match_ in
            add_source_range buf ~prepared ~source:str ~start:!previous_end ~end_:match_start;
            add_replacement buf ~prepared ~source_length:str_length ~match_ ~match_start ~match_end;
            previous_end := match_end)
          matches;
        add_source_range buf ~prepared ~source:str ~start:!previous_end ~end_:str_length;
        Buffer.contents buf
  in
  if Js_re.global regexp then (
    (* RegExp.prototype[Symbol.replace] (ECMA-262 22.2.6.11): with the global
       flag, start from 0 and iterate with exec (which advances lastIndex to
       the end of each match); on an empty match, advance lastIndex manually
       with AdvanceStringIndex. The final failing exec resets the caller's
       lastIndex to 0, as in JavaScript. *)
    Js_re.setLastIndex regexp 0;
    let unicode = is_full_unicode regexp in
    let rec collect acc =
      match Js_re.Prepared.exec prepared regexp with
      | None -> Stdlib.List.rev acc
      | Some match_ ->
          let match_start, match_end = Js_re.Prepared.range match_ in
          if match_end = match_start then
            Js_re.setLastIndex regexp (Js_re.Prepared.advance_index prepared ~unicode match_start);
          collect (match_ :: acc)
    in
    render (collect []))
  else
    (* Without the global flag only the first match is replaced. exec is used
       directly on the caller's regexp so sticky (y) lastIndex semantics are
       preserved. *)
    match Js_re.Prepared.exec prepared regexp with
    | None -> str
    | Some match_ -> render [ match_ ]

let replaceByRe ~regexp ~replacement str =
  replace_driver ~regexp str ~add_replacement:(fun buf ~prepared ~source_length ~match_ ~match_start ~match_end ->
      process_replacement ~buf ~prepared ~source:str ~source_length ~replacement
        ~matches:(Js_re.Prepared.captures match_) ~match_start ~match_end)

(* The unsafeReplaceByN functions pass the matched text, the first N capture
   groups, the UTF-16 offset of the match, and the whole string to [f]. Like
   JavaScript, a capture group that did not participate in the match is passed
   as an "empty" value; Melange leaks [undefined], natively it is [""]. *)
let capture matches n =
  if n >= Stdlib.Array.length matches then "" else match Stdlib.Array.get matches n with Some c -> c | None -> ""

let unsafeReplaceBy0 ~regexp ~f str =
  replace_driver ~regexp str ~add_replacement:(fun buf ~prepared:_ ~source_length:_ ~match_ ~match_start ~match_end:_ ->
      Buffer.add_string buf (f (capture (Js_re.Prepared.captures match_) 0) match_start str))

let unsafeReplaceBy1 ~regexp ~f str =
  replace_driver ~regexp str ~add_replacement:(fun buf ~prepared:_ ~source_length:_ ~match_ ~match_start ~match_end:_ ->
      let matches = Js_re.Prepared.captures match_ in
      Buffer.add_string buf (f (capture matches 0) (capture matches 1) match_start str))

let unsafeReplaceBy2 ~regexp ~f str =
  replace_driver ~regexp str ~add_replacement:(fun buf ~prepared:_ ~source_length:_ ~match_ ~match_start ~match_end:_ ->
      let matches = Js_re.Prepared.captures match_ in
      Buffer.add_string buf (f (capture matches 0) (capture matches 1) (capture matches 2) match_start str))

let unsafeReplaceBy3 ~regexp ~f str =
  replace_driver ~regexp str ~add_replacement:(fun buf ~prepared:_ ~source_length:_ ~match_ ~match_start ~match_end:_ ->
      let matches = Js_re.Prepared.captures match_ in
      Buffer.add_string buf
        (f (capture matches 0) (capture matches 1) (capture matches 2) (capture matches 3) match_start str))

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
    let prepared = Js_re.Prepared.make str in
    if size = 0 then match Js_re.Prepared.exec prepared splitter with Some _ -> [||] | None -> [| Some str |]
    else
      let substring_between start_u16 end_u16 = Js_re.Prepared.substring prepared ~start:start_u16 ~end_:end_u16 in
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
            match Js_re.Prepared.exec prepared splitter with
            | None -> ()
            | Some match_ ->
                let match_start, match_end = Js_re.Prepared.range match_ in
                (* The loop in the spec only probes positions before the end of
                   the string: a match starting at the very end is ignored. *)
                if match_start < size then
                  let match_end = Stdlib.min match_end size in
                  if match_end = !segment_start then (
                    (* Empty match at the current segment start: no split here,
                       advance and keep searching. *)
                    Js_re.setLastIndex splitter (Js_re.Prepared.advance_index prepared ~unicode match_start);
                    loop ())
                  else (
                    push (Some (substring_between !segment_start match_start));
                    let captures = Js_re.Prepared.captures match_ in
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

(* Locale-insensitive: aliased to toLowerCase (no ICU on the server). *)
let toLocaleLowerCase str = Quickjs.String.Prototype.to_lower_case str
let toUpperCase str = Quickjs.String.Prototype.to_upper_case str

(* Locale-insensitive: aliased to toUpperCase (no ICU on the server). *)
let toLocaleUpperCase str = Quickjs.String.Prototype.to_upper_case str
let trim str = Quickjs.String.Prototype.trim str

(* String.prototype.anchor/link (ECMA-262 B.2.2, CreateHTML): double quotes
   in the attribute value are replaced with &quot;. *)
let escape_html_attribute value =
  let buf = Buffer.create (Stdlib.String.length value) in
  Stdlib.String.iter (fun c -> if c = '"' then Buffer.add_string buf "&quot;" else Buffer.add_char buf c) value;
  Buffer.contents buf

let anchor ~name str = "<a name=\"" ^ escape_html_attribute name ^ "\">" ^ str ^ "</a>"
let link ~href str = "<a href=\"" ^ escape_html_attribute href ^ "\">" ^ str ^ "</a>"
