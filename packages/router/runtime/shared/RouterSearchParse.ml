(* Native RouterQuery.parse and the browser both use this parser, so one URL has the same search values on both sides.
   [~text] turns decoded UTF-8 bytes into the platform's string. [~slice] cuts [start, stop): Melange's String.sub
   copies the whole string first. The file is OCaml, not Reason: Reason's multi-argument functions reach OCaml 5.2+
   as one-argument closures, which allocate on every call of these loops. *)

type error = QueryTooLong

let maxLength = 8192

let hexValue = function
  | '0' .. '9' as character -> Char.code character - 48
  | 'a' .. 'f' as character -> Char.code character - 87
  | 'A' .. 'F' as character -> Char.code character - 55
  | _ -> -1

let rec decodedSize search stop read size =
  if read = stop then size
  else if String.unsafe_get search read = '%' then
    if
      read + 2 < stop
      && hexValue (String.unsafe_get search (read + 1)) >= 0
      && hexValue (String.unsafe_get search (read + 2)) >= 0
    then decodedSize search stop (read + 3) (size + 1)
    else -1
  else decodedSize search stop (read + 1) (size + 1)

let rec decodeInto search stop decoded read write =
  if read < stop then
    match String.unsafe_get search read with
    | '%' ->
        Bytes.unsafe_set decoded write
          (Char.unsafe_chr
             ((hexValue (String.unsafe_get search (read + 1)) lsl 4) lor hexValue (String.unsafe_get search (read + 2))));
        decodeInto search stop decoded (read + 3) (write + 1)
    | '+' ->
        Bytes.unsafe_set decoded write ' ';
        decodeInto search stop decoded (read + 1) (write + 1)
    | character ->
        Bytes.unsafe_set decoded write character;
        decodeInto search stop decoded (read + 1) (write + 1)

(* [first] is the index of the first '%', '+' or byte >= 0x80 in [start, stop), or -1 when there is none. *)
let decode ~text ~slice search start stop first =
  if first < 0 then Some (slice search start stop)
  else
    let size = decodedSize search stop first (first - start) in
    if size < 0 then None
    else
      let decoded = Bytes.create size in
      Bytes.blit_string search start decoded 0 (first - start);
      decodeInto search stop decoded first (first - start);
      let decoded = Bytes.unsafe_to_string decoded in
      if RouterUtf8.valid decoded then Some (text decoded) else None

type index = Small | Large of (string, string list ref) Hashtbl.t

let rec findValues key = function
  | [] -> None
  | (current, values) :: keys -> if String.equal key current then Some values else findValues key keys

type state = { mutable keys : (string * string list ref) list; mutable count : int; mutable index : index }

let add state key value =
  let current =
    match state.index with Small -> findValues key state.keys | Large table -> Hashtbl.find_opt table key
  in
  match current with
  | Some current -> current := value :: !current
  | None -> (
      let current = ref [ value ] in
      state.keys <- (key, current) :: state.keys;
      state.count <- state.count + 1;
      match state.index with
      | Large table -> Hashtbl.add table key current
      | Small when state.count = 8 ->
          let table = Hashtbl.create 16 in
          List.iter (fun (key, current) -> Hashtbl.add table key current) state.keys;
          state.index <- Large table
      | Small -> ())

let escaped character = character = '%' || character = '+' || Char.code character >= 0x80

let rec scan ~text ~slice search length state start equals keyFirst valueFirst position =
  if position < length && String.unsafe_get search position <> '&' then
    let character = String.unsafe_get search position in
    if equals < 0 && character = '=' then
      scan ~text ~slice search length state start position keyFirst valueFirst (position + 1)
    else if escaped character then
      scan ~text ~slice search length state start equals
        (if equals < 0 && keyFirst < 0 then position else keyFirst)
        (if equals >= 0 && valueFirst < 0 then position else valueFirst)
        (position + 1)
    else scan ~text ~slice search length state start equals keyFirst valueFirst (position + 1)
  else if start = position then
    if position >= length then () else scan ~text ~slice search length state (position + 1) (-1) (-1) (-1) (position + 1)
  else
    let keyStop = if equals < 0 then position else equals in
    let valueStart = if equals < 0 then position else equals + 1 in
    (match decode ~text ~slice search start keyStop keyFirst with
    | None -> ()
    | Some key -> (
        match decode ~text ~slice search valueStart position valueFirst with
        | None -> ()
        | Some value -> add state key value));
    if position >= length then () else scan ~text ~slice search length state (position + 1) (-1) (-1) (-1) (position + 1)

let parse ~text ~slice search =
  let length = String.length search in
  if length > maxLength then Error QueryTooLong
  else
    let first = if length > 0 && String.unsafe_get search 0 = '?' then 1 else 0 in
    let state = { keys = []; count = 0; index = Small } in
    if first < length then scan ~text ~slice search length state first (-1) (-1) (-1) first;
    Ok (List.rev_map (fun (key, current) -> (key, List.rev !current)) state.keys)
