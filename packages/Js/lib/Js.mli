(** The Js equivalent library (very unsafe) *)

include module type of Js_internal

type 'a t = 'a constraint 'a = < .. >

module Fn : sig
  type 'a arity0 = { i0 : unit -> 'a }
  type 'a arity1 = { i1 : 'a }
  type 'a arity2 = { i2 : 'a }
  type 'a arity3 = { i3 : 'a }
  type 'a arity4 = { i4 : 'a }
  type 'a arity5 = { i5 : 'a }
  type 'a arity6 = { i6 : 'a }
  type 'a arity7 = { i7 : 'a }
  type 'a arity8 = { i8 : 'a }
  type 'a arity9 = { i9 : 'a }
  type 'a arity10 = { i10 : 'a }
  type 'a arity11 = { i11 : 'a }
  type 'a arity12 = { i12 : 'a }
  type 'a arity13 = { i13 : 'a }
  type 'a arity14 = { i14 : 'a }
  type 'a arity15 = { i15 : 'a }
  type 'a arity16 = { i16 : 'a }
  type 'a arity17 = { i17 : 'a }
  type 'a arity18 = { i18 : 'a }
  type 'a arity19 = { i19 : 'a }
  type 'a arity20 = { i20 : 'a }
  type 'a arity21 = { i21 : 'a }
  type 'a arity22 = { i22 : 'a }
end

external toOption : 'a null -> 'a option = "%identity"
external nullToOption : 'a null -> 'a option = "%identity"
external undefinedToOption : 'a null -> 'a option = "%identity"
external fromOpt : 'a option -> 'a undefined = "%identity"
val undefined : 'a option
val null : 'a option
val empty : 'a option

type (+'a, +'e) promise

val typeof : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

module Null : module type of Js_null
module Undefined : module type of Js_undefined
module Nullable : module type of Js_nullable
module Null_undefined = Nullable
module Exn : module type of Js_exn
module Array : module type of Js_array
module Re : module type of Js_re
module String : module type of Js_string
module Promise : module type of Js_promise
module Date : module type of Js_date
module Dict : module type of Js_dict
module Global : module type of Js_global
module Types : module type of Js_types
module Json : module type of Js_json
module Math : module type of Js_math
module Obj : module type of Js_obj
module Typed_array : module type of Js_typed_array
module TypedArray2 : module type of Js_typed_array2
module Float : module type of Js_float
module Int : module type of Js_int
module Bigint : module type of Js_bigint
module Vector : module type of Js_vector
module Console : module type of Js_console

val log : string -> unit
val log2 : string -> string -> unit
val log3 : string -> string -> string -> unit
val log4 : string -> string -> string -> string -> unit
val logMany : string array -> unit

module Set : module type of Js_set
module WeakSet : module type of Js_weakset
module Map : module type of Js_map
module WeakMap : module type of Js_weakmap
module FormData : module type of Js_formdata
