(* Efficient JSON encoding using JavaScript API *)

type t

type _ kind =
  | String : string kind
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

val classify : t -> tagged_t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val test : 'a -> bool [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val decodeString : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val decodeNumber : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val decodeObject : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val decodeArray : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val decodeBoolean : t -> 'a [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val decodeNull : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val parseExn : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val stringifyAny : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val null : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val string : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val number : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val boolean : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val object_ : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val array : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val stringArray : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val numberArray : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val booleanArray : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val objectArray : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val stringify : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val stringifyWithSpace : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val patch : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val serializeExn : t -> string [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val deserializeUnsafe : string -> 'a
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]
