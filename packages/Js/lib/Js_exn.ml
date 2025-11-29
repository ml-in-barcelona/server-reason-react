type t

type exn +=
  | Error of string
  | EvalError of string
  | RangeError of string
  | ReferenceError of string
  | SyntaxError of string
  | TypeError of string
  | UriError of string

let asJsExn _ = Js_internal.notImplemented "Js.Exn" "asJsExn"
let stack _ = Js_internal.notImplemented "Js.Exn" "stack"
let message _ = Js_internal.notImplemented "Js.Exn" "message"
let name _ = Js_internal.notImplemented "Js.Exn" "name"
let fileName _ = Js_internal.notImplemented "Js.Exn" "fileName"
let anyToExnInternal _ = Js_internal.notImplemented "Js.Exn" "anyToExnInternal"
let isCamlExceptionOrOpenVariant _ = Js_internal.notImplemented "Js.Exn" "isCamlExceptionOrOpenVariant"
let raiseError str = raise (Error str)
let raiseEvalError str = raise (EvalError str)
let raiseRangeError str = raise (RangeError str)
let raiseReferenceError str = raise (ReferenceError str)
let raiseSyntaxError str = raise (SyntaxError str)
let raiseTypeError str = raise (TypeError str)
let raiseUriError str = raise (UriError str)
