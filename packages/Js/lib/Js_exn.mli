type t

type exn +=
  | Error of string
  | EvalError of string
  | RangeError of string
  | ReferenceError of string
  | SyntaxError of string
  | TypeError of string
  | UriError of string

val asJsExn : exn -> t option
(** Returns [Some] for the JS-style exceptions raised by the [raise*] functions below, [None] for any other OCaml
    exception, like Melange returns [None] for non-JS exceptions. *)

val stack : t -> string option
(** Always [None]: native exceptions do not capture a JS-style stack trace. *)

val message : t -> string option
val name : t -> string option

val fileName : t -> string option
(** Always [None]: native exceptions do not carry a file name. *)

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
