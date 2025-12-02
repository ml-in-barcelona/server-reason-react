type t

type exn +=
  | Error of string
  | EvalError of string
  | RangeError of string
  | ReferenceError of string
  | SyntaxError of string
  | TypeError of string
  | UriError of string

val asJsExn : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val stack : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val message : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val name : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val fileName : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val anyToExnInternal : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val isCamlExceptionOrOpenVariant : 'a -> 'b
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val raiseError : string -> 'a
val raiseEvalError : string -> 'a
val raiseRangeError : string -> 'a
val raiseReferenceError : string -> 'a
val raiseSyntaxError : string -> 'a
val raiseTypeError : string -> 'a
val raiseUriError : string -> 'a
