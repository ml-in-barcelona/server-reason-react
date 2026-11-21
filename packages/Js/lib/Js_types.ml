type symbol
type bigint_val
type obj_val
type undefined_val
type null_val
type function_val

type _ t =
  | Undefined : undefined_val t
  | Null : null_val t
  | Boolean : bool t
  | Number : float t
  | String : string t
  | Function : function_val t
  | Object : obj_val t
  | Symbol : symbol t
  | BigInt : bigint_val t

let test _ _ = Js_internal.notImplemented "Js.Types" "test"

type tagged_t =
  | JSFalse
  | JSTrue
  | JSNull
  | JSUndefined
  | JSNumber of float
  | JSString of string
  | JSFunction of function_val
  | JSObject of obj_val
  | JSSymbol of symbol
  | JSBigInt of bigint_val

let classify _ = Js_internal.notImplemented "Js.Types" "classify"
