module Percent = struct
  let hex_value = function
    | '0' .. '9' as character -> Char.code character - Char.code '0'
    | 'a' .. 'f' as character -> Char.code character - Char.code 'a' + 10
    | 'A' .. 'F' as character -> Char.code character - Char.code 'A' + 10
    | _ -> -1

  let slice value start stop = if start = stop then "" else String.sub value start (stop - start)

  let rec decoded_size reject_slash value stop read size =
    if read = stop then Ok size
    else
      match value.[read] with
      | '%' when read + 2 < stop ->
          let high = hex_value value.[read + 1] in
          let low = hex_value value.[read + 2] in
          if high < 0 || low < 0 then Error `Malformed
          else if reject_slash && high = 2 && low = 15 then Error `Encoded_slash
          else decoded_size reject_slash value stop (read + 3) (size + 1)
      | '%' -> Error `Malformed
      | _ -> decoded_size reject_slash value stop (read + 1) (size + 1)

  let rec decode_valid plus value stop decoded read write =
    if read = stop then Bytes.unsafe_to_string decoded
    else
      match value.[read] with
      | '%' ->
          let high = hex_value value.[read + 1] in
          let low = hex_value value.[read + 2] in
          Bytes.set decoded write (Char.chr ((high lsl 4) lor low));
          decode_valid plus value stop decoded (read + 3) (write + 1)
      | '+' when plus ->
          Bytes.set decoded write ' ';
          decode_valid plus value stop decoded (read + 1) (write + 1)
      | character ->
          Bytes.set decoded write character;
          decode_valid plus value stop decoded (read + 1) (write + 1)

  let decode_escaped ?(plus = false) ?(reject_slash = false) value ~start ~stop ~first =
    match decoded_size reject_slash value stop first (first - start) with
    | Error error -> Error error
    | Ok size ->
        let decoded = Bytes.create size in
        Bytes.blit_string value start decoded 0 (first - start);
        Ok (decode_valid plus value stop decoded first (first - start))
end

type error = RouterSearchParse.error = QueryTooLong

let parse search = RouterSearchParse.parse ~text:Fun.id ~slice:Percent.slice search
