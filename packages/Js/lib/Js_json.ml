(* JSON encoding/decoding with JSON.parse / JSON.stringify semantics (ECMA-404
   grammar, ECMA-262 JSON.stringify serialization). *)

type t =
  | JsonNull
  | JsonBoolean of bool
  | JsonNumber of float
  | JsonString of string
  | JsonObject of t Js_dict.t
  | JsonArray of t array

type _ kind =
  | String : Js_string.t kind
  | Number : float kind
  | Object : t Js_dict.t kind
  | Array : t array kind
  | Boolean : bool kind
  | Null : Js_types.null_val kind

type tagged_t =
  | JSONFalse
  | JSONTrue
  | JSONNull
  | JSONString of string
  | JSONNumber of float
  | JSONObject of t Js_dict.t
  | JSONArray of t array

let classify (x : t) : tagged_t =
  match x with
  | JsonNull -> JSONNull
  | JsonBoolean false -> JSONFalse
  | JsonBoolean true -> JSONTrue
  | JsonNumber n -> JSONNumber n
  | JsonString s -> JSONString s
  | JsonObject o -> JSONObject o
  | JsonArray a -> JSONArray a

(* Melange's [test] takes any ['a]; natively values carry no runtime type
   information, so the first argument is narrowed to [t]. *)
let test (type a) (x : t) (kind : a kind) : bool =
  match (x, kind) with
  | JsonString _, String -> true
  | JsonNumber _, Number -> true
  | JsonObject _, Object -> true
  | JsonArray _, Array -> true
  | JsonBoolean _, Boolean -> true
  | JsonNull, Null -> true
  | _ -> false

let decodeString (json : t) = match json with JsonString s -> Some s | _ -> None
let decodeNumber (json : t) = match json with JsonNumber n -> Some n | _ -> None
let decodeObject (json : t) = match json with JsonObject o -> Some o | _ -> None
let decodeArray (json : t) = match json with JsonArray a -> Some a | _ -> None
let decodeBoolean (json : t) = match json with JsonBoolean b -> Some b | _ -> None
let decodeNull (json : t) : 'a Js_null.t option = match json with JsonNull -> Some Js_null.empty | _ -> None
let null : t = JsonNull
let string (s : string) : t = JsonString s
let number (n : float) : t = JsonNumber n
let boolean (b : bool) : t = JsonBoolean b
let object_ (o : t Js_dict.t) : t = JsonObject o
let array (a : t array) : t = JsonArray a
let stringArray (a : string array) : t = JsonArray (Stdlib.Array.map (fun s -> JsonString s) a)
let numberArray (a : float array) : t = JsonArray (Stdlib.Array.map (fun n -> JsonNumber n) a)
let booleanArray (a : bool array) : t = JsonArray (Stdlib.Array.map (fun b -> JsonBoolean b) a)
let objectArray (a : t Js_dict.t array) : t = JsonArray (Stdlib.Array.map (fun o -> JsonObject o) a)

(* ---------------------------------------------------------------------------
   JSON.parse: strict ECMA-404 recursive descent parser.
   Raises Js_exn.SyntaxError like JSON.parse raises a SyntaxError. *)

exception Syntax_error of string

