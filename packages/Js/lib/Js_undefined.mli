type 'a t = 'a Js_internal.nullable

external return : 'a -> 'a t = "%identity"
val empty : 'a Js_internal.nullable
external toOption : 'a t -> 'a Js_internal.nullable = "%identity"
external fromOpt : 'a Js_internal.nullable -> 'a t = "%identity"
val getExn : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getUnsafe : 'a t -> 'a
val bind : 'a -> 'b -> 'c [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val iter : 'a -> 'b -> 'c [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val testAny : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val test : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val fromOption : 'a Js_internal.nullable -> 'a t
val from_opt : 'a Js_internal.nullable -> 'a t
