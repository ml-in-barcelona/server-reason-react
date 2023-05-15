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
(* module Internal = struct
     open Fn
     external opaqueFullApply : 'a -> 'a = "#full_apply"

     (* Use opaque instead of [._n] to prevent some optimizations happening *)
     external run : 'a arity0 -> 'a = "#run"
     external opaque : 'a -> 'a = "%opaque"

   end *)
(**/**)

type +'a null = 'a option
type +'a undefined = 'a option
type +'a nullable = 'a option

external toOption : 'a null -> 'a option = "%identity"
external nullToOption : 'a null -> 'a option = "%identity"
external undefinedToOption : 'a null -> 'a option = "%identity"
external fromOpt : 'a option -> 'a undefined = "%identity"

(* external undefined : 'a undefined = "#undefined" *)

(** The same as  [empty] {!Js.Undefined} will be compiled as [undefined]*)
let undefined = None

(* external null : 'a null = "#null" *)

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

(* external typeof : 'a -> string = "#typeof" *)

(** [typeof x] will be compiled as [typeof x] in JS
    Please consider functions in {!Types} for a type safe way of reflection *)
let typeof _ = "TODO"

(** {4 operators }*)

(* external unsafe_lt : 'a -> 'a -> bool = "#unsafe_lt" *)
(** [unsafe_lt a b] will be compiled as [a < b].
    It is marked as unsafe, since it is impossible
    to give a proper semantics for comparision which applies to any type *)

(* external unsafe_le : 'a -> 'a -> bool = "#unsafe_le" *)
(**  [unsafe_le a b] will be compiled as [a <= b].
     See also {!unsafe_lt} *)

(* external unsafe_gt : 'a -> 'a -> bool = "#unsafe_gt" *)
(**  [unsafe_gt a b] will be compiled as [a > b].
     See also {!unsafe_lt} *)

(* external unsafe_ge : 'a -> 'a -> bool = "#unsafe_ge" *)
(**  [unsafe_ge a b] will be compiled as [a >= b].
     See also {!unsafe_lt} *)

(** {12 nested modules}*)

module Null = struct
  type 'a t = 'a null

  external toOption : 'a t -> 'a option = "%identity"
  external fromOpt : 'a option -> 'a t = "%identity"

  let return a = fromOpt (Some a)
  let getUnsafe a = match toOption a with None -> assert false | Some a -> a
end

module Undefined = struct
  type 'a t = 'a undefined

  external return : 'a -> 'a t = "%identity"

  let empty = None

  external toOption : 'a t -> 'a option = "%identity"
  external fromOpt : 'a option -> 'a t = "%identity"
end

module Nullable = struct
  type 'a t = 'a option

  external toOption : 'a t -> 'a option = "%identity"
  external to_opt : 'a t -> 'a option = "%identity"

  let return : 'a -> 'a t = fun x -> Some x
  let isNullable : 'a t -> bool = function Some _ -> false | None -> true
  let null : 'a t = None
  let undefined : 'a t = None

  let bind x f =
    match to_opt x with
    | None -> (Stdlib.Obj.magic (x : 'a t) : 'b t)
    | Some x -> return (f x [@bs])

  let iter x f = match to_opt x with None -> () | Some x -> f x [@bs]
  let fromOption x = match x with None -> undefined | Some x -> return x
  let from_opt = fromOption
end

module Null_undefined = Nullable

module Exn = struct
  type error

  external makeError : string -> error = "%identity"

  let raiseError str = raise (Stdlib.Obj.magic (makeError str : error) : exn)
end

(** Provide bindings to Js array *)
module Array2 = struct
  type 'a t = 'a array
  (** JavaScript Array API *)

  type 'a array_like

  (* commented out until bs has a plan for iterators `type 'a array_iter = 'a array_like`*)

  (* external from : 'a array_like -> 'a array = "Array.from" [@@bs.val] *)
  let from _ _ = failwith "TODO"
  (* ES2015 *)

  (* external fromMap : 'a array_like -> (('a -> 'b)[@bs.uncurry]) -> 'b array = "Array.from" [@@bs.val] *)
  let fromMap _ _ = failwith "TODO"
  (* ES2015 *)

  (* external isArray : 'a -> bool = "Array.isArray" [@@bs.val] *)
  let isArray _ _ = failwith "TODO"

  (* ES2015 *)
  (* ES2015 *)

  (* Array.of: seems pointless unless you can bind *)
  (* external length : 'a array -> int = "length" [@@bs.get] *)
  let length _ _ = failwith "TODO"

  (* Mutator functions *)
  (* external copyWithin : 'a t -> to_:int -> 'a t = "copyWithin" [@@bs.send] *)
  let copyWithin _ _ = failwith "TODO"
  (* ES2015 *)

  (* external copyWithinFrom : 'a t -> to_:int -> from:int -> 'a t = "copyWithin" [@@bs.send] *)
  let copyWithinFrom _ _ = failwith "TODO"
  (* ES2015 *)

  (* external copyWithinFromRange : 'a t -> to_:int -> start:int -> end_:int -> 'a t = "copyWithin" [@@bs.send] *)
  let copyWithinFromRange _ _ = failwith "TODO"
  (* ES2015 *)

  (* external fillInPlace : 'a t -> 'a -> 'a t = "fill" [@@bs.send] (* ES2015 *) *)
  let fillInPlace _ _ = failwith "TODO"

  (* external fillFromInPlace : 'a t -> 'a -> from:int -> 'a t = "fill" [@@bs.send] *)
  let fillFromInPlace _ _ = failwith "TODO"
  (* ES2015 *)

  (* external fillRangeInPlace : 'a t -> 'a -> start:int -> end_:int -> 'a t = "fill" [@@bs.send] *)
  let fillRangeInPlace _ _ = failwith "TODO"
  (* ES2015 *)

  (* external pop : 'a t -> 'a option = "pop" [@@bs.send] [@@bs.return undefined_to_opt] *)

  (** https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/push *)
  let pop _ _ = failwith "TODO"

  (* external push : 'a t -> 'a -> int = "push" [@@bs.send] *)
  let push _ _ = failwith "TODO"

  (* external pushMany : 'a t -> 'a array -> int = "push" [@@bs.send] [@@bs.splice] *)
  let pushMany _ _ = failwith "TODO"

  (* external reverseInPlace : 'a t -> 'a t = "reverse" [@@bs.send] *)
  let reverseInPlace _ _ = failwith "TODO"

  (* external shift : 'a t -> 'a option = "shift" [@@bs.send] [@@bs.return undefined_to_opt] *)
  let shift _ _ = failwith "TODO"

  (* external sortInPlace : 'a t -> 'a t = "sort" [@@bs.send] *)
  let sortInPlace _ _ = failwith "TODO"

  (* external sortInPlaceWith : 'a t -> (('a -> 'a -> int)[@bs.uncurry]) -> 'a t = "sort" [@@bs.send] *)
  let sortInPlaceWith _ _ = failwith "TODO"

  (* external spliceInPlace : 'a t -> pos:int -> remove:int -> add:'a array -> 'a t = "splice" [@@bs.send] [@@bs.splice] *)
  let spliceInPlace _ _ = failwith "TODO"

  (* external removeFromInPlace : 'a t -> pos:int -> 'a t = "splice" [@@bs.send] *)
  let removeFromInPlace _ _ = failwith "TODO"

  (* external removeCountInPlace : 'a t -> pos:int -> count:int -> 'a t = "splice" [@@bs.send] *)
  let removeCountInPlace _ _ = failwith "TODO"
  (* screwy naming, but screwy function *)

  (* external unshift : 'a t -> 'a -> int = "unshift" [@@bs.send] *)
  let unshift _ _ = failwith "TODO"

  (* external unshiftMany : 'a t -> 'a array -> int = "unshift" [@@bs.send] [@@bs.splice] *)
  let unshiftMany _ _ = failwith "TODO"

  (* Accessor functions *)
  (* external append : 'a t -> 'a -> 'a t = "concat" [@@bs.send] [@@deprecated "append is not type-safe. Use `concat` instead, and see #1884"] *)
  let append _ _ = failwith "TODO"

  (* external concat : 'a t -> 'a t -> 'a t = "concat" [@@bs.send] *)
  let concat _ _ = failwith "TODO"

  (* external concatMany : 'a t -> 'a t array -> 'a t = "concat" [@@bs.send] [@@bs.splice] *)
  let concatMany _ _ = failwith "TODO"

  (* TODO: Not available in Node V4  *)
  (* external includes : 'a t -> 'a -> bool = "includes" [@@bs.send] *)

  (** ES2016 *)
  let includes _ _ = failwith "TODO"

  (* external indexOf : 'a t -> 'a -> int = "indexOf" [@@bs.send] *)
  let indexOf _ _ = failwith "TODO"

  (* external indexOfFrom : 'a t -> 'a -> from:int -> int = "indexOf" [@@bs.send] *)
  let indexOfFrom _ _ = failwith "TODO"

  (* external joinWith : 'a t -> string -> string = "join" [@@bs.send] *)
  let joinWith _ _ = failwith "TODO"

  (* external lastIndexOf : 'a t -> 'a -> int = "lastIndexOf" [@@bs.send] *)
  let lastIndexOf _ _ = failwith "TODO"

  (* external lastIndexOfFrom : 'a t -> 'a -> from:int -> int = "lastIndexOf" [@@bs.send] *)
  let lastIndexOfFrom _ _ = failwith "TODO"

  (* external slice : 'a t -> start:int -> end_:int -> 'a t = "slice" [@@bs.send] *)
  let slice _ _ = failwith "TODO"

  (* external copy : 'a t -> 'a t = "slice" [@@bs.send] *)
  let copy _ _ = failwith "TODO"

  (* external sliceFrom : 'a t -> int -> 'a t = "slice" [@@bs.send] *)
  let sliceFrom _ _ = failwith "TODO"

  (* external toString : 'a t -> string = "toString" [@@bs.send] *)
  let toString _ _ = failwith "TODO"

  (* external toLocaleString : 'a t -> string = "toLocaleString" [@@bs.send] *)
  let toLocaleString _ _ = failwith "TODO"

  (* Iteration functions *)
  (* commented out until bs has a plan for iterators external entries : 'a t -> (int * 'a) array_iter = "" [@@bs.send] (* ES2015 *) *)

  (* external every : 'a t -> (('a -> bool)[@bs.uncurry]) -> bool = "every" [@@bs.send] *)
  let every _ _ = failwith "TODO"

  (* external everyi : 'a t -> (('a -> int -> bool)[@bs.uncurry]) -> bool = "every" [@@bs.send] *)
  let everyi _ _ = failwith "TODO"

  (* external filter : 'a t -> (('a -> bool)[@bs.uncurry]) -> 'a t = "filter" [@@bs.send] *)

  (** should we use [bool] or [boolean] seems they are intechangeable here *)
  let filter _ _ = failwith "TODO"

  (* external filteri : 'a t -> (('a -> int -> bool)[@bs.uncurry]) -> 'a t = "filter" [@@bs.send] *)
  let filteri _ _ = failwith "TODO"

  (* external find : 'a t -> (('a -> bool)[@bs.uncurry]) -> 'a option = "find" [@@bs.send] [@@bs.return { undefined_to_opt }] *)
  let find _ _ = failwith "TODO"
  (* ES2015 *)

  (* external findi : 'a t -> (('a -> int -> bool)[@bs.uncurry]) -> 'a option = "find" [@@bs.send] [@@bs.return {  undefined_to_opt }] *)
  let findi _ _ = failwith "TODO"
  (* ES2015 *)

  (* external findIndex : 'a t -> (('a -> bool)[@bs.uncurry]) -> int = "findIndex" [@@bs.send] *)
  let findIndex _ _ = failwith "TODO"
  (* ES2015 *)

  (* external findIndexi : 'a t -> (('a -> int -> bool)[@bs.uncurry]) -> int = "findIndex" [@@bs.send] *)
  let findIndexi _ _ = failwith "TODO"
  (* ES2015 *)

  (* external forEach : 'a t -> (('a -> unit)[@bs.uncurry]) -> unit = "forEach" [@@bs.send] *)
  let forEach _ _ = failwith "TODO"

  (* external forEachi : 'a t -> (('a -> int -> unit)[@bs.uncurry]) -> unit = "forEach" [@@bs.send] *)
  let forEachi _ _ = failwith "TODO"

  (* commented out until bs has a plan for iterators external keys : 'a t -> int array_iter = "" [@@bs.send] (* ES2015 *) *)

  (* external map : 'a t -> (('a -> 'b)[@bs.uncurry]) -> 'b t = "map" [@@bs.send] *)
  let map _ _ = failwith "TODO"

  (* external mapi : 'a t -> (('a -> int -> 'b)[@bs.uncurry]) -> 'b t = "map" [@@bs.send] *)
  let mapi _ _ = failwith "TODO"

  (* external reduce : 'a t -> (('b -> 'a -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduce" [@@bs.send] *)
  let reduce _ _ = failwith "TODO"

  (* external reducei : 'a t -> (('b -> 'a -> int -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduce" [@@bs.send] *)
  let reducei _ _ = failwith "TODO"

  (* external reduceRight : 'a t -> (('b -> 'a -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduceRight" [@@bs.send] *)
  let reduceRight _ _ = failwith "TODO"

  (* external reduceRighti : 'a t -> (('b -> 'a -> int -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduceRight" [@@bs.send] *)
  let reduceRighti _ _ = failwith "TODO"

  (* external some : 'a t -> (('a -> bool)[@bs.uncurry]) -> bool = "some" [@@bs.send] *)
  let some _ _ = failwith "TODO"

  (* external somei : 'a t -> (('a -> int -> bool)[@bs.uncurry]) -> bool = "some" [@@bs.send] *)
  let somei _ _ = failwith "TODO"

  (* commented out until bs has a plan for iterators external values : 'a t -> 'a array_iter = "" [@@bs.send] (* ES2015 *) *)
  (* external unsafe_get : 'a array -> int -> 'a = "%array_unsafe_get" *)
  let unsafe_get _ _ = failwith "TODO"

  (* external unsafe_set : 'a array -> int -> 'a -> unit = "%array_unsafe_set" *)
  let unsafe_set _ _ = failwith "TODO"
end

(** Provide bindings to Js array *)
module Array = struct
  (** JavaScript Array API *)

  type 'a t = 'a array
  type 'a array_like = 'a Array2.array_like

  (* commented out until bs has a plan for iterators
     type 'a array_iter = 'a array_like
  *)

  (* external from : 'a array_like -> 'a array = "Array.from" [@@bs.val] *)
  let from _ _ = failwith "TODO"
  (* ES2015 *)

  (* external fromMap : 'a array_like -> (('a -> 'b)[@bs.uncurry]) -> 'b array = "Array.from" [@@bs.val] *)
  let fromMap _ _ = failwith "TODO"
  (* ES2015 *)

  (* external isArray : 'a -> bool = "Array.isArray" [@@bs.val] *)
  let isArray _ _ = failwith "TODO"

  (* ES2015 *)
  (* ES2015 *)

  (* Array.of: seems pointless unless you can bind *)
  (* external length : 'a array -> int = "length" [@@bs.get] *)
  let length _ = failwith "TODO"

  (* Mutator functions *)
  (* external copyWithin : to_:int -> 'this = "copyWithin" [@@bs.send.pipe: 'a t as 'this] *)
  let copyWithin _ _ = failwith "TODO"
  (* ES2015 *)

  let copyWithinFrom _ _ = failwith "TODO"

  (* external copyWithinFrom : to_:int -> from:int -> 'this = "copyWithin" [@@bs.send.pipe: 'a t as 'this] *)
  (* ES2015 *)

  (* external copyWithinFromRange : to_:int -> start:int -> end_:int -> 'this = "copyWithin" [@@bs.send.pipe: 'a t as 'this] *)
  let copyWithinFromRange _ _ = failwith "TODO"
  (* ES2015 *)

  (* external fillInPlace : 'a -> 'this = "fill" [@@bs.send.pipe: 'a t as 'this] *)
  let fillInPlace _ _ = failwith "TODO"
  (* ES2015 *)

  let fillFromInPlace _ _ = failwith "TODO"
  (* external fillFromInPlace : 'a -> from:int -> 'this = "fill" [@@bs.send.pipe: 'a t as 'this] *)
  (* ES2015 *)

  let fillRangeInPlace _ _ = failwith "TODO"
  (* external fillRangeInPlace : 'a -> start:int -> end_:int -> 'this = "fill" [@@bs.send.pipe: 'a t as 'this] *)
  (* ES2015 *)

  (** https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/push *)
  let pop _ _ = failwith "TODO"
  (* external pop : 'a option = "pop" [@@bs.send.pipe: 'a t as 'this] [@@bs.return undefined_to_opt] *)

  (* external push : 'a -> int = "push" [@@bs.send.pipe: 'a t as 'this] *)
  let push _ _ = failwith "TODO"

  (* external pushMany : 'a array -> int = "push" [@@bs.send.pipe: 'a t as 'this] [@@bs.splice] *)
  let pushMany _ _ = failwith "TODO"

  (* external reverseInPlace : 'this = "reverse" [@@bs.send.pipe: 'a t as 'this] *)
  let reverseInPlace _ _ = failwith "TODO"
  (* external shift : 'a option = "shift" [@@bs.send.pipe: 'a t as 'this] [@@bs.return { undefined_to_opt }] *)

  let sortInPlace _ _ = failwith "TODO"
  (* external sortInPlace : 'this = "sort" [@@bs.send.pipe: 'a t as 'this] *)

  let sortInPlaceWith _ _ = failwith "TODO"
  (* external sortInPlaceWith : (('a -> 'a -> int)[@bs.uncurry]) -> 'this = "sort" [@@bs.send.pipe: 'a t as 'this] *)

  let spliceInPlace _ _ = failwith "TODO"
  (* external spliceInPlace : pos:int -> remove:int -> add:'a array -> 'this = "splice" [@@bs.send.pipe: 'a t as 'this] [@@bs.splice] *)

  let removeFromInPlace _ _ = failwith "TODO"
  (* external removeFromInPlace : pos:int -> 'this = "splice" [@@bs.send.pipe: 'a t as 'this] *)

  let removeCountInPlace _ _ = failwith "TODO"
  (* external removeCountInPlace : pos:int -> count:int -> 'this = "splice" [@@bs.send.pipe: 'a t as 'this] *)
  (* screwy naming, but screwy function *)

  let unshift _ _ = failwith "TODO"
  (* external unshift : 'a -> int = "unshift" [@@bs.send.pipe: 'a t as 'this] *)

  let unshiftMany _ _ = failwith "TODO"
  (* external unshiftMany : 'a array -> int = "unshift" [@@bs.send.pipe: 'a t as 'this] [@@bs.splice] *)

  (* Accessor functions *)
  (* external append : 'a -> 'this = "concat" [@@bs.send.pipe: 'a t as 'this] [@@deprecated "append is not type-safe. Use `concat` instead, and see #1884"] *)
  let append _ _ = failwith "TODO"

  (* external concat : 'this -> 'this = "concat" [@@bs.send.pipe: 'a t as 'this] *)
  let concat _ _ = failwith "TODO"

  (* external concatMany : 'this array -> 'this = "concat" [@@bs.send.pipe: 'a t as 'this] [@@bs.splice] *)
  let concatMany _ _ = failwith "TODO"

  (** ES2016 *)
  let includes _ _ = failwith "TODO"

  (* TODO: Not available in Node V4 *)
  (* external includes : 'a -> bool = "includes" [@@bs.send.pipe: 'a t as 'this] *)

  (* external indexOf : 'a -> int = "indexOf" [@@bs.send.pipe: 'a t as 'this] *)
  let indexOf _ _ = failwith "TODO"

  (* external indexOfFrom : 'a -> from:int -> int = "indexOf" [@@bs.send.pipe: 'a t as 'this] *)
  let indexOfFrom _ _ = failwith "TODO"

  (* external join : 'a t -> string = "join" [@@bs.send] [@@deprecated "please use joinWith instead"] *)
  let join _ _ = failwith "TODO"

  (* external joinWith : string -> string = "join" [@@bs.send.pipe: 'a t as 'this] *)
  let joinWith _ _ = failwith "TODO"

  (* external lastIndexOf : 'a -> int = "lastIndexOf" [@@bs.send.pipe: 'a t as 'this] *)
  let lastIndexOf _ _ = failwith "TODO"

  (* external lastIndexOfFrom : 'a -> from:int -> int = "lastIndexOf" [@@bs.send.pipe: 'a t as 'this] *)
  let lastIndexOfFrom _ _ = failwith "TODO"

  (* external lastIndexOf_start : 'a -> int = "lastIndexOf" [@@bs.send.pipe: 'a t as 'this] [@@deprecated "Please use `lastIndexOf"] *)
  let lastIndexOf_start _ _ = failwith "TODO"

  (* external slice : start:int -> end_:int -> 'this = "slice" [@@bs.send.pipe: 'a t as 'this] *)
  let slice _ _ = failwith "TODO"

  (* external copy : 'this = "slice" [@@bs.send.pipe: 'a t as 'this] *)
  let copy _ _ = failwith "TODO"

  (* external slice_copy : unit -> 'this = "slice" [@@bs.send.pipe: 'a t as 'this] [@@deprecated "Please use `copy`"] *)
  let slice_copy _ _ = failwith "TODO"

  (* external sliceFrom : int -> 'this = "slice" [@@bs.send.pipe: 'a t as 'this] *)
  let sliceFrom _ _ = failwith "TODO"

  (* external slice_start : int -> 'this = "slice" [@@bs.send.pipe: 'a t as 'this] [@@deprecated "Please use `sliceFrom`"] *)
  let slice_start _ _ = failwith "TODO"

  (* external toString : string = "toString" [@@bs.send.pipe: 'a t as 'this] *)
  let toString _ _ = failwith "TODO"

  (* external toLocaleString : string = "toLocaleString" [@@bs.send.pipe: 'a t as 'this] *)
  let toLocaleString _ _ = failwith "TODO"

  (* Iteration functions *)
  (* commented out until bs has a plan for iterators
     external entries : (int * 'a) array_iter = "" [@@bs.send.pipe: 'a t as 'this] (* ES2015 *)
  *)

  (* external every : (('a -> bool)[@bs.uncurry]) -> bool = "every" [@@bs.send.pipe: 'a t as 'this] *)
  let every _ _ = failwith "TODO"

  (* external everyi : (('a -> int -> bool)[@bs.uncurry]) -> bool = "every" [@@bs.send.pipe: 'a t as 'this] *)
  let everyi _ _ = failwith "TODO"

  (* external filter : (('a -> bool)[@bs.uncurry]) -> 'this = "filter" [@@bs.send.pipe: 'a t as 'this] *)

  (** should we use [bool] or [boolean] seems they are intechangeable here *)
  let filter _ _ = failwith "TODO"

  (* external filteri : (('a -> int -> bool)[@bs.uncurry]) -> 'this = "filter" [@@bs.send.pipe: 'a t as 'this] *)
  let filteri _ _ = failwith "TODO"

  (* external find : (('a -> bool)[@bs.uncurry]) -> 'a option = "find" [@@bs.send.pipe: 'a t as 'this] [@@bs.return { undefined_to_opt }] *)
  let find _ _ = failwith "TODO"
  (* ES2015 *)

  (* external findi : (('a -> int -> bool)[@bs.uncurry]) -> 'a option = "find" [@@bs.send.pipe: 'a t as 'this] [@@bs.return { undefined_to_opt }] *)
  let findi _ _ = failwith "TODO"
  (* ES2015 *)

  (* external findIndex : (('a -> bool)[@bs.uncurry]) -> int = "findIndex" [@@bs.send.pipe: 'a t as 'this] *)
  let findIndex _ _ = failwith "TODO"
  (* ES2015 *)

  (* external findIndexi : (('a -> int -> bool)[@bs.uncurry]) -> int = "findIndex" [@@bs.send.pipe: 'a t as 'this] *)
  let findIndexi _ _ = failwith "TODO"
  (* ES2015 *)

  (* external forEach : (('a -> unit)[@bs.uncurry]) -> unit = "forEach" [@@bs.send.pipe: 'a t as 'this] *)
  let forEach _ _ = failwith "TODO"

  (* external forEachi : (('a -> int -> unit)[@bs.uncurry]) -> unit = "forEach" [@@bs.send.pipe: 'a t as 'this] *)
  let forEachi _ _ = failwith "TODO"

  (* commented out until bs has a plan for iterators
     external keys : int array_iter = "" [@@bs.send.pipe: 'a t as 'this] (* ES2015 *)
  *)

  (* external map : (('a -> 'b)[@bs.uncurry]) -> 'b t = "map" [@@bs.send.pipe: 'a t as 'this] *)
  let map _ _ = failwith "TODO"

  (* external mapi : (('a -> int -> 'b)[@bs.uncurry]) -> 'b t = "map" [@@bs.send.pipe: 'a t as 'this] *)
  let mapi _ _ = failwith "TODO"

  (* external reduce : (('b -> 'a -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduce" [@@bs.send.pipe: 'a t as 'this] *)
  let reduce _ _ = failwith "TODO"

  (* external reducei : (('b -> 'a -> int -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduce" [@@bs.send.pipe: 'a t as 'this] *)
  let reducei _ _ = failwith "TODO"

  (* external reduceRight : (('b -> 'a -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduceRight" [@@bs.send.pipe: 'a t as 'this] *)
  let reduceRight _ _ = failwith "TODO"

  (* external reduceRighti : (('b -> 'a -> int -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduceRight" [@@bs.send.pipe: 'a t as 'this] *)
  let reduceRighti _ _ = failwith "TODO"

  (* external some : (('a -> bool)[@bs.uncurry]) -> bool = "some" [@@bs.send.pipe: 'a t as 'this] *)
  let some _ _ = failwith "TODO"

  (* external somei : (('a -> int -> bool)[@bs.uncurry]) -> bool = "some" [@@bs.send.pipe: 'a t as 'this] *)
  let somei _ _ = failwith "TODO"

  (* commented out until bs has a plan for iterators
     external values : 'a array_iter = "" [@@bs.send.pipe: 'a t as 'this] (* ES2015 *)
  *)
  (* external unsafe_get : 'a array -> int -> 'a = "%array_unsafe_get" *)
  let unsafe_get _ _ = failwith "TODO"

  (* external unsafe_set : 'a array -> int -> 'a -> unit = "%array_unsafe_set" *)
  let unsafe_set _ _ = failwith "TODO"
end

module String = struct
  (** Provide bindings to JS string *)
end

module String2 = struct
  (** Provide bindings to JS string *)
end

module Re = struct
  (** Provide bindings to Js regex expression *)
end

module Promise = struct
  (** Provide bindings to JS promise *)
end

module Date = struct
  (** Provide bindings for JS Date *)
end

module Dict = struct
  (** Provide utilities for JS dictionary object *)
end

module Global = struct
  (** Provide bindings to JS global functions in global namespace*)
end

module Json = struct
  (** Provide utilities for json *)
end

module Math = struct
  (** Provide bindings for JS [Math] object *)
end

module Obj = struct
  (** Provide utilities for {!Js.t} *)
end

module Typed_array = struct
  (** Provide bindings for JS typed array *)
end

module TypedArray2 = struct
  (** Provide bindings for JS typed array *)
end

module Types = struct
  (** Provide utilities for manipulating JS types *)
end

module Float = struct
  (** Provide utilities for JS float *)
end

module Int = struct
  (** Provide utilities for int *)
end

module Bigint = struct
  (** Provide utilities for bigint *)
end

module Option = struct
  (** Provide utilities for option *)
end

module Result = struct
  (** Define the interface for result *)
end

module List = struct
  (** Provide utilities for list *)
end

module Vector = struct
  (** Provide utilities for Vector *)
end

module Console = struct
  let log a = print_endline (Stdlib.Obj.magic a)

  let log2 a b =
    print_endline
      (Printf.sprintf "%s %s" (Stdlib.Obj.magic a) (Stdlib.Obj.magic b))

  let log3 a b c =
    print_endline
      (Printf.sprintf "%s %s %s" (Stdlib.Obj.magic a) (Stdlib.Obj.magic b)
         (Stdlib.Obj.magic c))

  let log4 a b c d =
    print_endline
      (Printf.sprintf "%s %s %s %s" (Stdlib.Obj.magic a) (Stdlib.Obj.magic b)
         (Stdlib.Obj.magic c) (Stdlib.Obj.magic d))

  let logMany arr = Stdlib.Array.iter log arr
  let info = log
  let info2 = log2
  let info3 = log3
  let info4 = log4
  let infoMany = logMany
  let error = log
  let error2 = log2
  let error3 = log3
  let error4 = log4
  let errorMany = logMany
  let warn = log
  let warn2 = log2
  let warn3 = log3
  let warn4 = log4
  let warnMany = logMany

  (* external trace : unit -> unit = "trace" [@@bs.val] [@@bs.scope "console"] *)
  let trace () = ()

  (* external timeStart : string -> unit = "time" [@@bs.val] [@@bs.scope "console"] *)
  let timeStart _ = ()

  (* external timeEnd : string -> unit = "timeEnd" [@@bs.val] [@@bs.scope "console"] *)
  let timeEnd _ = ()
end

let log = Console.log
let log2 = Console.log2
let log3 = Console.log3
let log4 = Console.log4
let logMany = Console.logMany

module Set = struct
  (** Provides bindings for ES6 Set *)
end

module WeakSet = struct
  (** Provides bindings for ES6 WeakSet *)
end

module Map = struct
  (** Provides bindings for ES6 Map *)
end

module WeakMap = struct
  (** Provides bindings for ES6 WeakMap *)
end
