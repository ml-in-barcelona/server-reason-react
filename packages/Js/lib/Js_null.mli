type 'a t = 'a Js_internal.nullable

external toOption : 'a t -> 'a Js_internal.nullable = "%identity"
external fromOpt : 'a Js_internal.nullable -> 'a t = "%identity"
val empty : 'a Js_internal.nullable
val return : 'a -> 'a Js_internal.nullable
val getUnsafe : 'a t -> 'a
val test : 'a Js_internal.nullable -> bool
val getExn : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val bind : 'a -> 'b -> 'c [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val iter : 'a -> 'b -> 'c [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val fromOption : 'a Js_internal.nullable -> 'a t
val from_opt : 'a Js_internal.nullable -> 'a t
