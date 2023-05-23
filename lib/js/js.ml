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
     (* external opaqueFullApply : 'a -> 'a = "#full_apply" *)

     (* Use opaque instead of [._n] to prevent some optimizations happening *)
     (* external run : 'a arity0 -> 'a = "#run" *)
     (* external opaque : 'a -> 'a = "%opaque" *)

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

  let empty = None
  let return a = Some a
  let getUnsafe a = match toOption a with None -> assert false | Some a -> a
  let test = function None -> true | Some _ -> false
  let getExn _ = failwith "TODO"
  let bind _ _ = failwith "TODO"
  let iter _ _ = failwith "TODO"
  let fromOption = fromOpt
  let from_opt = fromOpt
end

module Undefined = struct
  type 'a t = 'a undefined

  external return : 'a -> 'a t = "%identity"

  let empty = None

  external toOption : 'a t -> 'a option = "%identity"
  external fromOpt : 'a option -> 'a t = "%identity"

  let getExn _ = failwith "TODO"
  let getUnsafe a = match toOption a with None -> assert false | Some a -> a
  let bind _ _ = failwith "TODO"
  let iter _ _ = failwith "TODO"
  let testAny _ = failwith "TODO"
  let test _ = failwith "TODO"
  let fromOption = fromOpt
  let from_opt = fromOpt
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
  type t
  type exn += private Error of t

  external makeError : string -> t = "%identity"

  let asJsExn _ = failwith "TODO"
  let stack _ = failwith "TODO"
  let message _ = failwith "TODO"
  let name _ = failwith "TODO"
  let fileName _ = failwith "TODO"
  let anyToExnInternal _ = failwith "TODO"
  let isCamlExceptionOrOpenVariant _ = failwith "TODO"
  let raiseError str = raise (Stdlib.Obj.magic (makeError str : t) : exn)
  let raiseEvalError _ = failwith "TODO"
  let raiseRangeError _ = failwith "TODO"
  let raiseReferenceError _ = failwith "TODO"
  let raiseSyntaxError _ = failwith "TODO"
  let raiseTypeError _ = failwith "TODO"
  let raiseUriError _ = failwith "TODO"
end

