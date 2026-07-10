type t = { name : string; message : string option; stack : string option; fileName : string option }

type exn +=
  | Error of string
  | EvalError of string
  | RangeError of string
  | ReferenceError of string
  | SyntaxError of string
  | TypeError of string
  | UriError of string

let make name message = { name; message = Some message; stack = None; fileName = None }

let asJsExn (exn : exn) : t option =
  match exn with
  | Error message -> Some (make "Error" message)
  | EvalError message -> Some (make "EvalError" message)
  | RangeError message -> Some (make "RangeError" message)
  | ReferenceError message -> Some (make "ReferenceError" message)
  | SyntaxError message -> Some (make "SyntaxError" message)
  | TypeError message -> Some (make "TypeError" message)
  | UriError message -> Some (make "URIError" message)
  | _ -> None

let stack (t : t) = t.stack
let message (t : t) = t.message
let name (t : t) = Some t.name
let fileName (t : t) = t.fileName
let anyToExnInternal _ = Js_internal.notImplemented "Js.Exn" "anyToExnInternal"
let isCamlExceptionOrOpenVariant _ = Js_internal.notImplemented "Js.Exn" "isCamlExceptionOrOpenVariant"
let raiseError str = raise (Error str)
let raiseEvalError str = raise (EvalError str)
let raiseRangeError str = raise (RangeError str)
let raiseReferenceError str = raise (ReferenceError str)
let raiseSyntaxError str = raise (SyntaxError str)
let raiseTypeError str = raise (TypeError str)
let raiseUriError str = raise (UriError str)
