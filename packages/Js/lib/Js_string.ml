(** JavaScript String API *)

type t = string

let make _whatever = Js_internal.notImplemented "Js.String" "make"

let fromCharCode code =
  let uchar = Uchar.of_int code in
  let char_value = Uchar.to_char uchar in
  Stdlib.String.make 1 char_value

let fromCharCodeMany _ = Js_internal.notImplemented "Js.String" "fromCharCodeMany"

let fromCodePoint code_point =
  let ch = Char.chr code_point in
  Stdlib.String.make 1 ch

let fromCodePointMany _ = Js_internal.notImplemented "Js.String" "fromCodePointMany"
let length = Stdlib.String.length

let get str index =
  let ch = Stdlib.String.get str index in
  Stdlib.String.make 1 ch

(* TODO (davesnx): If the string contains characters outside the range [\u0000-\uffff], it will return the first 16-bit value at that position in the string. *)
let charAt ~index str =
  if index < 0 || index >= Stdlib.String.length str then ""
  else
    let ch = Stdlib.String.get str index in
    Stdlib.String.make 1 ch

let charCodeAt ~index:n s =
  if n < 0 || n >= Stdlib.String.length s then nan else float_of_int (Stdlib.Char.code (Stdlib.String.get s n))

let codePointAt ~index str =
  let str_length = Stdlib.String.length str in
  if index >= 0 && index < str_length then
    let uchar = Uchar.of_char (Stdlib.String.get str index) in
    Some (Uchar.to_int uchar)
  else None

let concat ~other:str2 str1 = Stdlib.String.concat "" [ str1; str2 ]

let concatMany ~strings:many original =
  let many_list = Stdlib.Array.to_list many in
  Stdlib.String.concat "" (original :: many_list)

let endsWith ~suffix ?len str =
  let str_length = Stdlib.String.length str in
  let end_idx = match len with Some i -> Stdlib.min str_length i | None -> str_length in
  let sub_str = Stdlib.String.sub str 0 end_idx in
  Stdlib.String.ends_with ~suffix sub_str

let includes ~search ?start str =
  let str_length = Stdlib.String.length str in
  let search_length = Stdlib.String.length search in
  let rec includes_helper idx =
    if idx + search_length > str_length then false
    else if Stdlib.String.sub str idx search_length = search then true
    else includes_helper (idx + 1)
  in
  let from = match start with None -> 0 | Some f -> f in
  includes_helper from

let indexOf ~search ?start str =
  let str_length = Stdlib.String.length str in
  let search_length = Stdlib.String.length search in
  let rec index_helper idx =
    if idx + search_length > str_length then -1
    else if Stdlib.String.sub str idx search_length = search then idx
    else index_helper (idx + 1)
  in
  let from = match start with None -> 0 | Some f -> f in
  index_helper from

let lastIndexOf ~search ?(start = max_int) str =
  let len = String.length str in
  let rec find_index i =
    if i < 0 || i > start then -1
    else
      let sub_len = min (len - i) (String.length search) in
      if String.sub str i sub_len = search then i else find_index (i - 1)
  in
  find_index (min (len - 1) start)

let localeCompare ~other:_ _ = Js_internal.notImplemented "Js.String" "localeCompare"

let match_ ~regexp str =
  let match_next str regex =
    match Js_re.exec ~str regex with None -> None | Some result -> Some (Js_re.captures result)
  in

  let match_all : t -> Js_re.t -> t Js_internal.nullable array Js_internal.nullable =
   fun str regex ->
    match match_next str regex with
    | None -> None
    | Some result -> (
        match match_next str regex with None -> Some result | Some second -> Some (Stdlib.Array.append result second))
  in

  if Js_re.global regexp then match_all str regexp else match_next str regexp

