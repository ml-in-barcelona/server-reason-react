(** JSON encoding/decoding with JSON.parse / JSON.stringify semantics *)

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

val classify : t -> tagged_t

val test : t -> 'b kind -> bool
(** Note: Melange's [test] accepts any ['a]; natively the first argument is narrowed to [t] because values carry no
    runtime type information. *)

val decodeString : t -> string option
val decodeNumber : t -> float option
val decodeObject : t -> t Js_dict.t option
val decodeArray : t -> t array option
val decodeBoolean : t -> bool option
val decodeNull : t -> 'a Js_null.t option

val parseExn : string -> t
(** @raise Js_exn.SyntaxError if the string is not valid JSON. *)

val stringifyAny : 'a -> string option
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val null : t
val string : string -> t
val number : float -> t
val boolean : bool -> t
val object_ : t Js_dict.t -> t
val array : t array -> t
val stringArray : string array -> t
val numberArray : float array -> t
val booleanArray : bool array -> t
val objectArray : t Js_dict.t array -> t
val stringify : t -> string
val stringifyWithSpace : t -> int -> string
val patch : t -> t
val serializeExn : t -> string [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val deserializeUnsafe : string -> 'a
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]
