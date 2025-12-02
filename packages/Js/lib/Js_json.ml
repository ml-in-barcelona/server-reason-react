(* Efficient JSON encoding using JavaScript API *)

type t

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

let classify (_x : t) : tagged_t = Js_internal.notImplemented "Js.Json" "classify"
let test _ : bool = Js_internal.notImplemented "Js.Json" "test"
let decodeString _json = Js_internal.notImplemented "Js.Json" "decodeString"
let decodeNumber _json = Js_internal.notImplemented "Js.Json" "decodeNumber"
let decodeObject _json = Js_internal.notImplemented "Js.Json" "decodeObject"
let decodeArray _json = Js_internal.notImplemented "Js.Json" "decodeArray"
let decodeBoolean (_json : t) = Js_internal.notImplemented "Js.Json" "decodeBoolean"
let decodeNull _json = Js_internal.notImplemented "Js.Json" "decodeNull"
let parseExn _ = Js_internal.notImplemented "Js.Json" "parseExn"
let stringifyAny _ = Js_internal.notImplemented "Js.Json" "stringifyAny"
let null _ = Js_internal.notImplemented "Js.Json" "null"
let string _ = Js_internal.notImplemented "Js.Json" "string"
let number _ = Js_internal.notImplemented "Js.Json" "number"
let boolean _ = Js_internal.notImplemented "Js.Json" "boolean"
let object_ _ = Js_internal.notImplemented "Js.Json" "object_"
let array _ = Js_internal.notImplemented "Js.Json" "array"
let stringArray _ = Js_internal.notImplemented "Js.Json" "stringArray"
let numberArray _ = Js_internal.notImplemented "Js.Json" "numberArray"
let booleanArray _ = Js_internal.notImplemented "Js.Json" "booleanArray"
let objectArray _ = Js_internal.notImplemented "Js.Json" "objectArray"
let stringify _ = Js_internal.notImplemented "Js.Json" "stringify"
let stringifyWithSpace _ = Js_internal.notImplemented "Js.Json" "stringifyWithSpace"
let patch _ = Js_internal.notImplemented "Js.Json" "patch"
let serializeExn (_x : t) : string = Js_internal.notImplemented "Js.Json" "serializeExn"
let deserializeUnsafe (_s : string) : 'a = Js_internal.notImplemented "Js.Json" "deserializeUnsafe"
