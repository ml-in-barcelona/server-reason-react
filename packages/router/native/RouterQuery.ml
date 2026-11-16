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

  let decode_range ?(plus = false) value ~start ~stop ~first =
    if first < 0 then Ok (slice value start stop)
    else
      match decode_escaped ~plus value ~start ~stop ~first with
      | Ok decoded -> Ok decoded
      | Error _ -> Error (slice value start stop)
end

type error = MalformedEscape of string | QueryTooLong
type index = Small | Large of (string, string list ref) Hashtbl.t

let decode search ~start ~stop ~first =
  match Percent.decode_range ~plus:true search ~start ~stop ~first with
  | Ok value -> Ok value
  | Error value -> Error (MalformedEscape value)

let rec find_values key = function
  | [] -> None
  | (current_key, values) :: keys -> if String.equal key current_key then Some values else find_values key keys

let parse search =
  if String.length search > 8192 then Error QueryTooLong
  else
    let length = String.length search in
    let first = if length > 0 && search.[0] = '?' then 1 else 0 in
    if first = length then Ok []
    else
      let keys = ref [] in
      let value_index = ref Small in
      let finish () = Ok (List.rev_map (fun (key, current) -> (key, List.rev !current)) !keys) in
      let rec loop start equals key_first value_first index =
        if index < length && search.[index] <> '&' then
          let character = search.[index] in
          if equals < 0 && character = '=' then loop start index key_first value_first (index + 1)
          else
            let escaped = character = '%' || character = '+' in
            let key_first = if equals < 0 && key_first < 0 && escaped then index else key_first in
            let value_first = if equals >= 0 && value_first < 0 && escaped then index else value_first in
            loop start equals key_first value_first (index + 1)
        else
          let key_stop = if equals < 0 then index else equals in
          let value_start = if equals < 0 then index else equals + 1 in
          match
            ( decode search ~start ~stop:key_stop ~first:key_first,
              decode search ~start:value_start ~stop:index ~first:value_first )
          with
          | Ok key, Ok value ->
              let current =
                match !value_index with Small -> find_values key !keys | Large values -> Hashtbl.find_opt values key
              in
              (match current with
              | Some current -> current := value :: !current
              | None -> (
                  let current = ref [ value ] in
                  keys := (key, current) :: !keys;
                  match !value_index with
                  | Large values -> Hashtbl.add values key current
                  | Small when List.length !keys = 8 ->
                      let values = Hashtbl.create 16 in
                      List.iter (fun (key, current) -> Hashtbl.add values key current) !keys;
                      value_index := Large values
                  | Small -> ()));
              if index = length then finish () else loop (index + 1) (-1) (-1) (-1) (index + 1)
          | Error error, _ | _, Error error -> Error error
      in
      loop first (-1) (-1) (-1) first
