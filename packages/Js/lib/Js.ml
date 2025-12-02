(** The Js equivalent library (very unsafe) *)

include Js_internal

type 'a t = < .. > as 'a

module Fn = struct
  type 'a arity0 = { i0 : unit -> 'a [@internal] }
  type 'a arity1 = { i1 : 'a [@internal] }
  type 'a arity2 = { i2 : 'a [@internal] }
  type 'a arity3 = { i3 : 'a [@internal] }
  type 'a arity4 = { i4 : 'a [@internal] }
  type 'a arity5 = { i5 : 'a [@internal] }
  type 'a arity6 = { i6 : 'a [@internal] }
  type 'a arity7 = { i7 : 'a [@internal] }
  type 'a arity8 = { i8 : 'a [@internal] }
  type 'a arity9 = { i9 : 'a [@internal] }
  type 'a arity10 = { i10 : 'a [@internal] }
  type 'a arity11 = { i11 : 'a [@internal] }
  type 'a arity12 = { i12 : 'a [@internal] }
  type 'a arity13 = { i13 : 'a [@internal] }
  type 'a arity14 = { i14 : 'a [@internal] }
  type 'a arity15 = { i15 : 'a [@internal] }
  type 'a arity16 = { i16 : 'a [@internal] }
  type 'a arity17 = { i17 : 'a [@internal] }
  type 'a arity18 = { i18 : 'a [@internal] }
  type 'a arity19 = { i19 : 'a [@internal] }
  type 'a arity20 = { i20 : 'a [@internal] }
  type 'a arity21 = { i21 : 'a [@internal] }
  type 'a arity22 = { i22 : 'a [@internal] }
end

(**/**)

(* module MapperRt = Js_mapperRt *)
module Internal = struct
  (* open Fn *)

  (* Use opaque instead of [._n] to prevent some optimizations happening *)
end

(**/**)

type +'a null = 'a Js_internal.null
type +'a undefined = 'a Js_internal.undefined
type +'a nullable = 'a Js_internal.nullable

external toOption : 'a null -> 'a option = "%identity"
external nullToOption : 'a null -> 'a option = "%identity"
external undefinedToOption : 'a null -> 'a option = "%identity"
external fromOpt : 'a option -> 'a undefined = "%identity"

(** The same as [empty] {!Js.Undefined} will be compiled as [undefined]*)
let undefined = None

(** The same as [empty] in {!Js.Null} will be compiled as [null]*)
let null = None

let empty = None

type (+'a, +'e) promise

(* external eqNull : 'a -> 'a null -> bool = "%bs_equal_null" *)
(* let eqNull : 'a -> 'a null -> bool = fun x -> x == None *)

(* external eqUndefined : 'a -> 'a undefined -> bool = "%bs_equal_undefined" *)
(* let eqUndefined : 'a -> 'a undefined -> bool = function
   | Some _ -> false
   | None -> true *)

(* external eqNullable : 'a -> 'a nullable -> bool = "%bs_equal_nullable" *)
(* let eqNullable : 'a -> 'a nullable -> bool = function
   | Some _ -> false
   | None -> true *)

(** [typeof x] will be compiled as [typeof x] in JS Please consider functions in {!Types} for a type safe way of
    reflection *)
let typeof _ = notImplemented "Js" "typeof"

(** {4 operators}*)

(* external unsafe_lt : 'a -> 'a -> bool = "#unsafe_lt" *)
(** [unsafe_lt a b] will be compiled as [a < b]. It is marked as unsafe, since it is impossible to give a proper
    semantics for comparision which applies to any type *)

(* external unsafe_le : 'a -> 'a -> bool = "#unsafe_le" *)
(** [unsafe_le a b] will be compiled as [a <= b]. See also {!unsafe_lt} *)

(* external unsafe_gt : 'a -> 'a -> bool = "#unsafe_gt" *)
(** [unsafe_gt a b] will be compiled as [a > b]. See also {!unsafe_lt} *)

(* external unsafe_ge : 'a -> 'a -> bool = "#unsafe_ge" *)
(** [unsafe_ge a b] will be compiled as [a >= b]. See also {!unsafe_lt} *)

(** {12 nested modules}*)

module Null = Js_null
module Undefined = Js_undefined
module Nullable = Js_nullable
module Null_undefined = Nullable
module Exn = Js_exn
module Array = Js_array
module Re = Js_re
module String = Js_string
module Promise = Js_promise
module Date = Js_date
module Dict = Js_dict
module Global = Js_global
module Types = Js_types
module Json = Js_json
module Math = Js_math
module Obj = Js_obj
module Typed_array = Js_typed_array
module TypedArray2 = Js_typed_array2
module Float = Js_float
module Int = Js_int
module Bigint = Js_bigint
module Vector = Js_vector
module Console = Js_console

let log = Console.log
let log2 = Console.log2
let log3 = Console.log3
let log4 = Console.log4
let logMany = Console.logMany

module Set = Js_set
module WeakSet = Js_weakset
module Map = Js_map
module WeakMap = Js_weakmap
module FormData = Js_formdata
