exception Not_implemented of string

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

let date _ : t = notImplemented "Json.Encode" "date"
let nullable encode : 'a -> t = function Some a -> encode a | _ -> `Null
let string value : t = `String value
let int value : t = `Int value
let bool value : t = `Bool value
let float value : t = `Float value

let dict encode d : t =
  let pairs = Js.Dict.entries d in
  let encodedPairs = Array.map (fun (k, v) -> (k, encode v)) pairs in
  `Assoc (encodedPairs |> Array.to_list)

let list value encode : t =
  match value with
  | [] -> `List []
  | list -> `List (List.map (fun value -> encode value) list)

let array value encode : t =
  let list = Array.to_list value in
  match list with
  | [] -> `List []
  | list -> `List (List.map (fun value -> encode value) list)

let pair value encodeA encodeB : t =
  let a, b = value in
  `List [ encodeA a; encodeB b ]

let tuple3 value encodeA encodeB encodeC : t =
  let a, b, c = value in
  `List [ encodeA a; encodeB b; encodeC c ]

let tuple4 value encodeA encodeB encodeC encodeD : t =
  let a, b, c, d = value in
  `List [ encodeA a; encodeB b; encodeC c; encodeD d ]

let stringArray value = array value string
let intArray value = array value int
let boolArray value = array value bool