let normalize ?(form = `NFC) str =
  let normalization =
    match form with
    | `NFC -> Quickjs.String.NFC
    | `NFD -> Quickjs.String.NFD
    | `NFKC -> Quickjs.String.NFKC
    | `NFKD -> Quickjs.String.NFKD
  in
  match Quickjs.String.Prototype.normalize normalization str with Some s -> s | None -> str

(* TODO(davesnx): RangeError *)
let repeat ~count str =
  let rec repeat' str acc remaining = if remaining <= 0 then acc else repeat' str (str ^ acc) (remaining - 1) in
  repeat' str "" count

(* If pattern is a string, only the first occurrence will be replaced.
   https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace *)
let replace ~search ~replacement str =
  let search_regexp = Str.regexp_string search in
  Str.replace_first search_regexp replacement str

(* Process replacement string with backreferences like $1, $2, $&, $$, $`, $' *)
let process_replacement ~replacement ~matches ~prefix ~suffix =
  let len = String.length replacement in
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
          let matched = Stdlib.Array.get matches 0 |> Option.value ~default:"" in
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
                  let two_digit = int_of_string (String.sub replacement start_digit 2) in
                  if two_digit < Array.length matches then (two_digit, 3) else (Char.code next - Char.code '0', 2)
              | _ -> (Char.code next - Char.code '0', 2)
            else (Char.code next - Char.code '0', 2)
          in
          if group_num > 0 && group_num < Array.length matches then (
            let group_value = Stdlib.Array.get matches group_num |> Option.value ~default:"" in
            Buffer.add_string buf group_value)
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

let replaceByRe ~regexp ~replacement str =
  let rec replace_all str =
    Js_re.setLastIndex regexp 0;
    match Js_re.exec ~str regexp with
    | None -> str
    | Some result when Stdlib.Array.length (Js_re.captures result) == 0 -> str
    | Some result ->
        let matches = Js_re.captures result in
        let matched_str = Stdlib.Array.get matches 0 |> Option.get in
        let prefix = Stdlib.String.sub str 0 (Js_re.index result) in
        let suffix_start = Js_re.index result + String.length matched_str in
        let suffix = Stdlib.String.sub str suffix_start (String.length str - suffix_start) in
        let processed_replacement = process_replacement ~replacement ~matches ~prefix ~suffix in
        Js_re.setLastIndex regexp suffix_start;
        prefix ^ processed_replacement ^ replace_all suffix
  in
  let replace_first str =
    match Js_re.exec ~str regexp with
    | None -> str
    | Some result ->
        let matches = Js_re.captures result in
        let matched_str = Stdlib.Array.get matches 0 |> Option.get in
        let prefix = Stdlib.String.sub str 0 (Js_re.index result) in
        let suffix_start = Js_re.index result + String.length matched_str in
        let suffix = Stdlib.String.sub str suffix_start (String.length str - suffix_start) in
        let processed_replacement = process_replacement ~replacement ~matches ~prefix ~suffix in
        prefix ^ processed_replacement ^ suffix
  in

  if Js_re.global regexp then replace_all str else replace_first str

let unsafeReplaceBy0 ~regexp:_ ~f:_ _ = Js_internal.notImplemented "Js.String" "unsafeReplaceBy0"
let unsafeReplaceBy1 ~regexp:_ ~f:_ _ = Js_internal.notImplemented "Js.String" "unsafeReplaceBy1"
let unsafeReplaceBy2 ~regexp:_ ~f:_ _ = Js_internal.notImplemented "Js.String" "unsafeReplaceBy2"
let unsafeReplaceBy3 ~regexp:_ ~f:_ _ = Js_internal.notImplemented "Js.String" "unsafeReplaceBy3"
let search ~regexp str =
  (* Save and reset lastIndex for consistent behavior *)
  let saved_last_index = Js_re.lastIndex regexp in
  Js_re.setLastIndex regexp 0;
  let result =
    if Js_re.test ~str regexp then (
      (* Reset lastIndex again since test modified it *)
      Js_re.setLastIndex regexp 0;
      match Js_re.exec ~str regexp with
      | Some result -> Js_re.index result
      | None -> -1)
    else -1
  in
  Js_re.setLastIndex regexp saved_last_index;
  result

let slice ?start ?end_ str =
  let str_length = Stdlib.String.length str in
  let start = match start with None -> 0 | Some s -> s in
  let end_ = match end_ with None -> str_length | Some s -> s in
  let start_idx = Stdlib.max 0 (Stdlib.min start str_length) in
  let end_idx = Stdlib.max start_idx (Stdlib.min end_ str_length) in
  if start_idx >= end_idx then "" else Stdlib.String.sub str start_idx (end_idx - start_idx)

let split ?sep ?limit str =
  let sep = Option.value sep ~default:str in
  let regexp = Str.regexp_string sep in
  (* On js split, it don't return an empty string on end when separator is an empty string *)
  (* but "split_delim" does *)
  (* https://melange.re/unstable/playground/?language=OCaml&code=SnMubG9nKEpzLlN0cmluZy5zcGxpdCB%2Bc2VwOiIiICJzdGFydCIpOw%3D%3D&live=off *)
  let split = if sep <> "" then Str.split_delim else Str.split in
  let items = split regexp str |> Stdlib.Array.of_list in
  let limit = Option.value limit ~default:(Stdlib.Array.length items) in
  match limit with
  | limit when limit >= 0 && limit < Stdlib.Array.length items -> Stdlib.Array.sub items 0 limit
  | _ -> items

let splitByRe ~regexp ?limit str =
  let rev_array arr = arr |> Stdlib.Array.to_list |> Stdlib.List.rev |> Stdlib.Array.of_list in
  let rec split_all str acc =
    Js_re.setLastIndex regexp 0;
    match Js_re.exec ~str regexp with
    | Some result when Stdlib.Array.length (Js_re.captures result) = 0 ->
        Stdlib.Array.append [| Some str |] acc |> rev_array
    | None -> Stdlib.Array.append [| Some str |] acc |> rev_array
    | Some result ->
        let matches = Js_re.captures result in
        let matched_str = Stdlib.Array.get matches 0 |> Option.get in
        let prefix = String.sub str 0 (Js_re.index result) in
        let suffix_start = Js_re.index result + String.length matched_str in
        let suffix = String.sub str suffix_start (String.length str - suffix_start) in
        let suffix_matches = Stdlib.Array.append [| Some prefix |] acc in
        split_all suffix suffix_matches
  in

  let split_next str acc =
    Js_re.setLastIndex regexp 0;
    match Js_re.exec ~str regexp with
    | None -> Stdlib.Array.append [| Some str |] acc |> rev_array
    | Some result ->
        let matches = Js_re.captures result in
        let matched_str = Stdlib.Array.get matches 0 |> Option.get in
        let index = Js_re.index result in
        let prefix = String.sub str 0 index in
        let suffix_start = index + String.length matched_str in
        let suffix = String.sub str suffix_start (String.length str - suffix_start) in
        Stdlib.Array.append [| Some prefix |] (split_all suffix acc)
  in

  let _ = limit in
  if Js_re.global regexp then split_all str [||] else split_next str [||]

let startsWith ~prefix ?(start = 0) str =
  let len_prefix = String.length prefix in
  let len_str = String.length str in
  if start < 0 || start > len_str then false
  else
    let rec compare_prefix i =
      i = len_prefix || (i < len_str && prefix.[i] = str.[start + i] && compare_prefix (i + 1))
    in
    compare_prefix 0

let substr ?(start = 0) ?len str =
  let str_length = Stdlib.String.length str in
  let len = match len with None -> str_length | Some s -> s in
  let start_idx = max 0 (min start str_length) in
  let end_idx = min (start_idx + len) str_length in
  if start_idx >= end_idx then "" else Stdlib.String.sub str start_idx (end_idx - start_idx)

let substring ?start ?end_ str =
  let str_length = Stdlib.String.length str in
  let start = match start with None -> 0 | Some s -> s in
  let end_ = match end_ with None -> str_length | Some s -> s in
  let start_idx = max 0 (min start str_length) in
  let end_idx = max 0 (min end_ str_length) in
  if start_idx >= end_idx then Stdlib.String.sub str end_idx (start_idx - end_idx)
  else Stdlib.String.sub str start_idx (end_idx - start_idx)

let case_to_utf_8 case_map s =
  let rec loop buf s i max =
    if i > max then Buffer.contents buf
    else
      let dec = String.get_utf_8_uchar s i in
      let u = Uchar.utf_decode_uchar dec in
      (match case_map u with
      | `Self -> Buffer.add_utf_8_uchar buf u
      | `Uchars us -> List.iter (Buffer.add_utf_8_uchar buf) us);
      loop buf s (i + Uchar.utf_decode_length dec) max
  in
  let buf = Buffer.create (String.length s * 2) in
  loop buf s 0 (String.length s - 1)

let toLowerCase s = case_to_utf_8 Uucp.Case.Map.to_lower s
let toLocaleLowerCase _ = Js_internal.notImplemented "Js.String" "toLocaleLowerCase"
let toUpperCase s = case_to_utf_8 Uucp.Case.Map.to_upper s
let toLocaleUpperCase _ = Js_internal.notImplemented "Js.String" "toLocaleUpperCase"

let trim str =
  let whitespace = " \t\n\r" in
  let is_whitespace c = Stdlib.String.contains whitespace c in
  let length = Stdlib.String.length str in
  let rec trim_start idx =
    if idx >= length then length else if is_whitespace (Stdlib.String.get str idx) then trim_start (idx + 1) else idx
  in
  let rec trim_end idx =
    if idx <= 0 then 0 else if is_whitespace (Stdlib.String.get str (idx - 1)) then trim_end (idx - 1) else idx
  in
  let start_idx = trim_start 0 in
  let end_idx = trim_end length in
  if start_idx >= end_idx then "" else Stdlib.String.sub str start_idx (end_idx - start_idx)

let anchor ~name:_ _ = Js_internal.notImplemented "Js.String" "anchor"
let link ~href:_ _ = Js_internal.notImplemented "Js.String" "link"