(** Provide bindings to Js array *)
module Array2_ = struct
  (* "Array2_" is to hide it from Array2 *)
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

  (** https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/push *)
  let pop _ _ = failwith "TODO"
  (* external pop : 'a t -> 'a option = "pop" [@@bs.send] [@@bs.return undefined_to_opt] *)

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
  let find arr fn = Stdlib.Array.find_opt fn arr
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
  let forEach arr fn = Stdlib.Array.iter fn arr

  (* external forEachi : 'a t -> (('a -> int -> unit)[@bs.uncurry]) -> unit = "forEach" [@@bs.send] *)
  let forEachi arr fn = Stdlib.Array.iteri fn arr

  (* commented out until bs has a plan for iterators external keys : 'a t -> int array_iter = "" [@@bs.send] (* ES2015 *) *)

  (* external map : 'a t -> (('a -> 'b)[@bs.uncurry]) -> 'b t = "map" [@@bs.send] *)
  let map arr fn = Stdlib.Array.map fn arr

  (* external mapi : 'a t -> (('a -> int -> 'b)[@bs.uncurry]) -> 'b t = "map" [@@bs.send] *)
  let mapi arr fn = Stdlib.Array.mapi fn arr

  (* external reduce : 'a t -> (('b -> 'a -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduce" [@@bs.send] *)

  (* external reduce : 'a t -> (('b -> 'a -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduce" [@@bs.send] *)
  let reduce arr fn init = Stdlib.Array.fold_left fn init arr

  (* external reducei : 'a t -> (('b -> 'a -> int -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduce" [@@bs.send] *)
  let reducei arr fn init =
    let r = ref init in
    for i = 0 to Stdlib.Array.length arr - 1 do
      r := fn !r (Stdlib.Array.unsafe_get arr i) i
    done;
    !r

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
  type 'a array_like = 'a Array2_.array_like

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
  let indexOfFrom _ ~from:_ _ = failwith "TODO"

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
     (* external entries : (int * 'a) array_iter = "" [@@bs.send.pipe: 'a t as 'this] (* ES2015 *) *)
     let entries _ _ = failwith "TODO"
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
     (* external keys : int array_iter = "" [@@bs.send.pipe: 'a t as 'this] (* ES2015 *) *)
     let keys _ _ = failwith "TODO"
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
     (* external values : 'a array_iter = "" [@@bs.send.pipe: 'a t as 'this] (* ES2015 *) *)
     let values _ _ = failwith "TODO"
  *)
  (* external unsafe_get : 'a array -> int -> 'a = "%array_unsafe_get" *)
  let unsafe_get _ _ = failwith "TODO"

  (* external unsafe_set : 'a array -> int -> 'a -> unit = "%array_unsafe_set" *)
  let unsafe_set _ _ = failwith "TODO"
end

module Re = struct
  (** Provide bindings to Js regex expression *)

  type flag = [ Pcre.cflag | `GLOBAL | `STICKY | `UNICODE ]

  (* The RegExp object *)
  type t = { regex : Pcre.regexp; flags : flag list; mutable lastIndex : int }

  (* The result of a executing a RegExp on a string. *)
  type result = { substrings : Pcre.substrings }

  let captures : result -> string nullable array =
   fun result -> Pcre.get_opt_substrings result.substrings

  let matches : result -> string array =
   fun result -> Pcre.get_substrings result.substrings

  let index : result -> int =
   fun result ->
    try
      let substring = result.substrings in
      let start_offset, _end_offset = Pcre.get_substring_ofs substring 0 in
      start_offset
    with Not_found -> 0

  let input : result -> string =
   fun result -> Pcre.get_subject result.substrings

  let source : t -> string = fun _ -> failwith "todo source"

  let fromString : string -> t =
   fun str ->
    try
      let regexp = Pcre.regexp str in
      { regex = regexp; flags = []; lastIndex = 0 }
    with
    | Pcre.Error BadPartial -> raise @@ Invalid_argument "BadPartial"
    | Pcre.Error (BadPattern (msg, _pos)) ->
        raise @@ Invalid_argument ("BadPattern: " ^ msg)
    | Pcre.Error Partial -> raise @@ Invalid_argument "Partial"
    | Pcre.Error BadUTF8 -> raise @@ Invalid_argument "BadUTF8"
    | Pcre.Error BadUTF8Offset -> raise @@ Invalid_argument "BadUTF8Offset"
    | Pcre.Error MatchLimit -> raise @@ Invalid_argument "MatchLimit"
    | Pcre.Error RecursionLimit -> raise @@ Invalid_argument "RecursionLimit"
    | Pcre.Error WorkspaceSize -> raise @@ Invalid_argument "WorkspaceSize"
    | Pcre.Error (InternalError msg) -> raise @@ Invalid_argument msg

  let char_of_cflag : Pcre.cflag -> char option = function
    | `CASELESS -> Some 'i'
    | `MULTILINE -> Some 'm'
    | `UTF8 -> Some 'u'
    | _ -> None

  let flag_of_char : char -> flag = function
    | 'g' -> `GLOBAL
    | 'i' -> `CASELESS
    | 'm' -> `MULTILINE
    | 'u' -> `UTF8
    | 'y' -> `STICKY
    | _ -> raise (Invalid_argument "invalid flag")

  let parse_flags : string -> flag list =
   fun flags -> flags |> String.to_seq |> Seq.map flag_of_char |> List.of_seq

  let cflag_of_flag : flag -> Pcre.cflag option =
   fun flag ->
    match flag with
    | `GLOBAL | `STICKY | `UNICODE -> None
    | `CASELESS -> Some `CASELESS
    | `MULTILINE -> Some `MULTILINE
    | `DOTALL -> Some `DOTALL
    | `EXTENDED -> Some `EXTENDED
    | `ANCHORED -> Some `ANCHORED
    | `DOLLAR_ENDONLY -> Some `DOLLAR_ENDONLY
    | `EXTRA -> Some `EXTRA
    | `UNGREEDY -> Some `UNGREEDY
    | `UTF8 -> Some `UTF8
    | `NO_UTF8_CHECK -> Some `NO_UTF8_CHECK
    | `NO_AUTO_CAPTURE -> Some `NO_AUTO_CAPTURE
    | `AUTO_CALLOUT -> Some `AUTO_CALLOUT
    | `FIRSTLINE -> Some `FIRSTLINE

  let fromStringWithFlags : string -> flags:string -> t =
   fun str ~flags:str_flags ->
    let flags = parse_flags str_flags in
    let pcre_flags = List.filter_map cflag_of_flag flags in
    let regexp = Pcre.regexp ~flags:pcre_flags str in
    { regex = regexp; flags = parse_flags str_flags; lastIndex = 0 }

  let flags : t -> string =
   fun regexp ->
    let options = Pcre.options regexp.regex in
    let flags = Pcre.cflag_list options in
    flags |> List.filter_map char_of_cflag |> List.to_seq |> String.of_seq

  let flag : t -> flag -> bool = fun regexp flag -> List.mem flag regexp.flags
  let global : t -> bool = fun regexp -> flag regexp `GLOBAL
  let ignoreCase : t -> bool = fun regexp -> flag regexp `CASELESS
  let multiline : t -> bool = fun regexp -> flag regexp `MULTILINE
  let sticky : t -> bool = fun regexp -> flag regexp `STICKY
  let unicode : t -> bool = fun regexp -> flag regexp `UNICODE
  let lastIndex : t -> int = fun regex -> regex.lastIndex

  let setLastIndex : t -> int -> unit =
   fun regex index -> regex.lastIndex <- index

  let exec_ : t -> string -> result option =
   fun regexp str ->
    try
      let rex = regexp.regex in
      print_endline (Printf.sprintf "before lastIndex: %d" regexp.lastIndex);
      let substrings = Pcre.exec ~rex ~pos:regexp.lastIndex str in
      let _, lastIndex = Pcre.get_substring_ofs substrings 0 in
      print_endline (Printf.sprintf "after lastIndex: %d" lastIndex);
      regexp.lastIndex <- lastIndex;
      let sbs =
        Pcre.get_opt_substrings substrings
        |> Stdlib.Array.to_list
        |> Stdlib.List.filter_map (fun x -> x)
      in
      print_endline (Printf.sprintf "substrings: %s" (String.concat ", " sbs));
      Some { substrings }
    with Not_found -> None

  let regexp = fromStringWithFlags ~flags:"g" ".ats"
  let str = "cats and bats and mats"

  let wat () =
    try
      let rex = regexp.regex in
      let substrings = Pcre.exec ~rex ~pos:regexp.lastIndex str in
      print_endline (Printf.sprintf "lastIndex: %d" regexp.lastIndex);
      let _, lastIndex = Pcre.get_substring_ofs substrings 0 in
      regexp.lastIndex <- lastIndex;
      let sbs =
        Pcre.get_opt_substrings substrings
        |> Stdlib.Array.to_list
        |> Stdlib.List.filter_map (fun x -> x)
      in
      print_endline (Printf.sprintf "substrings: %s" (String.concat ", " sbs));
      ()
    with Not_found ->
      regexp.lastIndex <- 0;
      print_endline "Not found"

  let exec : string -> t -> result option = fun str rex -> exec_ rex str

  let test_ : t -> string -> bool =
   fun regexp str -> Pcre.pmatch ~rex:regexp.regex str

  (** Deprecated. please use Js.Re.test_ instead. *)
  let test : string -> t -> bool = fun str regex -> test_ regex str
end

module String = struct
  (** Provide bindings to JS string *)

  (** JavaScript String API *)

  type t = string

  (* external make : 'a -> t = "String" [@@bs.val] *)

  (** [make value] converts the given value to a string

@example {[
  make 3.5 = "3.5";;
  make [|1;2;3|]) = "1,2,3";;
]}
*)
  let make _ _ = failwith "TODO"

  (* external fromCharCode : int -> t = "String.fromCharCode" [@@bs.val] *)

  (** [fromCharCode n]
  creates a string containing the character corresponding to that number; {i n} ranges from 0 to 65535. If out of range, the lower 16 bits of the value are used. Thus, [fromCharCode 0x1F63A] gives the same result as [fromCharCode 0xF63A].

@example {[
  fromCharCode 65 = "A";;
  fromCharCode 0x3c8 = {js|ψ|js};;
  fromCharCode 0xd55c = {js|한|js};;
  fromCharCode -64568 = {js|ψ|js};;
]}
*)
  let fromCharCode _ _ = failwith "TODO"

  (* external fromCharCodeMany : int array -> t = "String.fromCharCode" [@@bs.val] [@@bs.splice] *)

  (** [fromCharCodeMany \[|n1;n2;n3|\]] creates a string from the characters corresponding to the given numbers, using the same rules as [fromCharCode].

@example {[
  fromCharCodeMany([|0xd55c, 0xae00, 33|]) = {js|한글!|js};;
]}
*)
  let fromCharCodeMany _ _ = failwith "TODO"

  (* external fromCodePoint : int -> t = "String.fromCodePoint" [@@bs.val] *)

  (** [fromCodePoint n]
  creates a string containing the character corresponding to that numeric code point. If the number is not a valid code point, {b raises} [RangeError]. Thus, [fromCodePoint 0x1F63A] will produce a correct value, unlike [fromCharCode 0x1F63A], and [fromCodePoint -5] will raise a [RangeError].

@example {[
  fromCodePoint 65 = "A";;
  fromCodePoint 0x3c8 = {js|ψ|js};;
  fromCodePoint 0xd55c = {js|한|js};;
  fromCodePoint 0x1f63a = {js|😺|js};;
]}

*)
  let fromCodePoint _ _ = failwith "TODO"
  (** ES2015 *)

  (* external fromCodePointMany : int array -> t = "String.fromCodePoint" [@@bs.val] [@@bs.splice] *)

  (** [fromCharCodeMany \[|n1;n2;n3|\]] creates a string from the characters corresponding to the given code point numbers, using the same rules as [fromCodePoint].

@example {[
  fromCodePointMany([|0xd55c; 0xae00; 0x1f63a|]) = {js|한글😺|js}
]}
*)
  let fromCodePointMany _ _ = failwith "TODO"
  (** ES2015 *)

  (* String.raw: ES2015, meant to be used with template strings, not directly *)

  (* external length : t -> int = "length" [@@bs.get] *)

  (** [length s] returns the length of the given string.

@example {[
  length "abcd" = 4;;
]}

*)
  let length _ _ = failwith "TODO"

  (* external get : t -> int -> t = "" [@@bs.get_index] *)

  (** [get s n] returns as a string the character at the given index number. If [n] is out of range, this function returns [undefined], so at some point this function may be modified to return [t option].

@example {[
  get "Reason" 0 = "R";;
  get "Reason" 4 = "o";;
  get {js|Rẽasöń|js} 5 = {js|ń|js};;
]}
*)
  let get _ _ = failwith "TODO"

  (* external charAt : int -> t = "charAt" [@@bs.send.pipe: t] *)

  (** [charAt n s] gets the character at index [n] within string [s]. If [n] is negative or greater than the length of [s], returns the empty string. If the string contains characters outside the range [\u0000-\uffff], it will return the first 16-bit value at that position in the string.

@example {[
  charAt 0, "Reason" = "R"
  charAt( 12, "Reason") = "";
  charAt( 5, {js|Rẽasöń|js} = {js|ń|js}
]}
*)
  let charAt _ _ = failwith "TODO"

  (* external charCodeAt : int -> float = "charCodeAt" [@@bs.send.pipe: t] *)

  (** [charCodeAt n s] returns the character code at position [n] in string [s]; the result is in the range 0-65535, unlke [codePointAt], so it will not work correctly for characters with code points greater than or equal to [0x10000].
The return type is [float] because this function returns [NaN] if [n] is less than zero or greater than the length of the string.

@example {[
  charCodeAt 0 {js|😺|js} returns 0xd83d
  codePointAt 0 {js|😺|js} returns Some 0x1f63a
]}

*)
  let charCodeAt _ _ = failwith "TODO"

  (* external codePointAt : int -> int option = "codePointAt" [@@bs.send.pipe: t] *)

  (** [codePointAt n s] returns the code point at position [n] within string [s] as a [Some] value. The return value handles code points greater than or equal to [0x10000]. If there is no code point at the given position, the function returns [None].

@example {[
  codePointAt 1 {js|¿😺?|js} = Some 0x1f63a
  codePointAt 5 "abc" = None
]}
*)
  let codePointAt _ _ = failwith "TODO"
  (** ES2015 *)

  (* external concat : t -> t = "concat" [@@bs.send.pipe: t] *)

  (** [concat append original] returns a new string with [append] added after [original].

@example {[
  concat "bell" "cow" = "cowbell";;
]}
*)
  let concat _ _ = failwith "TODO"

  (* external concatMany : t array -> t = "concat" [@@bs.send.pipe: t] [@@bs.splice] *)

  (** [concat arr original] returns a new string consisting of each item of an array of strings added to the [original] string.

@example {[
  concatMany [|"2nd"; "3rd"; "4th"|] "1st" = "1st2nd3rd4th";;
]}
*)
  let concatMany _ _ = failwith "TODO"

  (* external endsWith : t -> bool = "endsWith" [@@bs.send.pipe: t] *)

  (** ES2015:
    [endsWith substr str] returns [true] if the [str] ends with [substr], [false] otherwise.

@example {[
  endsWith "Script" "ReScript" = true;;
  endsWith "Script" "ReShoes" = false;;
]}
*)
  let endsWith _ _ = failwith "TODO"

  (* external endsWithFrom : t -> int -> bool = "endsWith" [@@bs.send.pipe: t] *)

  (** [endsWithFrom ending len str] returns [true] if the first [len] characters of [str] end with [ending], [false] otherwise. If [n] is greater than or equal to the length of [str], then it works like [endsWith]. (Honestly, this should have been named [endsWithAt], but oh well.)

@example {[
  endsWithFrom "cd" 4 "abcd" = true;;
  endsWithFrom "cd" 3 "abcde" = false;;
  endsWithFrom "cde" 99 "abcde" = true;;
  endsWithFrom "ple" 7 "example.dat" = true;;
]}
*)
  let endsWithFrom _ _ = failwith "TODO"
  (** ES2015 *)

  (* external includes : t -> bool = "includes" [@@bs.send.pipe: t] *)

  (**
  [includes searchValue s] returns [true] if [searchValue] is found anywhere within [s], [false] otherwise.

@example {[
  includes "gram" "programmer" = true;;
  includes "er" "programmer" = true;;
  includes "pro" "programmer" = true;;
  includes "xyz" "programmer" = false;;
]}
*)
  let includes _ _ = failwith "TODO"
  (** ES2015 *)

  (* external includesFrom : t -> int -> bool = "includes" [@@bs.send.pipe: t] *)

  (**
  [includes searchValue start s] returns [true] if [searchValue] is found anywhere within [s] starting at character number [start] (where 0 is the first character), [false] otherwise.

@example {[
  includesFrom "gram" 1 "programmer" = true;;
  includesFrom "gram" 4 "programmer" = false;;
  includesFrom {js|한|js} 1 {js|대한민국|js} = true;;
]}
*)
  let includesFrom _ _ = failwith "TODO"
  (** ES2015 *)

  (* external indexOf : t -> int = "indexOf" [@@bs.send.pipe: t] *)

  (**
  [indexOf searchValue s] returns the position at which [searchValue] was first found within [s], or [-1] if [searchValue] is not in [s].

@example {[
  indexOf "ok" "bookseller" = 2;;
  indexOf "sell" "bookseller" = 4;;
  indexOf "ee" "beekeeper" = 1;;
  indexOf "xyz" "bookseller" = -1;;
]}
*)
  let indexOf _ _ = failwith "TODO"

  (* external indexOfFrom : t -> int -> int = "indexOf" [@@bs.send.pipe: t] *)

  (**
  [indexOfFrom searchValue start s] returns the position at which [searchValue] was found within [s] starting at character position [start], or [-1] if [searchValue] is not found in that portion of [s]. The return value is relative to the beginning of the string, no matter where the search started from.

@example {[
  indexOfFrom "ok" 1 "bookseller" = 2;;
  indexOfFrom "sell" 2 "bookseller" = 4;;
  indexOfFrom "sell" 5 "bookseller" = -1;;
  indexOf "xyz" "bookseller" = -1;;
]}
*)
  let indexOfFrom _ _ = failwith "TODO"

  (* external lastIndexOf : t -> int = "lastIndexOf" [@@bs.send.pipe: t] *)

  (**
  [lastIndexOf searchValue s] returns the position of the {i last} occurrence of [searchValue] within [s], searching backwards from the end of the string. Returns [-1] if [searchValue] is not in [s]. The return value is always relative to the beginning of the string.

@example {[
  lastIndexOf "ok" "bookseller" = 2;;
  lastIndexOf "ee" "beekeeper" = 4;;
  lastIndexOf "xyz" "abcdefg" = -1;;
]}
*)
  let lastIndexOf _ _ = failwith "TODO"

  (* external lastIndexOfFrom : t -> int -> int = "lastIndexOf" [@@bs.send.pipe: t] *)

  (**
  [lastIndexOfFrom searchValue start s] returns the position of the {i last} occurrence of [searchValue] within [s], searching backwards from the given [start] position. Returns [-1] if [searchValue] is not in [s]. The return value is always relative to the beginning of the string.

@example {[
  lastIndexOfFrom "ok" 6 "bookseller" = 2;;
  lastIndexOfFrom "ee" 8 "beekeeper" = 4;;
  lastIndexOfFrom "ee" 3 "beekeeper" = 1;;
  lastIndexOfFrom "xyz" 4 "abcdefg" = -1;;
]}
*)
  let lastIndexOfFrom _ _ = failwith "TODO"

  (* extended by ECMA-402 *)

  (* external localeCompare : t -> float = "localeCompare" [@@bs.send.pipe: t] *)

  (**
  [localeCompare comparison reference] returns

{ul
  {- a negative value if [reference] comes before [comparison] in sort order}
  {- zero if [reference] and [comparison] have the same sort order}
  {- a positive value if [reference] comes after [comparison] in sort order}}

@example {[
  (localeCompare "ant" "zebra") > 0.0;;
  (localeCompare "zebra" "ant") < 0.0;;
  (localeCompare "cat" "cat") = 0.0;;
  (localeCompare "cat" "CAT") > 0.0;;
]}
*)
  let localeCompare _ _ = failwith "TODO"

  (* external match_ : Re.t -> t option array option = "match" [@@bs.send.pipe: t] [@@bs.return { null_to_opt }] *)

  (**
  [match regexp str] matches a string against the given [regexp]. If there is no match, it returns [None].
  For regular expressions without the [g] modifier, if there is a match, the return value is [Some array] where the array contains:

  {ul
    {- The entire matched string}
    {- Any capture groups if the [regexp] had parentheses}
  }

  For regular expressions with the [g] modifier, a matched expression returns [Some array] with all the matched substrings and no capture groups.

@example {[
  match [%re "/b[aeiou]t/"] "The better bats" = Some [|"bet"|]
  match [%re "/b[aeiou]t/g"] "The better bats" = Some [|"bet";"bat"|]
  match [%re "/(\\d+)-(\\d+)-(\\d+)/"] "Today is 2018-04-05." =
    Some [|"2018-04-05"; "2018"; "04"; "05"|]
  match [%re "/b[aeiou]g/"] "The large container." = None
]}

*)
  let match_ _ _ = failwith "TODO"

  (* external normalize : t = "normalize" [@@bs.send.pipe: t] *)

  (** [normalize str] returns the normalized Unicode string using Normalization Form Canonical (NFC) Composition.

Consider the character [ã], which can be represented as the single codepoint [\u00e3] or the combination of a lower case letter A [\u0061] and a combining tilde [\u0303]. Normalization ensures that both can be stored in an equivalent binary representation.

@see <https://www.unicode.org/reports/tr15/tr15-45.html> Unicode technical report for details
*)
  let normalize _ _ = failwith "TODO"
  (** ES2015 *)

  (* external normalizeByForm : t -> t = "normalize" [@@bs.send.pipe: t] *)

  (**
  [normalize str form] (ES2015) returns the normalized Unicode string using the specified form of normalization, which may be one of:

  {ul
    {- "NFC" — Normalization Form Canonical Composition.}
    {- "NFD" — Normalization Form Canonical Decomposition.}
    {- "NFKC" — Normalization Form Compatibility Composition.}
    {- "NFKD" — Normalization Form Compatibility Decomposition.}
  }

  @see <https://www.unicode.org/reports/tr15/tr15-45.html> Unicode technical report for details
*)
  let normalizeByForm _ _ = failwith "TODO"

  (* external repeat : int -> t = "repeat" [@@bs.send.pipe: t] *)

  (**
  [repeat n s] returns a string that consists of [n] repetitions of [s]. Raises [RangeError] if [n] is negative.

@example {[
  repeat 3 "ha" = "hahaha"
  repeat 0 "empty" = ""
]}
*)
  let repeat _ _ = failwith "TODO"
  (** ES2015 *)

  (* external replace : t -> t -> t = "replace" [@@bs.send.pipe: t] *)

  (** [replace substr newSubstr string] returns a new string which is
identical to [string] except with the first matching instance of [substr]
replaced by [newSubstr].

[substr] is treated as a verbatim string to match, not a regular
expression.

@example {[
  replace "old" "new" "old string" = "new string"
  replace "the" "this" "the cat and the dog" = "this cat and the dog"
]}
*)
  let replace _ _ = failwith "TODO"

  (* external replaceByRe : Re.t -> t -> t = "replace" [@@bs.send.pipe: t] *)

  (** [replaceByRe regex replacement string] returns a new string where occurrences matching [regex]
have been replaced by [replacement].

@example {[
  replaceByRe [%re "/[aeiou]/g"] "x" "vowels be gone" = "vxwxls bx gxnx"
  replaceByRe [%re "/(\\w+) (\\w+)/"] "$2, $1" "Juan Fulano" = "Fulano, Juan"
]}
*)
  let replaceByRe _ _ = failwith "TODO"

  (* external unsafeReplaceBy0 : Re.t -> ((t -> int -> t -> t)[@bs.uncurry]) -> t *)

  (** returns a new string with some or all matches of a pattern with no capturing
parentheses replaced by the value returned from the given function.
The function receives as its parameters the matched string, the offset at which the
match begins, and the whole string being matched

@example {[
let str = "beautiful vowels"
let re = [%re "/[aeiou]/g"]
let matchFn matchPart offset wholeString =
  Js.String.toUpperCase matchPart

let replaced = Js.String.unsafeReplaceBy0 re matchFn str

let () = Js.log replaced (* prints "bEAUtifUl vOwEls" *)
]}

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy0 _ _ = failwith "TODO" = "replace" [@@bs.send.pipe: t]

  (* external unsafeReplaceBy1 :
     Re.t -> ((t -> t -> int -> t -> t)[@bs.uncurry]) -> t = "replace" [@@bs.send.pipe: t] *)

  (** returns a new string with some or all matches of a pattern with one set of capturing
parentheses replaced by the value returned from the given function.
The function receives as its parameters the matched string, the captured string,
the offset at which the match begins, and the whole string being matched.

@example {[
let str = "increment 23"
let re = [%re "/increment (\\d+)/g"]
let matchFn matchPart p1 offset wholeString =
  wholeString ^ " is " ^ (string_of_int ((int_of_string p1) + 1))

let replaced = Js.String.unsafeReplaceBy1 re matchFn str

let () = Js.log replaced (* prints "increment 23 is 24" *)
]}

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy1 _ _ = failwith "TODO"

  (* external unsafeReplaceBy2 : Re.t -> ((t -> t -> t -> int -> t -> t)[@bs.uncurry]) -> t = "replace" [@@bs.send.pipe: t] *)

  (** returns a new string with some or all matches of a pattern with two sets of capturing
parentheses replaced by the value returned from the given function.
The function receives as its parameters the matched string, the captured strings,
the offset at which the match begins, and the whole string being matched.

@example {[
let str = "7 times 6"
let re = [%re "/(\\d+) times (\\d+)/"]
let matchFn matchPart p1 p2 offset wholeString =
  string_of_int ((int_of_string p1) * (int_of_string p2))

let replaced = Js.String.unsafeReplaceBy2 re matchFn str

let () = Js.log replaced (* prints "42" *)
]}

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy2 _ _ = failwith "TODO"

  (* external unsafeReplaceBy3 :
     Re.t -> ((t -> t -> t -> t -> int -> t -> t)[@bs.uncurry]) -> t = "replace" [@@bs.send.pipe: t] *)

  (** returns a new string with some or all matches of a pattern with three sets of capturing
parentheses replaced by the value returned from the given function.
The function receives as its parameters the matched string, the captured strings,
the offset at which the match begins, and the whole string being matched.

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy3 _ _ = failwith "TODO"

  (* external search : Re.t -> int = "search" [@@bs.send.pipe: t] *)

  (** [search regexp str] returns the starting position of the first match of [regexp] in the given [str], or -1 if there is no match.

@example {[
search [%re "/\\d+/"] "testing 1 2 3" = 8;;
search [%re "/\\d+/"] "no numbers" = -1;;
]}
*)
  let search _ _ = failwith "TODO"

  (* external slice : from:int -> to_:int -> t = "slice" [@@bs.send.pipe: t] *)

  (** [slice from:n1 to_:n2 str] returns the substring of [str] starting at character [n1] up to but not including [n2]

If either [n1] or [n2] is negative, then it is evaluated as [length str - n1] (or [length str - n2].

If [n2] is greater than the length of [str], then it is treated as [length str].

If [n1] is greater than [n2], [slice] returns the empty string.

@example {[
  slice ~from:2 ~to_:5 "abcdefg" == "cde";;
  slice ~from:2 ~to_:9 "abcdefg" == "cdefg";;
  slice ~from:(-4) ~to_:(-2) "abcdefg" == "de";;
  slice ~from:5 ~to_:1 "abcdefg" == "";;
]}
*)
  let slice _ _ = failwith "TODO"

  (* external sliceToEnd : from:int -> t = "slice" [@@bs.send.pipe: t] *)

  (** [sliceToEnd from: n str] returns the substring of [str] starting at character [n] to the end of the string

If [n] is negative, then it is evaluated as [length str - n].

If [n] is greater than the length of [str], then [sliceToEnd] returns the empty string.

@example {[
  sliceToEnd ~from: 4 "abcdefg" == "efg";;
  sliceToEnd ~from: (-2) "abcdefg" == "fg";;
  sliceToEnd ~from: 7 "abcdefg" == "";;
]}
*)
  let sliceToEnd _ _ = failwith "TODO"

  (* external split : t -> t array = "split" [@@bs.send.pipe: t] *)

  (**
  [split delimiter str] splits the given [str] at every occurrence of [delimiter] and returns an
  array of the resulting substrings.

@example {[
  split "-" "2018-01-02" = [|"2018"; "01"; "02"|];;
  split "," "a,b,,c" = [|"a"; "b"; ""; "c"|];;
  split "::" "good::bad as great::awful" = [|"good"; "bad as great"; "awful"|];;
  split ";" "has-no-delimiter" = [|"has-no-delimiter"|];;
]};
*)
  let split _ _ = failwith "TODO"

  (* external splitAtMost : t -> limit:int -> t array = "split" [@@bs.send.pipe: t] *)

  (**
  [splitAtMost delimiter ~limit: n str] splits the given [str] at every occurrence of [delimiter] and returns an array of the first [n] resulting substrings. If [n] is negative or greater than the number of substrings, the array will contain all the substrings.

@example {[
  splitAtMost "/" ~limit: 3 "ant/bee/cat/dog/elk" = [|"ant"; "bee"; "cat"|];;
  splitAtMost "/" ~limit: 0 "ant/bee/cat/dog/elk" = [| |];;
  splitAtMost "/" ~limit: 9 "ant/bee/cat/dog/elk" = [|"ant"; "bee"; "cat"; "dog"; "elk"|];;
]}
*)
  let splitAtMost _ _ = failwith "TODO"

  (* external splitLimited : t -> int -> t array = "split" [@@bs.send.pipe: t] [@@deprecated "Please use splitAtMost"] *)

  (**
  Deprecated - Please use [splitAtMost]
*)
  let splitLimited _ _ = failwith "TODO"

  (* external splitByRe : Re.t -> t option array = "split" [@@bs.send.pipe: t] *)

  (**
  [splitByRe regex str] splits the given [str] at every occurrence of [regex] and returns an
  array of the resulting substrings.

@example {[
  splitByRe [%re "/\\s*[,;]\\s*/"] "art; bed , cog ;dad" = [|Some "art"; Some "bed"; Some "cog"; Some "dad"|];;
  splitByRe [%re "/[,;]/"] "has:no:match" = [|Some "has:no:match"|];;
  splitByRe [%re "/(#)(:)?/"] "a#b#:c" = [|Some "a"; Some "#"; None; Some "b"; Some "#"; Some ":"; Some "c"|];;
]};
*)
  let splitByRe _ _ = failwith "TODO"

  (* external splitByReAtMost : Re.t -> limit:int -> t option array = "split" [@@bs.send.pipe: t] *)

  (**
  [splitByReAtMost regex ~limit: n str] splits the given [str] at every occurrence of [regex] and returns an
  array of the first [n] resulting substrings. If [n] is negative or greater than the number of substrings, the array will contain all the substrings.

@example {[
  splitByReAtMost [%re "/\\s*:\\s*/"] ~limit: 3 "one: two: three: four" = [|Some "one"; Some "two"; Some "three"|];;
  splitByReAtMost [%re "/\\s*:\\s*/"] ~limit: 0 "one: two: three: four" = [| |];;
  splitByReAtMost [%re "/\\s*:\\s*/"] ~limit: 8 "one: two: three: four" = [|Some "one"; Some "two"; Some "three"; Some "four"|];;
  splitByReAtMost [%re "/(#)(:)?/"] ~limit:3 "a#b#:c" = [|Some "a"; Some "#"; None|];;
]};
*)
  let splitByReAtMost _ _ = failwith "TODO"

  (* external splitRegexpLimited : Re.t -> int -> t array = "split" [@@bs.send.pipe: t] [@@deprecated "Please use  splitByReAtMost"] *)

  (** Deprecated - Please use [splitByReAtMost] *)
  let splitRegexpLimited _ _ = failwith "TODO"

  (* external startsWith : t -> bool = "startsWith" [@@bs.send.pipe: t] *)

  (** ES2015:
    [startsWith substr str] returns [true] if the [str] starts with [substr], [false] otherwise.

@example {[
  startsWith "Re" "ReScript" = true;;
  startsWith "" "ReScript" = true;;
  startsWith "Re" "JavaScript" = false;;
]}
*)
  let startsWith _ _ = failwith "TODO"

  (* external startsWithFrom : t -> int -> bool = "startsWith" [@@bs.send.pipe: t] *)

  (** ES2015:
    [startsWithFrom substr n str] returns [true] if the [str] starts with [substr] starting at position [n], [false] otherwise. If [n] is negative, the search starts at the beginning of [str].

@example {[
  startsWithFrom "cri" 3 "ReScript" = true;;
  startsWithFrom "" 3 "ReScript" = true;;
  startsWithFrom "Re" 2 "JavaScript" = false;;
]}
*)
  let startsWithFrom _ _ = failwith "TODO"

  (* external substr : from:int -> t = "substr" [@@bs.send.pipe: t] *)

  (**
  [substr ~from: n str] returns the substring of [str] from position [n] to the end of the string.

  If [n] is less than zero, the starting position is the length of [str] - [n].

  If [n] is greater than or equal to the length of [str], returns the empty string.

@example {[
  substr ~from: 3 "abcdefghij" = "defghij"
  substr ~from: (-3) "abcdefghij" = "hij"
  substr ~from: 12 "abcdefghij" = ""
]}
*)
  let substr _ _ = failwith "TODO"

  (* external substrAtMost : from:int -> length:int -> t = "substr" [@@bs.send.pipe: t] *)

  (**
  [substrAtMost ~from: pos ~length: n str] returns the substring of [str] of length [n] starting at position [pos].

  If [pos] is less than zero, the starting position is the length of [str] - [pos].

  If [pos] is greater than or equal to the length of [str], returns the empty string.

  If [n] is less than or equal to zero, returns the empty string.

@example {[
  substrAtMost ~from: 3 ~length: 4 "abcdefghij" = "defghij"
  substrAtMost ~from: (-3) ~length: 4 "abcdefghij" = "hij"
  substrAtMost ~from: 12 ~ length: 2 "abcdefghij" = ""
]}
*)
  let substrAtMost _ _ = failwith "TODO"

  (* external substring : from:int -> to_:int -> t = "substring" [@@bs.send.pipe: t] *)

  (**
  [substring ~from: start ~to_: finish str] returns characters [start] up to but not including [finish] from [str].

  If [start] is less than zero, it is treated as zero.

  If [finish] is zero or negative, the empty string is returned.

  If [start] is greater than [finish], the start and finish points are swapped.

@example {[
  substring ~from: 3 ~to_: 6 "playground" = "ygr";;
  substring ~from: 6 ~to_: 3 "playground" = "ygr";;
  substring ~from: 4 ~to_: 12 "playground" = "ground";;
]}
*)
  let substring _ _ = failwith "TODO"

  (* external substringToEnd : from:int -> t = "substring" [@@bs.send.pipe: t] *)

  (**
  [substringToEnd ~from: start str] returns the substring of [str] from position [start] to the end.

  If [start] is less than or equal to zero, the entire string is returned.

  If [start] is greater than or equal to the length of [str], the empty string is returned.

@example {[
  substringToEnd ~from: 4 "playground" = "ground";;
  substringToEnd ~from: (-3) "playground" = "playground";;
  substringToEnd ~from: 12 "playground" = "";
]}
*)
  let substringToEnd _ _ = failwith "TODO"

  (* external toLowerCase : t = "toLowerCase" [@@bs.send.pipe: t] *)

  (**
  [toLowerCase str] converts [str] to lower case using the locale-insensitive case mappings in the Unicode Character Database. Notice that the conversion can give different results depending upon context, for example with the Greek letter sigma, which has two different lower case forms when it is the last character in a string or not.

@example {[
  toLowerCase "ABC" = "abc";;
  toLowerCase {js|ΣΠ|js} = {js|σπ|js};;
  toLowerCase {js|ΠΣ|js} = {js|πς|js};;
]}
*)
  let toLowerCase _ _ = failwith "TODO"

  (* external toLocaleLowerCase : t = "toLocaleLowerCase" [@@bs.send.pipe: t] *)

  (**
  [toLocaleLowerCase str] converts [str] to lower case using the current locale
*)
  let toLocaleLowerCase _ _ = failwith "TODO"

  (* external toUpperCase : t = "toUpperCase" [@@bs.send.pipe: t] *)

  (**
  [toUpperCase str] converts [str] to upper case using the locale-insensitive case mappings in the Unicode Character Database. Notice that the conversion can expand the number of letters in the result; for example the German [ß] capitalizes to two [S]es in a row.

@example {[
  toUpperCase "abc" = "ABC";;
  toUpperCase {js|Straße|js} = {js|STRASSE|js};;
  toLowerCase {js|πς|js} = {js|ΠΣ|js};;
]}
*)
  let toUpperCase _ _ = failwith "TODO"

  (* external toLocaleUpperCase : t = "toLocaleUpperCase" [@@bs.send.pipe: t] *)

  (**
  [toLocaleUpperCase str] converts [str] to upper case using the current locale
*)
  let toLocaleUpperCase _ _ = failwith "TODO"

  (* external trim : t = "trim" [@@bs.send.pipe: t] *)

  (**
  [trim str] returns a string that is [str] with whitespace stripped from both ends. Internal whitespace is not removed.

@example {[
  trim "   abc def   " = "abc def"
  trim "\n\r\t abc def \n\n\t\r " = "abc def"
]}
*)
  let trim _ _ = failwith "TODO"

  (* HTML wrappers *)

  (* external anchor : t -> t = "anchor" [@@bs.send.pipe: t] *)

  (**
  [anchor anchorName anchorText] creates a string with an HTML [<a>] element with [name] attribute of [anchorName] and [anchorText] as its content.

@example {[
  anchor "page1" "Page One" = "<a name=\"page1\">Page One</a>"
]}
*)
  let anchor _ _ = failwith "TODO"
  (** ES2015 *)

  (* external link : t -> t = "link" [@@bs.send.pipe: t] *)

  (**
  [link urlText linkText] creates a string withan HTML [<a>] element with [href] attribute of [urlText] and [linkText] as its content.

@example {[
  link "page2.html" "Go to page two" = "<a href=\"page2.html\">Go to page two</a>"
]}
*)
  let link _ _ = failwith "TODO"
  (** ES2015 *)

  (* external castToArrayLike : t -> t Array2.array_like = "%identity" *)
  let castToArrayLike _ _ = failwith "TODO"
  (* FIXME: we should not encourage people to use [%identity], better
      to provide something using [@@bs.val] so that we can track such
      casting
  *)
end

module String2 = struct
  (** Provide bindings to JS string *)

  (** JavaScript String API *)

  type t = string

  (* external make : 'a -> t = "String" [@@bs.val] *)

  (** [make value] converts the given value to a string

@example {[
  make 3.5 = "3.5";;
  make [|1;2;3|]) = "1,2,3";;
]}
*)

  (* TODO (davesnx): This changes the interface from String() *)
  let make i ch = Stdlib.String.make i ch

  (* external fromCharCode : int -> t = "String.fromCharCode" [@@bs.val] *)

  (** [fromCharCode n]
  creates a string containing the character corresponding to that number; {i n} ranges from 0 to 65535. If out of range, the lower 16 bits of the value are used. Thus, [fromCharCode 0x1F63A] gives the same result as [fromCharCode 0xF63A].

@example {[
  fromCharCode 65 = "A";;
  fromCharCode 0x3c8 = {js|ψ|js};;
  fromCharCode 0xd55c = {js|한|js};;
  fromCharCode -64568 = {js|ψ|js};;
]}
*)
  let fromCharCode code =
    let uchar = Uchar.of_int code in
    let char_value = Uchar.to_char uchar in
    Stdlib.String.make 1 char_value

  (* external fromCharCodeMany : int array -> t = "String.fromCharCode" [@@bs.val] [@@bs.
     splice] *)

  (** [fromCharCodeMany \[|n1;n2;n3|\]] creates a string from the characters corresponding to the given numbers, using the same rules as [fromCharCode].

@example {[
  fromCharCodeMany([|0xd55c, 0xae00, 33|]) = {js|한글!|js};;
]}
*)
  let fromCharCodeMany _ _ = failwith "TODO"

  (* external fromCodePoint : int -> t = "String.fromCodePoint" [@@bs.val] (** ES2015 *) *)

  (** [fromCodePoint n]
  creates a string containing the character corresponding to that numeric code point. If the number is not a valid code point, {b raises} [RangeError]. Thus, [fromCodePoint 0x1F63A] will produce a correct value, unlike [fromCharCode 0x1F63A], and [fromCodePoint -5] will raise a [RangeError].

@example {[
  fromCodePoint 65 = "A";;
  fromCodePoint 0x3c8 = {js|ψ|js};;
  fromCodePoint 0xd55c = {js|한|js};;
  fromCodePoint 0x1f63a = {js|😺|js};;
]}
*)

  let fromCodePoint code_point =
    let ch = Char.chr code_point in
    Stdlib.String.make 1 ch

  (* external fromCodePointMany : int array -> t = "String.fromCodePoint" [@@bs.val] [@@bs.
     splice] *)

  (** [fromCharCodeMany \[|n1;n2;n3|\]] creates a string from the characters corresponding to the given code point numbers, using the same rules as [fromCodePoint].

@example {[
  fromCodePointMany([|0xd55c; 0xae00; 0x1f63a|]) = {js|한글😺|js}
]}
*)
  let fromCodePointMany _ = failwith "TODO"
  (** ES2015 *)

  (* String.raw: ES2015, meant to be used with template strings, not directly *)

  (* external length : t -> int = "length" [@@bs.get] *)

  (** [length s] returns the length of the given string.

@example {[
  length "abcd" = 4;;
]}

*)
  let length = Stdlib.String.length

  (* external get : t -> int -> t = "" [@@bs.get_index] *)

  (** [get s n] returns as a string the character at the given index number. If [n] is out of range, this function returns [undefined], so at some point this function may be modified to return [t option].

@example {[
  get "Reason" 0 = "R";;
  get "Reason" 4 = "o";;
  get {js|Rẽasöń|js} 5 = {js|ń|js};;
]}
*)
  let get str index =
    let ch = Stdlib.String.get str index in
    Stdlib.String.make 1 ch

  (* external set : t -> int -> t -> t = "" [@@bs.set_index] *)

  (** [set s n c] sets the character at the given index number to the given character. If [n] is out of range, this function does nothing. *)

  (* external charAt : t -> int -> t = "charAt" [@@bs.send] *)

  (* TODO (davesnx): If the string contains characters outside the range [\u0000-\uffff], it will return the first 16-bit value at that position in the string. *)
  let charAt str index =
    if index < 0 || index >= Stdlib.String.length str then ""
    else
      let ch = Stdlib.String.get str index in
      Stdlib.String.make 1 ch

  (** [charAt n s] gets the character at index [n] within string [s]. If [n] is negative or greater than the length of [s], returns the empty string. If the string contains characters outside the range [\u0000-\uffff], it will return the first 16-bit value at that position in the string.

@example {[
  charAt "Reason" 0 = "R"
  charAt "Reason" 12 = "";
  charAt {js|Rẽasöń|js} 5 = {js|ń|js}
]}
*)

  (* external charCodeAt : t -> int -> float = "charCodeAt" [@@bs.send] *)

  (** [charCodeAt n s] returns the character code at position [n] in string [s]; the result is in the range 0-65535, unlke [codePointAt], so it will not work correctly for characters with code points greater than or equal to [0x10000].
The return type is [float] because this function returns [NaN] if [n] is less than zero or greater than the length of the string.

@example {[
  charCodeAt {js|😺|js} 0 returns 0xd83d
]}
*)

  (* JavaScript's String.prototype.charCodeAt can handle surrogate pairs, which are used to represent some Unicode characters in JavaScript strings. This implementation does not handle surrogate pairs and it treats each Unicode character as a separate code point, even if it's part of a surrogate pair. *)
  let charCodeAt s n =
    if n < 0 || n >= Stdlib.String.length s then nan
    else float_of_int (Stdlib.Char.code (Stdlib.String.get s n))

  (* external codePointAt : t -> int -> int option = "codePointAt" [@@bs.send]  (** ES2015 *) *)

  (** [codePointAt n s] returns the code point at position [n] within string [s] as a [Some] value. The return value handles code points greater than or equal to [0x10000]. If there is no code point at the given position, the function returns [None].

@example {[
  codePointAt {js|¿😺?|js} 1 = Some 0x1f63a
  codePointAt "abc" 5 = None
]}
*)
  let codePointAt str index =
    let str_length = Stdlib.String.length str in
    if index >= 0 && index < str_length then
      let uchar = Uchar.of_char (Stdlib.String.get str index) in
      Some (Uchar.to_int uchar)
    else None

  (* external concat : t -> t -> t = "concat" [@@bs.send] *)

  (** [concat append original] returns a new string with [append] added after [original].

@example {[
  concat "cow" "bell" = "cowbell";;
]}
*)
  let concat str1 str2 = Stdlib.String.concat "" [ str1; str2 ]

  (* external concatMany : t -> t array -> t = "concat" [@@bs.send] [@@bs.splice] *)

  (** [concat arr original] returns a new string consisting of each item of an array of strings added to the [original] string.

@example {[
  concatMany "1st" [|"2nd"; "3rd"; "4th"|] = "1st2nd3rd4th";;
]}
*)

  let concatMany original many =
    let many_list = Stdlib.Array.to_list many in
    Stdlib.String.concat "" (original :: many_list)

  (* external endsWith : t -> t -> bool = "endsWith" [@@bs.send] *)

  (** ES2015:
    [endsWith substr str] returns [true] if the [str] ends with [substr], [false] otherwise.

@example {[
  endsWith "ReScript" "Script" = true;;
  endsWith "ReShoes" "Script" = false;;
]}
*)
  let endsWith str suffix =
    let str_length = Stdlib.String.length str in
    let suffix_length = Stdlib.String.length suffix in
    if str_length < suffix_length then false
    else
      Stdlib.String.sub str (str_length - suffix_length) suffix_length = suffix

  (* external endsWithFrom : t -> t -> int -> bool = "endsWith" [@@bs.send] (** ES2015 *) *)

  (** [endsWithFrom ending len str] returns [true] if the first [len] characters of [str] end with [ending], [false] otherwise. If [n] is greater than or equal to the length of [str], then it works like [endsWith]. (Honestly, this should have been named [endsWithAt], but oh well.)

@example {[
  endsWithFrom "abcd" "cd" 4 = true;;
  endsWithFrom "abcde" "cd" 3 = false;;
  endsWithFrom "abcde" "cde" 99 = true;;
  endsWithFrom "example.dat" "ple" 7 = true;;
]}
*)
  let endsWithFrom str suffix from =
    let str_length = Stdlib.String.length str in
    let suffix_length = Stdlib.String.length suffix in
    let start_idx = Stdlib.max 0 (from - suffix_length) in
    if str_length - start_idx < suffix_length then false
    else Stdlib.String.sub str start_idx suffix_length = suffix

  (* external includes : t -> t -> bool = "includes" [@@bs.send] (** ES2015 *) *)

  (**
  [includes searchValue s] returns [true] if [searchValue] is found anywhere within [s], [false] otherwise.

@example {[
  includes "programmer" "gram" = true;;
  includes "programmer" "er" = true;;
  includes "programmer" "pro" = true;;
  includes "programmer" "xyz" = false;;
]}
*)
  let includes str sub =
    let str_length = Stdlib.String.length str in
    let sub_length = Stdlib.String.length sub in
    let rec includes_helper idx =
      if idx + sub_length > str_length then false
      else if Stdlib.String.sub str idx sub_length = sub then true
      else includes_helper (idx + 1)
    in
    includes_helper 0

  (* external includesFrom : t -> t -> int -> bool = "includes" [@@bs.send] (** ES2015 *) *)

  (**
  [includes searchValue start s] returns [true] if [searchValue] is found anywhere within [s] starting at character number [start] (where 0 is the first character), [false] otherwise.

@example {[
  includesFrom "programmer" "gram" 1 = true;;
  includesFrom "programmer" "gram" 4 = false;;
  includesFrom {js|대한민국|js} {js|한|js} 1 = true;;
]}
*)
  let includesFrom str sub from =
    let str_length = Stdlib.String.length str in
    let sub_length = Stdlib.String.length sub in
    let rec includes_helper idx =
      if idx + sub_length > str_length then false
      else if Stdlib.String.sub str idx sub_length = sub then true
      else includes_helper (idx + 1)
    in
    includes_helper from

  (* external indexOf : t -> t -> int = "indexOf" [@@bs.send] *)

  (**
  [indexOf searchValue s] returns the position at which [searchValue] was first found within [s], or [-1] if [searchValue] is not in [s].

@example {[
  indexOf "bookseller" "ok" = 2;;
  indexOf "bookseller" "sell" = 4;;
  indexOf "beekeeper" "ee" = 1;;
  indexOf "bookseller" "xyz" = -1;;
]}
*)
  let indexOf str pattern =
    let str_length = Stdlib.String.length str in
    let pattern_length = Stdlib.String.length pattern in
    let rec index_helper idx =
      if idx + pattern_length > str_length then -1
      else if Stdlib.String.sub str idx pattern_length = pattern then idx
      else index_helper (idx + 1)
    in
    index_helper 0

  (* external indexOfFrom : t -> t -> int -> int = "indexOf" [@@bs.send] *)

  (**
  [indexOfFrom searchValue start s] returns the position at which [searchValue] was found within [s] starting at character position [start], or [-1] if [searchValue] is not found in that portion of [s]. The return value is relative to the beginning of the string, no matter where the search started from.

@example {[
  indexOfFrom "bookseller" "ok" 1 = 2;;
  indexOfFrom "bookseller" "sell" 2 = 4;;
  indexOfFrom "bookseller" "sell" 5 = -1;;
]}
*)
  let indexOfFrom str pattern from =
    let str_length = Stdlib.String.length str in
    let pattern_length = Stdlib.String.length pattern in
    let rec index_helper idx =
      if idx + pattern_length > str_length then -1
      else if Stdlib.String.sub str idx pattern_length = pattern then idx
      else index_helper (idx + 1)
    in
    index_helper from

  (* external lastIndexOf : t -> t -> int = "lastIndexOf" [@@bs.send] *)

  (**
  [lastIndexOf searchValue s] returns the position of the {i last} occurrence of [searchValue] within [s], searching backwards from the end of the string. Returns [-1] if [searchValue] is not in [s]. The return value is always relative to the beginning of the string.

@example {[
  lastIndexOf "bookseller" "ok" = 2;;
  lastIndexOf "beekeeper" "ee" = 4;;
  lastIndexOf "abcdefg" "xyz" = -1;;
]}
*)
  let lastIndexOf str pattern =
    let str_length = Stdlib.String.length str in
    let pattern_length = Stdlib.String.length pattern in
    let rec last_index_helper idx =
      if idx < 0 || idx + pattern_length > str_length then -1
      else if Stdlib.String.sub str idx pattern_length = pattern then idx
      else last_index_helper (idx - 1)
    in
    last_index_helper (str_length - pattern_length)

  (* external lastIndexOfFrom : t -> t -> int -> int = "lastIndexOf" [@@bs.send] *)

  (**
  [lastIndexOfFrom searchValue start s] returns the position of the {i last} occurrence of [searchValue] within [s], searching backwards from the given [start] position. Returns [-1] if [searchValue] is not in [s]. The return value is always relative to the beginning of the string.

@example {[
  lastIndexOfFrom "bookseller" "ok" 6 = 2;;
  lastIndexOfFrom "beekeeper" "ee" 8 = 4;;
  lastIndexOfFrom "beekeeper" "ee" 3 = 1;;
  lastIndexOfFrom "abcdefg" "xyz" 4 = -1;;
]}
*)
  let lastIndexOfFrom str pattern from =
    let rec last_index_helper str pattern current_index max_index =
      if current_index < 0 then -1
      else if
        current_index <= max_index
        && Stdlib.String.sub str current_index (Stdlib.String.length pattern)
           = pattern
      then current_index
      else last_index_helper str pattern (current_index - 1) max_index
    in
    let str_length = Stdlib.String.length str in
    let max_index = Stdlib.min (str_length - 1) from in
    last_index_helper str pattern max_index max_index

  (* extended by ECMA-402 *)

  (* external localeCompare : t -> t -> float = "localeCompare" [@@bs.send] *)

  (**
  [localeCompare comparison reference] returns

{ul
  {- a negative value if [reference] comes before [comparison] in sort order}
  {- zero if [reference] and [comparison] have the same sort order}
  {- a positive value if [reference] comes after [comparison] in sort order}}

@example {[
  (localeCompare "zebra" "ant") > 0.0;;
  (localeCompare "ant" "zebra") < 0.0;;
  (localeCompare "cat" "cat") = 0.0;;
  (localeCompare "CAT" "cat") > 0.0;;
]}
*)
  let localeCompare _ _ = failwith "TODO"

  (* external match_ : t -> Js_re.t -> t option array option = "match" [@@bs.send] [@@bs.
     return {null_to_opt}] *)

  (**
  [match regexp str] matches a string against the given [regexp]. If there is no match, it returns [None].
  For regular expressions without the [g] modifier, if there is a match, the return value is [Some array] where the array contains:

  {ul
    {- The entire matched string}
    {- Any capture groups if the [regexp] had parentheses}
  }

  For regular expressions with the [g] modifier, a matched expression returns [Some array] with all the matched substrings and no capture groups.

@example {[
  match "The better bats" [%re "/b[aeiou]t/"] = Some [|"bet"|]
  match "The better bats" [%re "/b[aeiou]t/g"] = Some [|"bet";"bat"|]
  match "Today is 2018-04-05." [%re "/(\\d+)-(\\d+)-(\\d+)/"] = Some [|"2018-04-05"; "2018"; "04"; "05"|]
  match "The large container." [%re "/b[aeiou]g/"] = None
]}

*)
  let match_ _ _ = failwith "TODO"

  (* external normalize : t -> t = "normalize" [@@bs.send] (** ES2015 *) *)

  (** [normalize str] returns the normalized Unicode string using Normalization Form Canonical (NFC) Composition.

Consider the character [ã], which can be represented as the single codepoint [\u00e3] or the combination of a lower case letter A [\u0061] and a combining tilde [\u0303]. Normalization ensures that both can be stored in an equivalent binary representation.

@see <https://www.unicode.org/reports/tr15/tr15-45.html> Unicode technical report for details
*)
  let normalize _ _ = failwith "TODO"

  (* external normalizeByForm : t -> t -> t = "normalize" [@@bs.send] *)

  (**
  [normalize str form] (ES2015) returns the normalized Unicode string using the specified form of normalization, which may be one of:

  {ul
    {- "NFC" — Normalization Form Canonical Composition.}
    {- "NFD" — Normalization Form Canonical Decomposition.}
    {- "NFKC" — Normalization Form Compatibility Composition.}
    {- "NFKD" — Normalization Form Compatibility Decomposition.}
  }

  @see <https://www.unicode.org/reports/tr15/tr15-45.html> Unicode technical report for details
*)
  let normalizeByForm _ _ = failwith "TODO"

  (* external repeat : t -> int -> t = "repeat" [@@bs.send] (** ES2015 *) *)

  (* TODO(davesnx): RangeError *)

  (**
  [repeat n s] returns a string that consists of [n] repetitions of [s]. Raises [RangeError] if [n] is negative.

@example {[
  repeat "ha" 3 = "hahaha"
  repeat "empty" 0 = ""
]}
*)
  let repeat str count =
    let rec repeat' str acc remaining =
      if remaining <= 0 then acc else repeat' str (str ^ acc) (remaining - 1)
    in
    repeat' str "" count

  (* external replace : t -> t -> t -> t = "replace" [@@bs.send] *)

  (** [replace substr newSubstr string] returns a new string which is
identical to [string] except with the first matching instance of [substr]
replaced by [newSubstr].

[substr] is treated as a verbatim string to match, not a regular
expression.

@example {[
  replace "old string" "old" "new" = "new string"
  replace "the cat and the dog" "the" "this" = "this cat and the dog"
]}
*)
  let replace _ _ _ = failwith "TODO"

  (* external replaceByRe : t -> Js_re.t -> t -> t = "replace" [@@bs.send] *)

  (** [replaceByRe regex replacement string] returns a new string where occurrences matching [regex]
have been replaced by [replacement].

@example {[
  replaceByRe "vowels be gone" [%re "/[aeiou]/g"] "x" = "vxwxls bx gxnx"
  replaceByRe "Juan Fulano" [%re "/(\\w+) (\\w+)/"] "$2, $1" = "Fulano, Juan"
]}
*)
  let replaceByRe _ _ _ = failwith "TODO"

  (* external unsafeReplaceBy0 : t -> Js_re.t -> (t -> int -> t -> t [@bs.uncurry]) -> t =
     "replace" [@@bs.send] *)

  (** returns a new string with some or all matches of a pattern with no capturing
parentheses replaced by the value returned from the given function.
The function receives as its parameters the matched string, the offset at which the
match begins, and the whole string being matched

@example {[
let str = "beautiful vowels"
let re = [%re "/[aeiou]/g"]
let matchFn matchPart offset wholeString =
  Js.String2.toUpperCase matchPart

let replaced = Js.String2.unsafeReplaceBy0 str re matchFn

let () = Js.log replaced (* prints "bEAUtifUl vOwEls" *)
]}

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy0 _ _ = failwith "TODO"

  (* external unsafeReplaceBy1 : t -> Js_re.t -> (t -> t -> int -> t -> t [@bs.uncurry]) -> t = "replace" [@@bs.send] *)

  (** returns a new string with some or all matches of a pattern with one set of capturing
parentheses replaced by the value returned from the given function.
The function receives as its parameters the matched string, the captured string,
the offset at which the match begins, and the whole string being matched.

@example {[
let str = "increment 23"
let re = [%re "/increment (\\d+)/g"]
let matchFn matchPart p1 offset wholeString =
  wholeString ^ " is " ^ (string_of_int ((int_of_string p1) + 1))

let replaced = Js.String2.unsafeReplaceBy1 str re matchFn

let () = Js.log replaced (* prints "increment 23 is 24" *)
]}

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy1 _ _ = failwith "TODO"

  (* external unsafeReplaceBy2 : t -> Js_re.t -> (t -> t -> t -> int -> t -> t [@bs.uncurry])  -> t = "replace" [@@bs.send] *)

  (** returns a new string with some or all matches of a pattern with two sets of capturing
parentheses replaced by the value returned from the given function.
The function receives as its parameters the matched string, the captured strings,
the offset at which the match begins, and the whole string being matched.

@example {[
let str = "7 times 6"
let re = [%re "/(\\d+) times (\\d+)/"]
let matchFn matchPart p1 p2 offset wholeString =
  string_of_int ((int_of_string p1) * (int_of_string p2))

let replaced = Js.String2.unsafeReplaceBy2 str re matchFn

let () = Js.log replaced (* prints "42" *)
]}

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy2 _ _ = failwith "TODO"

  (* external unsafeReplaceBy3 : t -> Js_re.t -> (t -> t -> t -> t -> int -> t -> t [@bs.
     uncurry]) -> t = "replace" [@@bs.send] *)

  (** returns a new string with some or all matches of a pattern with three sets of capturing
parentheses replaced by the value returned from the given function.
The function receives as its parameters the matched string, the captured strings,
the offset at which the match begins, and the whole string being matched.

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy3 _ _ = failwith "TODO"

  (* external search : t -> Js_re.t -> int = "search" [@@bs.send] *)

  (** [search regexp str] returns the starting position of the first match of [regexp] in the given [str], or -1 if there is no match.

@example {[
search "testing 1 2 3" [%re "/\\d+/"] = 8;;
search "no numbers" [%re "/\\d+/"] = -1;;
]}
*)
  let search _ _ = failwith "TODO"

  (* external slice : t -> from:int -> to_:int ->  t = "slice" [@@bs.send] *)

  (** [slice from:n1 to_:n2 str] returns the substring of [str] starting at character [n1] up to but not including [n2]

If either [n1] or [n2] is negative, then it is evaluated as [length str - n1] (or [length str - n2].

If [n2] is greater than the length of [str], then it is treated as [length str].

If [n1] is greater than [n2], [slice] returns the empty string.

@example {[
  slice "abcdefg" ~from:2 ~to_:5 == "cde";;
  slice "abcdefg" ~from:2 ~to_:9 == "cdefg";;
  slice "abcdefg" ~from:(-4) ~to_:(-2) == "de";;
  slice "abcdefg" ~from:5 ~to_:1 == "";;
]}
*)
  let slice str ~from ~to_ =
    let str_length = Stdlib.String.length str in
    let start_idx = Stdlib.max 0 (Stdlib.min from str_length) in
    let end_idx = Stdlib.max start_idx (Stdlib.min to_ str_length) in
    if start_idx >= end_idx then ""
    else Stdlib.String.sub str start_idx (end_idx - start_idx)

  (* external sliceToEnd : t -> from:int ->  t = "slice" [@@bs.send] *)

  (** [sliceToEnd from: n str] returns the substring of [str] starting at character [n] to the end of the string

If [n] is negative, then it is evaluated as [length str - n].

If [n] is greater than the length of [str], then [sliceToEnd] returns the empty string.

@example {[
  sliceToEnd "abcdefg" ~from: 4 == "efg";;
  sliceToEnd "abcdefg" ~from: (-2) == "fg";;
  sliceToEnd "abcdefg" ~from: 7 == "";;
]}
*)
  let sliceToEnd str ~from =
    let str_length = Stdlib.String.length str in
    let start_idx = Stdlib.max 0 (Stdlib.min from str_length) in
    Stdlib.String.sub str start_idx (str_length - start_idx)

  (* external split : t -> t -> t array  = "split" [@@bs.send] *)

  (**
  [split delimiter str] splits the given [str] at every occurrence of [delimiter] and returns an
  array of the resulting substrings.

@example {[
  split "2018-01-02" "-" = [|"2018"; "01"; "02"|];;
  split "a,b,,c" "," = [|"a"; "b"; ""; "c"|];;
  split "good::bad as great::awful" "::" = [|"good"; "bad as great"; "awful"|];;
  split "has-no-delimiter" ";" = [|"has-no-delimiter"|];;
]};
*)
  let split _str _delimiter = failwith "TODO"

  (* external splitAtMost: t -> t -> limit:int -> t array = "split" [@@bs.send] *)

  (**
  [splitAtMost delimiter ~limit: n str] splits the given [str] at every occurrence of [delimiter] and returns an array of the first [n] resulting substrings. If [n] is negative or greater than the number of substrings, the array will contain all the substrings.

@example {[
  splitAtMost "ant/bee/cat/dog/elk" "/" ~limit: 3 = [|"ant"; "bee"; "cat"|];;
  splitAtMost "ant/bee/cat/dog/elk" "/" ~limit: 0 = [| |];;
  splitAtMost "ant/bee/cat/dog/elk" "/" ~limit: 9 = [|"ant"; "bee"; "cat"; "dog"; "elk"|];;
]}
*)
  let splitAtMost _str _separator ~limit:_ = failwith "TODO"

  (* external splitByRe : t -> Js_re.t -> t option array = "split" [@@bs.send] *)

  (**
  [splitByRe regex str] splits the given [str] at every occurrence of [regex] and returns an
  array of the resulting substrings.

@example {[
  splitByRe "art; bed , cog ;dad" [%re "/\\s*[,;]\\s*/"] = [|"art"; "bed"; "cog"; "dad"|];;
  splitByRe "has:no:match" [%re "/[,;]/"] = [|"has:no:match"|];;
]};
*)
  let splitByRe _ _ = failwith "TODO"

  (* external splitByReAtMost : t -> Js_re.t -> limit:int ->  t option array = "split" [@@bs.send] *)

  (**
  [splitByReAtMost regex ~limit: n str] splits the given [str] at every occurrence of [regex] and returns an
  array of the first [n] resulting substrings. If [n] is negative or greater than the number of substrings, the array will contain all the substrings.

@example {[
  splitByReAtMost "one: two: three: four" [%re "/\\s*:\\s*/"] ~limit: 3 = [|"one"; "two"; "three"|];;
  splitByReAtMost "one: two: three: four" [%re "/\\s*:\\s*/"] ~limit: 0 = [| |];;
  splitByReAtMost "one: two: three: four" [%re "/\\s*:\\s*/"] ~limit: 8 = [|"one"; "two"; "three"; "four"|];;
]};
*)
  let splitByReAtMost _ _ = failwith "TODO"

  (* external startsWith : t -> t -> bool = "startsWith" [@@bs.send] *)

  (** ES2015:
    [startsWith substr str] returns [true] if the [str] starts with [substr], [false] otherwise.

@example {[
  startsWith "ReScript" "Re" = true;;
  startsWith "ReScript" "" = true;;
  startsWith "JavaScript" "Re" = false;;
]}
*)
  let startsWith str prefix =
    Stdlib.String.length prefix <= Stdlib.String.length str
    && Stdlib.String.sub str 0 (Stdlib.String.length prefix) = prefix

  (* external startsWithFrom : t -> t -> int -> bool = "startsWith" [@@bs.send] *)

  (** ES2015:
    [startsWithFrom substr n str] returns [true] if the [str] starts with [substr] starting at position [n], [false] otherwise. If [n] is negative, the search starts at the beginning of [str].

@example {[
  startsWithFrom "ReScript" "cri" 3 = true;;
  startsWithFrom "ReScript" "" 3 = true;;
  startsWithFrom "JavaScript" "Re" 2 = false;;
]}
*)
  let startsWithFrom _str _index _ = failwith "TODO"

  (* external substr : t -> from:int -> t = "substr" [@@bs.send] *)

  (**
  [substr ~from: n str] returns the substring of [str] from position [n] to the end of the string.

  If [n] is less than zero, the starting position is the length of [str] - [n].

  If [n] is greater than or equal to the length of [str], returns the empty string.

@example {[
  substr "abcdefghij" ~from: 3 = "defghij"
  substr "abcdefghij" ~from: (-3) = "hij"
  substr "abcdefghij" ~from: 12 = ""
]}
*)
  let substr str ~from =
    let str_length = Stdlib.String.length str in
    let start_idx = Stdlib.max 0 (Stdlib.min from str_length) in
    if start_idx >= str_length then ""
    else Stdlib.String.sub str start_idx (str_length - start_idx)

  (* external substrAtMost : t -> from:int -> length:int -> t = "substr" [@@bs.send] *)

  (**
  [substrAtMost ~from: pos ~length: n str] returns the substring of [str] of length [n] starting at position [pos].

  If [pos] is less than zero, the starting position is the length of [str] - [pos].

  If [pos] is greater than or equal to the length of [str], returns the empty string.

  If [n] is less than or equal to zero, returns the empty string.

@example {[
  substrAtMost "abcdefghij" ~from: 3 ~length: 4 = "defghij"
  substrAtMost "abcdefghij" ~from: (-3) ~length: 4 = "hij"
  substrAtMost "abcdefghij" ~from: 12 ~ length: 2 = ""
]}
*)
  let substrAtMost str ~from ~length =
    let str_length = Stdlib.String.length str in
    let start_idx = max 0 (min from str_length) in
    let end_idx = min (start_idx + length) str_length in
    if start_idx >= end_idx then ""
    else Stdlib.String.sub str start_idx (end_idx - start_idx)

  (* external substring : t -> from:int -> to_:int ->  t = "substring" [@@bs.send] *)

  (**
  [substring ~from: start ~to_: finish str] returns characters [start] up to but not including [finish] from [str].

  If [start] is less than zero, it is treated as zero.

  If [finish] is zero or negative, the empty string is returned.

  If [start] is greater than [finish], the start and finish points are swapped.

@example {[
  substring "playground" ~from: 3 ~to_: 6 = "ygr";;
  substring "playground" ~from: 6 ~to_: 3 = "ygr";;
  substring "playground" ~from: 4 ~to_: 12 = "ground";;
]}
*)
  let substring str ~from ~to_ =
    let length = Stdlib.String.length str in
    let start_idx = max 0 (min from length) in
    let end_idx = max 0 (min to_ length) in
    if start_idx >= end_idx then
      Stdlib.String.sub str end_idx (start_idx - end_idx)
    else Stdlib.String.sub str start_idx (end_idx - start_idx)

  (* external substringToEnd : t -> from:int ->  t = "substring" [@@bs.send] *)

  (**
  [substringToEnd ~from: start str] returns the substring of [str] from position [start] to the end.

  If [start] is less than or equal to zero, the entire string is returned.

  If [start] is greater than or equal to the length of [str], the empty string is returned.

@example {[
  substringToEnd "playground" ~from: 4 = "ground";;
  substringToEnd "playground" ~from: (-3) = "playground";;
  substringToEnd "playground" ~from: 12 = "";
]}
*)
  let substringToEnd str ~from =
    let length = Stdlib.String.length str in
    if from >= length then ""
    else if from < 0 then str
    else Stdlib.String.sub str from (length - from)

  (* external toLowerCase : t -> t = "toLowerCase" [@@bs.send] *)

  (**
  [toLowerCase str] converts [str] to lower case using the locale-insensitive case mappings in the Unicode Character Database. Notice that the conversion can give different results depending upon context, for example with the Greek letter sigma, which has two different lower case forms when it is the last character in a string or not.

@example {[
  toLowerCase "ABC" = "abc";;
  toLowerCase {js|ΣΠ|js} = {js|σπ|js};;
  toLowerCase {js|ΠΣ|js} = {js|πς|js};;
]}
*)
  let toLowerCase str = Stdlib.String.lowercase_ascii str

  (* external toLocaleLowerCase : t -> t = "toLocaleLowerCase" [@@bs.send] *)

  (**
  [toLocaleLowerCase str] converts [str] to lower case using the current locale
*)
  let toLocaleLowerCase _ _ = failwith "TODO"

  (* external toUpperCase : t -> t = "toUpperCase" [@@bs.send] *)

  (**
  [toUpperCase str] converts [str] to upper case using the locale-insensitive case mappings in the Unicode Character Database. Notice that the conversion can expand the number of letters in the result; for example the German [ß] capitalizes to two [S]es in a row.

@example {[
  toUpperCase "abc" = "ABC";;
  toUpperCase {js|Straße|js} = {js|STRASSE|js};;
  toLowerCase {js|πς|js} = {js|ΠΣ|js};;
]}
*)
  let toUpperCase str = Stdlib.String.uppercase_ascii str

  (* external toLocaleUpperCase : t -> t = "toLocaleUpperCase" [@@bs.send] *)

  (**
  [toLocaleUpperCase str] converts [str] to upper case using the current locale
*)
  let toLocaleUpperCase _ _ = failwith "TODO"

  (* external trim : t -> t = "trim" [@@bs.send] *)

  (**
  [trim str] returns a string that is [str] with whitespace stripped from both ends. Internal whitespace is not removed.

@example {[
  trim "   abc def   " = "abc def"
  trim "\n\r\t abc def \n\n\t\r " = "abc def"
]}
*)
  let trim str =
    let whitespace = " \t\n\r" in
    let is_whitespace c = Stdlib.String.contains whitespace c in
    let length = Stdlib.String.length str in
    let rec trim_start idx =
      if idx >= length then length
      else if is_whitespace (Stdlib.String.get str idx) then trim_start (idx + 1)
      else idx
    in
    let rec trim_end idx =
      if idx <= 0 then 0
      else if is_whitespace (Stdlib.String.get str (idx - 1)) then
        trim_end (idx - 1)
      else idx
    in
    let start_idx = trim_start 0 in
    let end_idx = trim_end length in
    if start_idx >= end_idx then ""
    else Stdlib.String.sub str start_idx (end_idx - start_idx)

  (* HTML wrappers *)

  (* external anchor : t -> t -> t = "anchor" [@@bs.send] (** ES2015 *) *)

  (**
  [anchor anchorName anchorText] creates a string with an HTML [<a>] element with [name] attribute of [anchorName] and [anchorText] as its content.

@example {[
  anchor "Page One" "page1" = "<a name=\"page1\">Page One</a>"
]}
*)
  let anchor _ _ = failwith "TODO"

  (* external link : t -> t -> t = "link" [@@bs.send] (** ES2015 *) *)

  (**
  [link urlText linkText] creates a string withan HTML [<a>] element with [href] attribute of [urlText] and [linkText] as its content.

@example {[
  link "Go to page two" "page2.html" = "<a href=\"page2.html\">Go to page two</a>"
]}
*)
  let link _ _ = failwith "TODO"

  (* external castToArrayLike : t -> t Js_array2.array_like = "%identity" *)
  let castToArrayLike _ _ = failwith "TODO"
  (* FIXME: we should not encourage people to use [%identity], better
      to provide something using [@@bs.val] so that we can track such
      casting
  *)
end

module Promise = struct
  (** Provide bindings to JS promise *)
end

module Date = struct
  (** Provide bindings for JS Date *)
end

module Dict = struct
  (** Provide utilities for JS dictionary object *)

  type 'a t
  type key = string

  let get _ _ = failwith "TODO"
  let unsafeGet _ _ = failwith "TODO"
  let set _ _ = failwith "TODO"
  let keys _ = failwith "TODO"
  let empty _ = failwith "TODO"
  let unsafeDeleteKey _ _ = failwith "TODO"
  let entries _ = failwith "TODO"
  let values _ = failwith "TODO"
  let fromList _ = failwith "TODO"
  let fromArray _ = failwith "TODO"
  let map _ _ = failwith "TODO"
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

  type symbol
  (**Js symbol type only available in ES6 *)

  type bigint_val
  (** Js bigint type only available in ES2020 *)

  type obj_val

  type undefined_val
  (** This type has only one value [undefined] *)

  type null_val
  (** This type has only one value [null] *)

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

  (** @example{[
  test "x" String = true
  ]}*)
  let test _ _ = failwith "TODO"

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

  let classify _ = failwith "TODO"
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

  type 'a t = 'a option

  let some _ = failwith "TODO"
  let isSome _ = failwith "TODO"
  let isSomeValue _ _ _ = failwith "TODO"
  let isNone _ = failwith "TODO"
  let getExn _ = failwith "TODO"
  let equal _ _ = failwith "TODO"
  let andThen _ _ = failwith "TODO"
  let map _ _ = failwith "TODO"
  let getWithDefault _ _ = failwith "TODO"
  let default _ = failwith "TODO"
  let filter _ _ = failwith "TODO"
  let firstSome _ _ = failwith "TODO"
end

module Result = struct
  (** Define the interface for result *)
  type (+'good, +'bad) t = Ok of 'good | Error of 'bad
  [@@deprecated "Please use `Belt.Result.t` instead"]
end

module List = struct
  type 'a t = 'a list
  (** Provide utilities for list *)

  let length _ = failwith "TODO"
  let cons _ = failwith "TODO"
  let isEmpty _ = failwith "TODO"
  let hd _ = failwith "TODO"
  let tl _ = failwith "TODO"
  let nth _ = failwith "TODO"
  let revAppend _ = failwith "TODO"
  let rev _ = failwith "TODO"
  let mapRev _ = failwith "TODO"
  let map _ _ = failwith "TODO"
  let iter _ _ = failwith "TODO"
  let iteri _ _ = failwith "TODO"
  let foldLeft _ _ _ = failwith "TODO"
  let foldRight _ _ _ = failwith "TODO"
  let flatten _ = failwith "TODO"
  let filter _ _ = failwith "TODO"
  let filterMap _ _ = failwith "TODO"
  let countBy _ _ = failwith "TODO"
  let init _ _ = failwith "TODO"
  let toVector _ = failwith "TODO"
  let equal _ _ = failwith "TODO"
end

module Vector = struct
  (** Provide utilities for Vector *)

  type 'a t = 'a array

  let filterInPlace _ = failwith "TODO"
  let empty _ = failwith "TODO"
  let pushBack _ = failwith "TODO"
  let copy _ = failwith "TODO"
  let memByRef _ = failwith "TODO"
  let iter _ = failwith "TODO"
  let iteri _ = failwith "TODO"
  let toList _ = failwith "TODO"
  let map _ = failwith "TODO"
  let mapi _ = failwith "TODO"
  let foldLeft _ = failwith "TODO"
  let foldRight _ = failwith "TODO"

  external length : 'a t -> int = "%array_length"
  external get : 'a t -> int -> 'a = "%array_safe_get"
  external set : 'a t -> int -> 'a -> unit = "%array_safe_set"
  external make : int -> 'a -> 'a t = "caml_make_vect"

  let init _ = failwith "TODO"
  let append _ = failwith "TODO"

  external unsafe_get : 'a t -> int -> 'a = "%array_unsafe_get"
  external unsafe_set : 'a t -> int -> 'a -> unit = "%array_unsafe_set"
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
