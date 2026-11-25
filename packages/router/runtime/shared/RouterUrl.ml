type error = Malformed | EncodedSlash | InvalidSegment

let unicodeStrings = String.length {js|é|js} = 1

let utf8 value =
  if not unicodeStrings then value
  else
    let length = String.length value in
    let buffer = Buffer.create length in
    let add code = Buffer.add_char buffer (Char.unsafe_chr code) in
    let rec loop index =
      if index < length then (
        let unit = Char.code (String.unsafe_get value index) in
        let low = if index + 1 < length then Char.code (String.unsafe_get value (index + 1)) else 0 in
        let code, next =
          if unit >= 0xd800 && unit <= 0xdbff && low >= 0xdc00 && low <= 0xdfff then
            (0x10000 + ((unit - 0xd800) lsl 10) + (low - 0xdc00), index + 2)
          else (unit, index + 1)
        in
        if code < 0x80 then add code
        else if code < 0x800 then (
          add (0xc0 lor (code lsr 6));
          add (0x80 lor (code land 0x3f)))
        else if code < 0x10000 then (
          add (0xe0 lor (code lsr 12));
          add (0x80 lor ((code lsr 6) land 0x3f));
          add (0x80 lor (code land 0x3f)))
        else (
          add (0xf0 lor (code lsr 18));
          add (0x80 lor ((code lsr 12) land 0x3f));
          add (0x80 lor ((code lsr 6) land 0x3f));
          add (0x80 lor (code land 0x3f)));
        loop next)
    in
    loop 0;
    Buffer.contents buffer

let hexValue = function
  | '0' .. '9' as character -> Char.code character - Char.code '0'
  | 'a' .. 'f' as character -> Char.code character - Char.code 'a' + 10
  | 'A' .. 'F' as character -> Char.code character - Char.code 'A' + 10
  | _ -> -1

let slice value start stop = if start = stop then "" else String.sub value start (stop - start)

let rec decodedSize rejectSlash value stop read size =
  if read = stop then Ok size
  else
    match String.unsafe_get value read with
    | '%' when read + 2 < stop ->
        let high = hexValue (String.unsafe_get value (read + 1)) in
        let low = hexValue (String.unsafe_get value (read + 2)) in
        if high < 0 || low < 0 then Error Malformed
        else if rejectSlash && high = 2 && low = 15 then Error EncodedSlash
        else decodedSize rejectSlash value stop (read + 3) (size + 1)
    | '%' -> Error Malformed
    | _ -> decodedSize rejectSlash value stop (read + 1) (size + 1)

let rec decodeValid plus value stop decoded read write =
  if read = stop then Bytes.unsafe_to_string decoded
  else
    match String.unsafe_get value read with
    | '%' ->
        let high = hexValue (String.unsafe_get value (read + 1)) in
        let low = hexValue (String.unsafe_get value (read + 2)) in
        Bytes.unsafe_set decoded write (Char.unsafe_chr ((high lsl 4) lor low));
        decodeValid plus value stop decoded (read + 3) (write + 1)
    | '+' when plus ->
        Bytes.unsafe_set decoded write ' ';
        decodeValid plus value stop decoded (read + 1) (write + 1)
    | character ->
        Bytes.unsafe_set decoded write character;
        decodeValid plus value stop decoded (read + 1) (write + 1)

let decodeEscaped ?(plus = false) ?(rejectSlash = false) value ~start ~stop ~first =
  match decodedSize rejectSlash value stop first (first - start) with
  | Error error -> Error error
  | Ok size ->
      let decoded = Bytes.create size in
      Bytes.blit_string value start decoded 0 (first - start);
      Ok (decodeValid plus value stop decoded first (first - start))

let continuation value length index = index < length && Char.code (String.unsafe_get value index) land 0xc0 = 0x80

let rec validUtf8From value length index =
  if index >= length then true
  else
    let first = Char.code (String.unsafe_get value index) in
    if first < 0x80 then validUtf8From value length (index + 1)
    else if first < 0xc2 then false
    else if first < 0xe0 then continuation value length (index + 1) && validUtf8From value length (index + 2)
    else if index + 1 >= length then false
    else
      let second = Char.code (String.unsafe_get value (index + 1)) in
      if first < 0xf0 then
        (match first with 0xe0 -> second >= 0xa0 | 0xed -> second < 0xa0 | _ -> true)
        && continuation value length (index + 1)
        && continuation value length (index + 2)
        && validUtf8From value length (index + 3)
      else if first < 0xf5 then
        (match first with 0xf0 -> second >= 0x90 | 0xf4 -> second < 0x90 | _ -> true)
        && continuation value length (index + 1)
        && continuation value length (index + 2)
        && continuation value length (index + 3)
        && validUtf8From value length (index + 4)
      else false

let validUtf8 value = validUtf8From value (String.length value) 0

let validSegment value =
  (not (String.equal value ""))
  && (not (String.equal value "."))
  && (not (String.equal value ".."))
  && validUtf8 value
  && String.for_all (fun character -> Char.code character >= 0x20 && Char.code character <> 0x7f) value

let rec firstEscape value stop index =
  if index >= stop then -1 else if String.unsafe_get value index = '%' then index else firstEscape value stop (index + 1)

let decodeSegmentRange value ~start ~stop =
  let first = firstEscape value stop start in
  if first < 0 then
    let segment = slice value start stop in
    if validSegment segment then Ok segment else Error InvalidSegment
  else
    match decodeEscaped ~rejectSlash:true value ~start ~stop ~first with
    | Error _ as error -> error
    | Ok decoded as ok -> if validSegment decoded then ok else Error InvalidSegment

let decodeSegment value = decodeSegmentRange value ~start:0 ~stop:(String.length value)