let parse (input : string) : t =
  let len = Stdlib.String.length input in
  let pos = ref 0 in
  let error msg = raise (Syntax_error (Printf.sprintf "%s in JSON at position %d" msg !pos)) in
  let peek () = if !pos < len then Some (Stdlib.String.unsafe_get input !pos) else None in
  let advance () = incr pos in
  let skip_whitespace () =
    while
      !pos < len && match Stdlib.String.unsafe_get input !pos with ' ' | '\t' | '\n' | '\r' -> true | _ -> false
    do
      advance ()
    done
  in
  let expect c =
    match peek () with
    | Some got when got = c -> advance ()
    | Some got -> error (Printf.sprintf "Unexpected token %c" got)
    | None -> error "Unexpected end of JSON input"
  in
  let expect_literal lit value =
    if !pos + Stdlib.String.length lit <= len && Stdlib.String.sub input !pos (Stdlib.String.length lit) = lit then begin
      pos := !pos + Stdlib.String.length lit;
      value
    end
    else error "Unexpected token"
  in
  let utf8_encode buf code =
    (* code is a Unicode scalar value (or an unpaired surrogate, encoded as-is
       like JS engines do when producing WTF-8-ish output; we use U+FFFD for
       unpaired surrogates to keep strings valid UTF-8). *)
    let code = if code >= 0xD800 && code <= 0xDFFF then 0xFFFD else code in
    if code < 0x80 then Stdlib.Buffer.add_char buf (Stdlib.Char.chr code)
    else if code < 0x800 then begin
      Stdlib.Buffer.add_char buf (Stdlib.Char.chr (0xC0 lor (code lsr 6)));
      Stdlib.Buffer.add_char buf (Stdlib.Char.chr (0x80 lor (code land 0x3F)))
    end
    else if code < 0x10000 then begin
      Stdlib.Buffer.add_char buf (Stdlib.Char.chr (0xE0 lor (code lsr 12)));
      Stdlib.Buffer.add_char buf (Stdlib.Char.chr (0x80 lor ((code lsr 6) land 0x3F)));
      Stdlib.Buffer.add_char buf (Stdlib.Char.chr (0x80 lor (code land 0x3F)))
    end
    else begin
      Stdlib.Buffer.add_char buf (Stdlib.Char.chr (0xF0 lor (code lsr 18)));
      Stdlib.Buffer.add_char buf (Stdlib.Char.chr (0x80 lor ((code lsr 12) land 0x3F)));
      Stdlib.Buffer.add_char buf (Stdlib.Char.chr (0x80 lor ((code lsr 6) land 0x3F)));
      Stdlib.Buffer.add_char buf (Stdlib.Char.chr (0x80 lor (code land 0x3F)))
    end
  in
  let parse_hex4 () =
    if !pos + 4 > len then error "Unexpected end of JSON input";
    let value = ref 0 in
    for _ = 1 to 4 do
      let c = Stdlib.String.unsafe_get input !pos in
      let digit =
        match c with
        | '0' .. '9' -> Stdlib.Char.code c - Stdlib.Char.code '0'
        | 'a' .. 'f' -> Stdlib.Char.code c - Stdlib.Char.code 'a' + 10
        | 'A' .. 'F' -> Stdlib.Char.code c - Stdlib.Char.code 'A' + 10
        | _ -> error "Bad Unicode escape"
      in
      value := (!value * 16) + digit;
      advance ()
    done;
    !value
  in
  let parse_string () =
    expect '"';
    let buf = Stdlib.Buffer.create 16 in
    let rec loop () =
      match peek () with
      | None -> error "Unterminated string"
      | Some '"' -> advance ()
      | Some '\\' ->
          advance ();
          (match peek () with
          | Some '"' ->
              Stdlib.Buffer.add_char buf '"';
              advance ()
          | Some '\\' ->
              Stdlib.Buffer.add_char buf '\\';
              advance ()
          | Some '/' ->
              Stdlib.Buffer.add_char buf '/';
              advance ()
          | Some 'b' ->
              Stdlib.Buffer.add_char buf '\b';
              advance ()
          | Some 'f' ->
              Stdlib.Buffer.add_char buf '\012';
              advance ()
          | Some 'n' ->
              Stdlib.Buffer.add_char buf '\n';
              advance ()
          | Some 'r' ->
              Stdlib.Buffer.add_char buf '\r';
              advance ()
          | Some 't' ->
              Stdlib.Buffer.add_char buf '\t';
              advance ()
          | Some 'u' ->
              advance ();
              let code = parse_hex4 () in
              (* Combine surrogate pairs into a single scalar value. *)
              if
                code >= 0xD800 && code <= 0xDBFF
                && !pos + 1 < len
                && Stdlib.String.unsafe_get input !pos = '\\'
                && Stdlib.String.unsafe_get input (!pos + 1) = 'u'
              then begin
                let saved = !pos in
                pos := !pos + 2;
                let low = parse_hex4 () in
                if low >= 0xDC00 && low <= 0xDFFF then
                  utf8_encode buf (0x10000 + ((code - 0xD800) * 0x400) + (low - 0xDC00))
                else begin
                  pos := saved;
                  utf8_encode buf code
                end
              end
              else utf8_encode buf code
          | _ -> error "Bad escaped character");
          loop ()
      | Some c when Stdlib.Char.code c < 0x20 -> error "Bad control character in string literal"
      | Some c ->
          Stdlib.Buffer.add_char buf c;
          advance ();
          loop ()
    in
    loop ();
    Stdlib.Buffer.contents buf
  in
  let parse_number () =
    let start = !pos in
    if peek () = Some '-' then advance ();
    (match peek () with
    | Some '0' -> advance ()
    | Some '1' .. '9' ->
        while !pos < len && match Stdlib.String.unsafe_get input !pos with '0' .. '9' -> true | _ -> false do
          advance ()
        done
    | _ -> error "No number after minus sign");
    if peek () = Some '.' then begin
      advance ();
      (match peek () with Some '0' .. '9' -> () | _ -> error "Unterminated fractional number");
      while !pos < len && match Stdlib.String.unsafe_get input !pos with '0' .. '9' -> true | _ -> false do
        advance ()
      done
    end;
    (match peek () with
    | Some ('e' | 'E') ->
        advance ();
        (match peek () with Some ('+' | '-') -> advance () | _ -> ());
        (match peek () with Some '0' .. '9' -> () | _ -> error "Exponent part is missing a number");
        while !pos < len && match Stdlib.String.unsafe_get input !pos with '0' .. '9' -> true | _ -> false do
          advance ()
        done
    | _ -> ());
    Stdlib.float_of_string (Stdlib.String.sub input start (!pos - start))
  in
  let rec parse_value () =
    skip_whitespace ();
    match peek () with
    | None -> error "Unexpected end of JSON input"
    | Some '{' ->
        advance ();
        let dict = Js_dict.empty () in
        skip_whitespace ();
        if peek () = Some '}' then advance ()
        else begin
          let rec members () =
            skip_whitespace ();
            let key = parse_string () in
            skip_whitespace ();
            expect ':';
            let value = parse_value () in
            (* Duplicate keys: JSON.parse keeps the last occurrence. *)
            Js_dict.set dict key value;
            skip_whitespace ();
            match peek () with
            | Some ',' ->
                advance ();
                members ()
            | Some '}' -> advance ()
            | _ -> error "Expected ',' or '}' after property value"
          in
          members ()
        end;
        JsonObject dict
    | Some '[' ->
        advance ();
        skip_whitespace ();
        if peek () = Some ']' then begin
          advance ();
          JsonArray [||]
        end
        else begin
          let items = ref [] in
          let rec elements () =
            let value = parse_value () in
            items := value :: !items;
            skip_whitespace ();
            match peek () with
            | Some ',' ->
                advance ();
                elements ()
            | Some ']' -> advance ()
            | _ -> error "Expected ',' or ']' after array element"
          in
          elements ();
          JsonArray (Stdlib.Array.of_list (Stdlib.List.rev !items))
        end
    | Some '"' -> JsonString (parse_string ())
    | Some 't' -> expect_literal "true" (JsonBoolean true)
    | Some 'f' -> expect_literal "false" (JsonBoolean false)
    | Some 'n' -> expect_literal "null" JsonNull
    | Some ('-' | '0' .. '9') -> JsonNumber (parse_number ())
    | Some c -> error (Printf.sprintf "Unexpected token %c" c)
  in
  let value = parse_value () in
  skip_whitespace ();
  if !pos <> len then error "Unexpected non-whitespace character after JSON";
  value

