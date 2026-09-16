type node = { start : int; finish : int; kind : kind }
and kind = String of string | Scalar | Object of node list | Array of node list * int list

let fail position message = invalid_arg (Printf.sprintf "Flight projection at byte %d: %s" position message)

let parse source offset =
  let length = String.length source in
  let cursor = ref offset in
  let whitespace () =
    while !cursor < length && List.mem source.[!cursor] [ ' '; '\t'; '\r'; '\n' ] do
      incr cursor
    done
  in
  let expect char =
    whitespace ();
    if !cursor >= length || source.[!cursor] <> char then fail !cursor (Printf.sprintf "expected %C" char);
    incr cursor
  in
  let string () =
    let start = !cursor in
    expect '"';
    let rec scan () =
      if !cursor >= length then fail start "unterminated string";
      match source.[!cursor] with
      | '"' -> incr cursor
      | '\\' ->
          cursor := !cursor + 2;
          scan ()
      | char when Char.code char < 0x20 -> fail !cursor "unescaped control character in string"
      | _ ->
          incr cursor;
          scan ()
    in
    scan ();
    match Yojson.Safe.from_string (String.sub source start (!cursor - start)) with
    | `String value -> value
    | _ -> fail start "expected JSON string"
  in
  let rec value () =
    whitespace ();
    let start = !cursor in
    if start >= length then fail start "missing JSON value";
    let kind =
      match source.[start] with
      | '"' -> String (string ())
      | '[' ->
          incr cursor;
          whitespace ();
          let rec items nodes commas =
            let node = value () in
            whitespace ();
            if !cursor < length && source.[!cursor] = ',' then (
              let comma = !cursor in
              incr cursor;
              items (node :: nodes) (comma :: commas))
            else (
              expect ']';
              Array (List.rev (node :: nodes), List.rev commas))
          in
          if !cursor < length && source.[!cursor] = ']' then (
            incr cursor;
            Array ([], []))
          else items [] []
      | '{' ->
          incr cursor;
          whitespace ();
          let rec fields nodes =
            whitespace ();
            ignore (string ());
            expect ':';
            let node = value () in
            whitespace ();
            if !cursor < length && source.[!cursor] = ',' then (
              incr cursor;
              fields (node :: nodes))
            else (
              expect '}';
              Object (List.rev (node :: nodes)))
          in
          if !cursor < length && source.[!cursor] = '}' then (
            incr cursor;
            Object [])
          else fields []
      | _ ->
          while !cursor < length && not (List.mem source.[!cursor] [ ','; ']'; '}'; ' '; '\t'; '\r'; '\n' ]) do
            incr cursor
          done;
          let token = String.sub source start (!cursor - start) in
          let number = Str.regexp "-?\\(0\\|[1-9][0-9]*\\)\\(\\.[0-9]+\\)?\\([eE][+-]?[0-9]+\\)?$" in
          if
            not
              (List.mem token [ "null"; "true"; "false" ]
              || (Str.string_match number token 0 && Str.match_end () = String.length token))
          then fail start "invalid JSON scalar";
          Scalar
    in
    { start; finish = !cursor; kind }
  in
  let parsed = value () in
  whitespace ();
  if !cursor <> length then fail !cursor "trailing content after JSON value";
  parsed

let project_row row =
  let length = String.length row in
  let colon = match String.index_opt row ':' with Some colon -> colon | None -> fail 0 "missing row separator" in
  for index = 0 to colon - 1 do
    match row.[index] with '0' .. '9' | 'a' .. 'f' | 'A' .. 'F' -> () | _ -> fail index "invalid row ID"
  done;
  let payload = colon + 1 in
  if payload = length then fail payload "missing row payload";
  let offset, model =
    match row.[payload] with
    | 'I' | 'E' -> (payload + 1, false)
    | 'H' ->
        if payload + 1 >= length || not (List.mem row.[payload + 1] [ 'D'; 'C'; 'L'; 'm'; 'X'; 'S'; 'M' ]) then
          fail payload "invalid hint code";
        (payload + 2, false)
    | _ -> (payload, true)
  in
  if colon = 0 && row.[payload] <> 'H' then fail 0 "model, import, and error rows need an ID";
  let parsed = try parse row offset with Yojson.Json_error message -> fail offset message in
  (match (row.[payload], parsed.kind) with
  | 'I', Array _ | 'E', Object _ | 'H', (String _ | Array _) -> ()
  | ('I' | 'E' | 'H'), _ -> fail offset "invalid tagged row payload"
  | _ -> ());
  let token node = String.sub row node.start (node.finish - node.start) in
  let removals = ref [] in
  let rec visit node =
    match node.kind with
    | Array (({ kind = String "$"; _ } :: _ as items), commas) -> (
        match items with
        | [ _; tag; key; props; owner; stack; validation ] ->
            (match tag.kind with String value when value <> "" -> () | _ -> fail tag.start "invalid element type");
            (match key.kind with
            | String _ -> ()
            | Scalar when token key = "null" -> ()
            | _ -> fail key.start "invalid element key");
            (match props.kind with Object _ -> () | _ -> fail props.start "element props must be an object");
            if token owner <> "null" then fail owner.start "production owner must be null";
            if token stack <> "null" then fail stack.start "production stack must be null";
            if not (List.mem (token validation) [ "0"; "1"; "2" ]) then
              fail validation.start "validation must be integer 0, 1, or 2";
            removals := (List.nth commas 3, validation.finish) :: !removals;
            visit props
        | _ -> fail node.start "native element tuple must have exactly seven fields")
    | Array (items, _) | Object items -> List.iter visit items
    | String _ | Scalar -> ()
  in
  if model then visit parsed;
  let output = Buffer.create length in
  let copied = ref 0 in
  List.sort compare !removals
  |> List.iter (fun (start, finish) ->
      Buffer.add_substring output row !copied (start - !copied);
      copied := finish);
  Buffer.add_substring output row !copied (length - !copied);
  Buffer.contents output
