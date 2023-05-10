(** Types for JS objects *)
(* https://github.com/rescript-lang/rescript-compiler/blob/master/jscomp/runtime/js.ml *)

type 'a t = < .. > as 'a
(** This used to be mark a Js object type.
    It is not needed any more, it is kept here for compatibility reasons
*)

(* internal types for FFI, these types are not used by normal users
    Absent cmi file when looking up module alias.
*)
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

(* module Internal = struct
     open Fn

     external opaqueFullApply : 'a -> 'a = "#full_apply"

     (* Use opaque instead of [._n] to prevent some optimizations happening *)
     external run : 'a arity0 -> 'a = "#run"
     external opaque : 'a -> 'a = "%opaque"
   end *)

(**/**)

include Types

external log : 'a -> unit = "log"
  [@@bs.val] [@@bs.scope "console"]
(** A convenience function to log everything *)

external log2 : 'a -> 'b -> unit = "log" [@@bs.val] [@@bs.scope "console"]
external log3 : 'a -> 'b -> 'c -> unit = "log" [@@bs.val] [@@bs.scope "console"]

external log4 : 'a -> 'b -> 'c -> 'd -> unit = "log"
  [@@bs.val] [@@bs.scope "console"]

external logMany : 'a array -> unit = "log"
  [@@bs.val] [@@bs.scope "console"] [@@bs.splice]
(** A convenience function to log more than 4 arguments *)

(* external eqNull : 'a -> 'a null -> bool = "%bs_equal_null" *)
(* external eqUndefined : 'a -> 'a undefined -> bool = "%bs_equal_undefined" *)
(* external eqNullable : 'a -> 'a nullable -> bool = "%bs_equal_nullable" *)

(** {4 operators }*)

external unsafe_lt : 'a -> 'a -> bool = "#unsafe_lt"
(** [unsafe_lt a b] will be compiled as [a < b].
    It is marked as unsafe, since it is impossible
    to give a proper semantics for comparision which applies to any type
*)

external unsafe_le : 'a -> 'a -> bool = "#unsafe_le"
(**  [unsafe_le a b] will be compiled as [a <= b].
     See also {!unsafe_lt}
*)

external unsafe_gt : 'a -> 'a -> bool = "#unsafe_gt"
(**  [unsafe_gt a b] will be compiled as [a > b].
     See also {!unsafe_lt}
*)

external unsafe_ge : 'a -> 'a -> bool = "#unsafe_ge"
(**  [unsafe_ge a b] will be compiled as [a >= b].
     See also {!unsafe_lt}
*)

(** {12 nested modules}*)

module Null = Js_null
(** Provide utilities around ['a null] *)

module Undefined = Js_undefined
(** Provide utilities around {!undefined} *)

module Nullable = Js_null_undefined
(** Provide utilities around {!null_undefined} *)

module Exn = Js_exn
(** Provide utilities for dealing with Js exceptions *)

(* module Array = Js_array *)
(** Provide bindings to Js array*)

(* module Array2 = Js_array2 *)
(** Provide bindings to Js array*)

(* module String = Js_string *)
(** Provide bindings to JS string *)

(* module String2 = Js_string2 *)
(** Provide bindings to JS string *)

(* module Re = Js_re *)
(** Provide bindings to Js regex expression *)

(* module Promise = Js_promise *)
(** Provide bindings to JS promise *)

(* module Date = Js_date *)
(** Provide bindings for JS Date *)

(* module Dict = Js_dict *)
(** Provide utilities for JS dictionary object *)

(* module Global = Js_global *)
(** Provide bindings to JS global functions in global namespace*)

(* module Json = Js_json *)
(** Provide utilities for json *)

(* module Math = Js_math *)
(** Provide bindings for JS [Math] object *)

(* module Obj = Js_obj *)
(** Provide utilities for {!Js.t} *)

(* module Typed_array = Js_typed_array *)
(** Provide bindings for JS typed array *)

(* module TypedArray2 = Js_typed_array2 *)
(** Provide bindings for JS typed array *)

(* module Types = Js_types *)
(** Provide utilities for manipulating JS types  *)

(* module Float = Js_float *)
(** Provide utilities for JS float *)

(* module Int = Js_int *)
(** Provide utilities for int *)

(* module Bigint = Js_bigint *)
(** Provide utilities for bigint *)

(* module Option = Js_option *)
(** Provide utilities for option *)

(* module Result = Js_result *)
(** Define the interface for result *)

(* module List = Js_list *)
(** Provide utilities for list *)

(* module Vector = Js_vector *)

module Console = Js_console

(* module Set = Js_set *)
(** Provides bindings for ES6 Set *)

(* module WeakSet = Js_weakset *)
(** Provides bindings for ES6 WeakSet *)

(* module Map = Js_map *)
(** Provides bindings for ES6 Map *)

(* module WeakMap = Js_weakmap *)
(** Provides bindings for ES6 WeakMap *)
