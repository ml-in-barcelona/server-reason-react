(** Provide utilities for Vector *)

type 'a t = 'a array

let filterInPlace _ = Js_internal.notImplemented "Js.Vector" "filterInPlace"
let empty _ = Js_internal.notImplemented "Js.Vector" "empty"
let pushBack _ = Js_internal.notImplemented "Js.Vector" "pushBack"
let copy _ = Js_internal.notImplemented "Js.Vector" "copy"
let memByRef _ = Js_internal.notImplemented "Js.Vector" "memByRef"
let iter _ = Js_internal.notImplemented "Js.Vector" "iter"
let iteri _ = Js_internal.notImplemented "Js.Vector" "iteri"
let toList _ = Js_internal.notImplemented "Js.Vector" "toList"
let map _ = Js_internal.notImplemented "Js.Vector" "map"
let mapi _ = Js_internal.notImplemented "Js.Vector" "mapi"
let foldLeft _ = Js_internal.notImplemented "Js.Vector" "foldLeft"
let foldRight _ = Js_internal.notImplemented "Js.Vector" "foldRight"

external length : 'a t -> int = "%array_length"
external get : 'a t -> int -> 'a = "%array_safe_get"
external set : 'a t -> int -> 'a -> unit = "%array_safe_set"
external make : int -> 'a -> 'a t = "caml_make_vect"

let init _ = Js_internal.notImplemented "Js.Vector" "init"
let append _ = Js_internal.notImplemented "Js.Vector" "append"

external unsafe_get : 'a t -> int -> 'a = "%array_unsafe_get"
external unsafe_set : 'a t -> int -> 'a -> unit = "%array_unsafe_set"
