type +'a null
(** nullable, value of this type can be either [null] or ['a]
    this type is the same as type [t] in {!Null}
*)

type +'a undefined
(** value of this type can be either [undefined] or ['a]
    this type is the same as type [t] in {!Undefined} *)

type +'a nullable
(** value of this type can be [undefined], [null] or ['a]
    this type is the same as type [t] n {!Null_undefined} *)

type +'a null_undefined = 'a nullable

external toOption : 'a nullable -> 'a option = "#nullable_to_opt"
external undefinedToOption : 'a undefined -> 'a option = "#undefined_to_opt"
external nullToOption : 'a null -> 'a option = "#null_to_opt"
external isNullable : 'a nullable -> bool = "#is_nullable"

external testAny : 'a -> bool = "#is_nullable"
(** The same as {!test} except that it is more permissive on the types of input *)
(* external null : 'a null = "#null" [@@bs.external] *)
(* let empty = Option.get [%bs.external null] *)
(** The same as [empty] in {!Js.Null} will be compiled as [null]*)

(* external undefined : 'a undefined = "#undefined" *)
(* let undefined = Option.get [%bs.external undefined] *)
(** The same as  [empty] {!Js.Undefined} will be compiled as [undefined]*)

external typeof : 'a -> string = "#typeof"
(** [typeof x] will be compiled as [typeof x] in JS
    Please consider functions in {!Types} for a type safe way of reflection
*)
