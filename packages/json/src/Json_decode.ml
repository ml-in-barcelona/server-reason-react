open Yojson.Basic.Util

exception DecodeError of string
exception Not_implemented of string

let raiseOnYojsonDecodeError tryValue =
  try tryValue ()
  with Yojson.Basic.Util.Type_error (msg, _) -> raise @@ DecodeError msg

let notImplemented module_ function_ =
  raise
    (Not_implemented
       (Printf.sprintf
          "'%s.%s' is not implemented in native on `server-reason-react.json`. \
           You are running code that depends on the browser, this is not \
           supported. If this case should run on native and there's no browser \
           dependency, please open an issue at %s"
          module_ function_
          "https://github.com/ml-in-barcelona/server-reason-react/issues"))

type t = Yojson.Basic.t

let date _ = notImplemented "Json.Decode" "date"
let id json = json
let string value = raiseOnYojsonDecodeError @@ fun () -> value |> to_string
let int value = raiseOnYojsonDecodeError @@ fun () -> value |> to_int
let float value = raiseOnYojsonDecodeError @@ fun () -> value |> to_float
let bool value = raiseOnYojsonDecodeError @@ fun () -> value |> to_bool

let list decodeFn value =
  (raiseOnYojsonDecodeError @@ fun () -> value |> to_list) |> List.map decodeFn

let char value =
  String.get (raiseOnYojsonDecodeError @@ fun () -> value |> to_string) 0

let nullable decode : t -> 'a = function
  | `Null -> None
  | e -> Some (raiseOnYojsonDecodeError @@ fun () -> decode e)

let optional (decode : t -> 'a) json =
  try Some (decode json) with DecodeError _ -> None

let array decodeFn value =
  raiseOnYojsonDecodeError @@ fun () ->
  value |> to_list |> Array.of_list |> Array.map decodeFn

let pair decodeFnA decodeFnB value =
  let pairList = value |> to_list in
  let length = List.length pairList in
  if length = 2 then
    try (decodeFnA (List.nth pairList 0), decodeFnB (List.nth pairList 1))
    with DecodeError msg -> raise @@ DecodeError (msg ^ "\n\tin pair/tuple2")
  else
    raise
      (DecodeError
         (Printf.sprintf "Expected array of length 2, got array of length %s"
            (length |> Int.to_string)))

let tuple3 decodeFnA decodeFnB decodeFnC value =
  let tuple3List = value |> to_list in
  let length = List.length tuple3List in
  if length = 3 then
    try
      ( decodeFnA (List.nth tuple3List 0),
        decodeFnB (List.nth tuple3List 1),
        decodeFnC (List.nth tuple3List 2) )
    with DecodeError msg -> raise @@ DecodeError (msg ^ "\n\tin tuple3")
  else
    raise
      (DecodeError
         (Printf.sprintf "Expected array of length 3, got array of length %s"
            (length |> Int.to_string)))

let tuple4 decodeFnA decodeFnB decodeFnC decodeFnD value =
  let tuple4List = value |> to_list in
  let length = List.length tuple4List in
  if length = 4 then
    try
      ( decodeFnA (List.nth tuple4List 0),
        decodeFnB (List.nth tuple4List 1),
        decodeFnC (List.nth tuple4List 2),
        decodeFnD (List.nth tuple4List 3) )
    with DecodeError msg -> raise @@ DecodeError (msg ^ "\n\tin tuple3")
  else
    raise
      (DecodeError
         (Printf.sprintf "Expected array of length 4, got array of length %s"
            (length |> Int.to_string)))

let field fieldName (decoder : t -> 'a) json =
  match json with
  | `Assoc values -> (
      match List.find_opt (fun (key, _) -> key == fieldName) values with
      | Some (key, value) -> (
          try decoder value
          with DecodeError msg ->
            raise @@ DecodeError (msg ^ "\n\tat field '" ^ key ^ "'"))
      | None ->
          raise @@ DecodeError (Printf.sprintf "Expected field '%s'" fieldName))
  | json ->
      raise @@ DecodeError ("Expected object, got " ^ Yojson.Basic.show json)

let withDefault default decode json =
  try decode json with DecodeError _ -> default

let dict decode = function
  | `Assoc fields ->
      let target = Js.Dict.empty () in
      let rec applyValue = function
        | [] -> ()
        | hd :: rest ->
            let key, value = hd in
            let value =
              try decode value
              with DecodeError msg ->
                raise @@ DecodeError (msg ^ "\n\tin dict")
            in
            Js.Dict.set target key value;
            applyValue rest
      in

      applyValue fields;
      target
  | value ->
      raise @@ DecodeError ("Expected `Assoc, got " ^ Yojson.Basic.show value)

let rec at key_path decoder =
  match key_path with
  | [ key ] -> field key decoder
  | first :: rest -> field first (at rest decoder)
  | [] ->
      raise
      @@ Invalid_argument "Expected key_path to contain at least one element"

let oneOf decoders json =
  let rec inner decoders errors =
    match decoders with
    | [] ->
        let formattedErrors = "\n- " ^ String.concat "\n- " (List.rev errors) in
        raise
        @@ DecodeError
             (Printf.sprintf
                "All decoders given to oneOf failed. Here are all the errors: %s\n\
                 And the JSON being decoded: %s" formattedErrors
                (Yojson.Basic.to_string json))
    | decode :: rest -> (
        try decode json with DecodeError e -> inner rest (e :: errors))
  in
  inner decoders []

let either a b = oneOf [ a; b ]
let map f decode json = f (decode json)
let andThen b a (json : t) = b (a json) json