let parseExn (s : string) : t = try parse s with Syntax_error msg -> Js_exn.raiseSyntaxError msg

(* ---------------------------------------------------------------------------
   JSON.stringify (ECMA-262 SerializeJSONProperty). Numbers are formatted with
   Number::toString via quickjs so output matches JS byte-for-byte. *)

let escape_string buf s =
  Stdlib.Buffer.add_char buf '"';
  Stdlib.String.iter
    (fun c ->
      match c with
      | '"' -> Stdlib.Buffer.add_string buf "\\\""
      | '\\' -> Stdlib.Buffer.add_string buf "\\\\"
      | '\b' -> Stdlib.Buffer.add_string buf "\\b"
      | '\012' -> Stdlib.Buffer.add_string buf "\\f"
      | '\n' -> Stdlib.Buffer.add_string buf "\\n"
      | '\r' -> Stdlib.Buffer.add_string buf "\\r"
      | '\t' -> Stdlib.Buffer.add_string buf "\\t"
      | c when Stdlib.Char.code c < 0x20 -> Stdlib.Buffer.add_string buf (Printf.sprintf "\\u%04x" (Stdlib.Char.code c))
      | c -> Stdlib.Buffer.add_char buf c)
    s;
  Stdlib.Buffer.add_char buf '"'

let number_to_string (n : float) =
  (* JSON.stringify serializes non-finite numbers as null. *)
  if Float.is_nan n || Float.abs n = Float.infinity then "null" else Quickjs.Number.Prototype.to_string n

let stringify_impl (json : t) ~(indent : int) : string =
  let buf = Stdlib.Buffer.create 64 in
  let newline_and_pad level =
    if indent > 0 then begin
      Stdlib.Buffer.add_char buf '\n';
      Stdlib.Buffer.add_string buf (Stdlib.String.make (indent * level) ' ')
    end
  in
  let rec write json level =
    match json with
    | JsonNull -> Stdlib.Buffer.add_string buf "null"
    | JsonBoolean b -> Stdlib.Buffer.add_string buf (if b then "true" else "false")
    | JsonNumber n -> Stdlib.Buffer.add_string buf (number_to_string n)
    | JsonString s -> escape_string buf s
    | JsonArray [||] -> Stdlib.Buffer.add_string buf "[]"
    | JsonArray items ->
        Stdlib.Buffer.add_char buf '[';
        Stdlib.Array.iteri
          (fun i item ->
            if i > 0 then Stdlib.Buffer.add_char buf ',';
            newline_and_pad (level + 1);
            write item (level + 1))
          items;
        newline_and_pad level;
        Stdlib.Buffer.add_char buf ']'
    | JsonObject dict ->
        let entries = Js_dict.entries dict in
        if Stdlib.Array.length entries = 0 then Stdlib.Buffer.add_string buf "{}"
        else begin
          Stdlib.Buffer.add_char buf '{';
          Stdlib.Array.iteri
            (fun i (key, value) ->
              if i > 0 then Stdlib.Buffer.add_char buf ',';
              newline_and_pad (level + 1);
              escape_string buf key;
              Stdlib.Buffer.add_char buf ':';
              if indent > 0 then Stdlib.Buffer.add_char buf ' ';
              write value (level + 1))
            entries;
          newline_and_pad level;
          Stdlib.Buffer.add_char buf '}'
        end
  in
  write json 0;
  Stdlib.Buffer.contents buf

let stringify (json : t) : string = stringify_impl json ~indent:0

(* JSON.stringify clamps the space argument to 10. *)
let stringifyWithSpace (json : t) (space : int) : string = stringify_impl json ~indent:(Stdlib.min space 10)

(* Melange's stringifyAny serializes arbitrary values through the JS runtime;
   natively only [t] values carry enough structure, so this stays unsupported
   (see Js_json.mli: it raises). *)
let stringifyAny _ = Js_internal.notImplemented "Js.Json" "stringifyAny"

(* Melange's patch replaces [undefined] with [null] deep inside a structure.
   Natively [t] cannot contain undefined, so there is nothing to patch. *)
let patch (json : t) : t = json
let serializeExn (_x : t) : string = Js_internal.notImplemented "Js.Json" "serializeExn"
let deserializeUnsafe (_s : string) : 'a = Js_internal.notImplemented "Js.Json" "deserializeUnsafe"
