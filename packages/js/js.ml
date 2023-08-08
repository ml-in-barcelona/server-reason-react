exception Not_implemented of string

let notImplemented module_ function_ =
  raise
    (Not_implemented
       (Printf.sprintf "'%s.%s' is not implemented in server-reason-react"
          module_ function_))

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
  (* external opaqueFullApply : 'a -> 'a = "#full_apply" *)

  (* Use opaque instead of [._n] to prevent some optimizations happening *)
  (* external run : 'a arity0 -> 'a = "#run" *)
  (* external opaque : 'a -> 'a = "%opaque" *)
end

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
let typeof _ = notImplemented "Js" "typeof"

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
  let getExn _ = notImplemented "Js.Null" "getExn"
  let bind _ _ = notImplemented "Js.Null" "bind"
  let iter _ _ = notImplemented "Js.Null" "iter"
  let fromOption = fromOpt
  let from_opt = fromOpt
end

module Undefined = struct
  type 'a t = 'a undefined

  external return : 'a -> 'a t = "%identity"

  let empty = None

  external toOption : 'a t -> 'a option = "%identity"
  external fromOpt : 'a option -> 'a t = "%identity"

  let getExn _ = notImplemented "Js.Undefined" "getExn"
  let getUnsafe a = match toOption a with None -> assert false | Some a -> a
  let bind _ _ = notImplemented "Js.Undefined" "bind"
  let iter _ _ = notImplemented "Js.Undefined" "iter"
  let testAny _ = notImplemented "Js.Undefined" "testAny"
  let test _ = notImplemented "Js.Undefined" "test"
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
    | Some x -> return (f x)

  let iter x f = match to_opt x with None -> () | Some x -> f x
  let fromOption x = match x with None -> undefined | Some x -> return x
  let from_opt = fromOption
end

module Null_undefined = Nullable

module Exn = struct
  type t
  type exn += private Error of t

  external makeError : string -> t = "%identity"

  let asJsExn _ = notImplemented "Js.Exn" "asJsExn"
  let stack _ = notImplemented "Js.Exn" "stack"
  let message _ = notImplemented "Js.Exn" "message"
  let name _ = notImplemented "Js.Exn" "name"
  let fileName _ = notImplemented "Js.Exn" "fileName"
  let anyToExnInternal _ = notImplemented "Js.Exn" "anyToExnInternal"
  let isCamlExceptionOrOpenVariant _ = notImplemented "Js.Exn" "mplemented"
  let raiseError str = raise (Stdlib.Obj.magic (makeError str : t) : exn)
  let raiseEvalError _ = notImplemented "Js.Exn" "raiseEvalError"
  let raiseRangeError _ = notImplemented "Js.Exn" "raiseRangeError"
  let raiseReferenceError _ = notImplemented "Js.Exn" "raiseReferenceError"
  let raiseSyntaxError _ = notImplemented "Js.Exn" "raiseSyntaxError"
  let raiseTypeError _ = notImplemented "Js.Exn" "raiseTypeError"
  let raiseUriError _ = notImplemented "Js.Exn" "raiseUriError"
end

(** Provide bindings to Js array *)
module Array2 = struct
  type 'a t = 'a array
  (** JavaScript Array API *)

  type 'a array_like

  (* commented out until bs has a plan for iterators `type 'a array_iter = 'a array_like`*)

  (* external from : 'a array_like -> 'a array = "Array.from" [@@bs.val] *)
  let from _ _ = notImplemented "Js.Array2" "from"
  (* ES2015 *)

  (* external fromMap : 'a array_like -> (('a -> 'b)[@bs.uncurry]) -> 'b array = "Array.from" [@@bs.val] *)
  let fromMap _ _ = notImplemented "Js.Array2" "fromMap"
  (* ES2015 *)

  (* external isArray : 'a -> bool = "Array.isArray" [@@bs.val] *)
  let isArray _ _ = notImplemented "Js.Array2" "isArray"

  (* ES2015 *)
  (* ES2015 *)

  (* Array.of: seems pointless unless you can bind *)
  (* external length : 'a array -> int = "length" [@@bs.get] *)
  let length _ _ = notImplemented "Js.Array2" "length"

  (* Mutator functions *)
  (* external copyWithin : 'a t -> to_:int -> 'a t = "copyWithin" [@@bs.send] *)
  let copyWithin _ _ = notImplemented "Js.Array2" "copyWithin"
  (* ES2015 *)

  (* external copyWithinFrom : 'a t -> to_:int -> from:int -> 'a t = "copyWithin" [@@bs.send] *)
  let copyWithinFrom _ _ = notImplemented "Js.Array2" "copyWithinFrom"
  (* ES2015 *)

  (* external copyWithinFromRange : 'a t -> to_:int -> start:int -> end_:int -> 'a t = "copyWithin" [@@bs.send] *)
  let copyWithinFromRange _ _ = notImplemented "Js.Array2" "copyWithinFromRange"
  (* ES2015 *)

  (* external fillInPlace : 'a t -> 'a -> 'a t = "fill" [@@bs.send] (* ES2015 *) *)
  let fillInPlace _ _ = notImplemented "Js.Array2" "fillInPlace"

  (* external fillFromInPlace : 'a t -> 'a -> from:int -> 'a t = "fill" [@@bs.send] *)
  let fillFromInPlace _ _ = notImplemented "Js.Array2" "fillFromInPlace"
  (* ES2015 *)

  (* external fillRangeInPlace : 'a t -> 'a -> start:int -> end_:int -> 'a t = "fill" [@@bs.send] *)
  let fillRangeInPlace _ _ = notImplemented "Js.Array2" "fillRangeInPlace"
  (* ES2015 *)

  (** https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/push *)
  let pop _ _ = notImplemented "Js.Array2" "pop"
  (* external pop : 'a t -> 'a option = "pop" [@@bs.send] [@@bs.return undefined_to_opt] *)

  (* external push : 'a t -> 'a -> int = "push" [@@bs.send] *)
  let push _ _ = notImplemented "Js.Array2" "push"

  (* external pushMany : 'a t -> 'a array -> int = "push" [@@bs.send] [@@bs.splice] *)
  let pushMany _ _ = notImplemented "Js.Array2" "pushMany"

  (* external reverseInPlace : 'a t -> 'a t = "reverse" [@@bs.send] *)
  let reverseInPlace _ _ = notImplemented "Js.Array2" "reverseInPlace"

  (* external shift : 'a t -> 'a option = "shift" [@@bs.send] [@@bs.return undefined_to_opt] *)
  let shift _ _ = notImplemented "Js.Array2" "shift"

  (* external sortInPlace : 'a t -> 'a t = "sort" [@@bs.send] *)
  let sortInPlace _ _ = notImplemented "Js.Array2" "sortInPlace"

  (* external sortInPlaceWith : 'a t -> (('a -> 'a -> int)[@bs.uncurry]) -> 'a t = "sort" [@@bs.send] *)
  let sortInPlaceWith _ _ = notImplemented "Js.Array2" "sortInPlaceWith"

  (* external spliceInPlace : 'a t -> pos:int -> remove:int -> add:'a array -> 'a t = "splice" [@@bs.send] [@@bs.splice] *)
  let spliceInPlace _ _ = notImplemented "Js.Array2" "spliceInPlace"

  (* external removeFromInPlace : 'a t -> pos:int -> 'a t = "splice" [@@bs.send] *)
  let removeFromInPlace _ _ = notImplemented "Js.Array2" "removeFromInPlace"

  (* external removeCountInPlace : 'a t -> pos:int -> count:int -> 'a t = "splice" [@@bs.send] *)
  let removeCountInPlace _ _ = notImplemented "Js.Array2" "removeCountInPlace"
  (* screwy naming, but screwy function *)

  (* external unshift : 'a t -> 'a -> int = "unshift" [@@bs.send] *)
  let unshift _ _ = notImplemented "Js.Array2" "unshift"

  (* external unshiftMany : 'a t -> 'a array -> int = "unshift" [@@bs.send] [@@bs.splice] *)
  let unshiftMany _ _ = notImplemented "Js.Array2" "unshiftMany"

  (* Accessor functions *)
  (* external append : 'a t -> 'a -> 'a t = "concat" [@@bs.send] [@@deprecated "append is not type-safe. Use `concat` instead, and see #1884"] *)
  let append _ _ = notImplemented "Js.Array2" "append"

  (* external concat : 'a t -> 'a t -> 'a t = "concat" [@@bs.send] *)
  let concat _ _ = notImplemented "Js.Array2" "concat"

  (* external concatMany : 'a t -> 'a t array -> 'a t = "concat" [@@bs.send] [@@bs.splice] *)
  let concatMany _ _ = notImplemented "Js.Array2" "concatMany"

  (* TODO: Not available in Node V4  *)
  (* external includes : 'a t -> 'a -> bool = "includes" [@@bs.send] *)

  (** ES2016 *)
  let includes _ _ = notImplemented "Js.Array2" "includes"

  (* external indexOf : 'a t -> 'a -> int = "indexOf" [@@bs.send] *)
  let indexOf _ _ = notImplemented "Js.Array2" "indexOf"

  (* external indexOfFrom : 'a t -> 'a -> from:int -> int = "indexOf" [@@bs.send] *)
  let indexOfFrom _ _ = notImplemented "Js.Array2" "indexOfFrom"

  (* external joinWith : 'a t -> string -> string = "join" [@@bs.send] *)
  let joinWith _ _ = notImplemented "Js.Array2" "joinWith"

  (* external lastIndexOf : 'a t -> 'a -> int = "lastIndexOf" [@@bs.send] *)
  let lastIndexOf _ _ = notImplemented "Js.Array2" "lastIndexOf"

  (* external lastIndexOfFrom : 'a t -> 'a -> from:int -> int = "lastIndexOf" [@@bs.send] *)
  let lastIndexOfFrom _ _ = notImplemented "Js.Array2" "lastIndexOfFrom"

  (* external slice : 'a t -> start:int -> end_:int -> 'a t = "slice" [@@bs.send] *)
  let slice _ _ = notImplemented "Js.Array2" "slice"

  (* external copy : 'a t -> 'a t = "slice" [@@bs.send] *)
  let copy _ _ = notImplemented "Js.Array2" "copy"

  (* external sliceFrom : 'a t -> int -> 'a t = "slice" [@@bs.send] *)
  let sliceFrom _ _ = notImplemented "Js.Array2" "sliceFrom"

  (* external toString : 'a t -> string = "toString" [@@bs.send] *)
  let toString _ _ = notImplemented "Js.Array2" "toString"

  (* external toLocaleString : 'a t -> string = "toLocaleString" [@@bs.send] *)
  let toLocaleString _ _ = notImplemented "Js.Array2" "toLocaleString"

  (* Iteration functions *)
  (* commented out until bs has a plan for iterators external entries : 'a t -> (int * 'a) array_iter = "" [@@bs.send] (* ES2015 *) *)

  (* external every : 'a t -> (('a -> bool)[@bs.uncurry]) -> bool = "every" [@@bs.send] *)
  let every _ _ = notImplemented "Js.Array2" "every"

  (* external everyi : 'a t -> (('a -> int -> bool)[@bs.uncurry]) -> bool = "every" [@@bs.send] *)
  let everyi _ _ = notImplemented "Js.Array2" "everyi"

  (* external filter : 'a t -> (('a -> bool)[@bs.uncurry]) -> 'a t = "filter" [@@bs.send] *)

  (** should we use [bool] or [boolean] seems they are intechangeable here *)
  let filter _ _ = notImplemented "Js.Array2" "filter"

  (* external filteri : 'a t -> (('a -> int -> bool)[@bs.uncurry]) -> 'a t = "filter" [@@bs.send] *)
  let filteri _ _ = notImplemented "Js.Array2" "filteri"

  (* external find : 'a t -> (('a -> bool)[@bs.uncurry]) -> 'a option = "find" [@@bs.send] [@@bs.return { undefined_to_opt }] *)
  let find arr fn = Stdlib.Array.find_opt fn arr
  (* ES2015 *)

  (* external findi : 'a t -> (('a -> int -> bool)[@bs.uncurry]) -> 'a option = "find" [@@bs.send] [@@bs.return {  undefined_to_opt }] *)
  let findi _ _ = notImplemented "Js.Array2" "findi"
  (* ES2015 *)

  (* external findIndex : 'a t -> (('a -> bool)[@bs.uncurry]) -> int = "findIndex" [@@bs.send] *)
  let findIndex _ _ = notImplemented "Js.Array2" "findIndex"
  (* ES2015 *)

  (* external findIndexi : 'a t -> (('a -> int -> bool)[@bs.uncurry]) -> int = "findIndex" [@@bs.send] *)
  let findIndexi _ _ = notImplemented "Js.Array2" "findIndexi"
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
  let reduceRight _ _ = notImplemented "Js.Array2" "reduceRight"

  (* external reduceRighti : 'a t -> (('b -> 'a -> int -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduceRight" [@@bs.send] *)
  let reduceRighti _ _ = notImplemented "Js.Array2" "reduceRighti"

  (* external some : 'a t -> (('a -> bool)[@bs.uncurry]) -> bool = "some" [@@bs.send] *)
  let some _ _ = notImplemented "Js.Array2" "some"

  (* external somei : 'a t -> (('a -> int -> bool)[@bs.uncurry]) -> bool = "some" [@@bs.send] *)
  let somei _ _ = notImplemented "Js.Array2" "somei"

  (* commented out until bs has a plan for iterators external values : 'a t -> 'a array_iter = "" [@@bs.send] (* ES2015 *) *)
  (* external unsafe_get : 'a array -> int -> 'a = "%array_unsafe_get" *)
  let unsafe_get _ _ = notImplemented "Js.Array2" "unsafe_get"

  (* external unsafe_set : 'a array -> int -> 'a -> unit = "%array_unsafe_set" *)
  let unsafe_set _ _ = notImplemented "Js.Array2" "unsafe_set"
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
  let from _ = notImplemented "Js.Array" "from"
  (* ES2015 *)

  (* external fromMap : 'a array_like -> (('a -> 'b)[@bs.uncurry]) -> 'b array = "Array.from" [@@bs.val] *)
  let fromMap _ _ = notImplemented "Js.Array" "fromMap"
  (* ES2015 *)

  (* external isArray : 'a -> bool = "Array.isArray" [@@bs.val] *)
  let isArray _ _ = notImplemented "Js.Array" "isArray"

  (* ES2015 *)
  (* ES2015 *)

  (* Array.of: seems pointless unless you can bind *)
  (* external length : 'a array -> int = "length" [@@bs.get] *)
  let length _ = notImplemented "Js.Array" "length"

  (* Mutator functions *)
  (* external copyWithin : to_:int -> 'this = "copyWithin" [@@bs.send.pipe: 'a t as 'this] *)
  let copyWithin _ _ = notImplemented "Js.Array" "copyWithin"
  (* ES2015 *)

  let copyWithinFrom _ _ = notImplemented "Js.Array" "copyWithinFrom"

  (* external copyWithinFrom : to_:int -> from:int -> 'this = "copyWithin" [@@bs.send.pipe: 'a t as 'this] *)
  (* ES2015 *)

  (* external copyWithinFromRange : to_:int -> start:int -> end_:int -> 'this = "copyWithin" [@@bs.send.pipe: 'a t as 'this] *)
  let copyWithinFromRange _ _ = notImplemented "Js.Array" "copyWithinFromRange"
  (* ES2015 *)

  (* external fillInPlace : 'a -> 'this = "fill" [@@bs.send.pipe: 'a t as 'this] *)
  let fillInPlace _ _ = notImplemented "Js.Array" "fillInPlace"
  (* ES2015 *)

  let fillFromInPlace _ _ = notImplemented "Js.Array" "fillFromInPlace"
  (* external fillFromInPlace : 'a -> from:int -> 'this = "fill" [@@bs.send.pipe: 'a t as 'this] *)
  (* ES2015 *)

  let fillRangeInPlace _ _ = notImplemented "Js.Array" "fillRangeInPlace"
  (* external fillRangeInPlace : 'a -> start:int -> end_:int -> 'this = "fill" [@@bs.send.pipe: 'a t as 'this] *)
  (* ES2015 *)

  (** https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/push *)
  let pop _ _ = notImplemented "Js.Array" "pop"
  (* external pop : 'a option = "pop" [@@bs.send.pipe: 'a t as 'this] [@@bs.return undefined_to_opt] *)

  (* external push : 'a -> int = "push" [@@bs.send.pipe: 'a t as 'this] *)
  let push _ _ = notImplemented "Js.Array" "push"

  (* external pushMany : 'a array -> int = "push" [@@bs.send.pipe: 'a t as 'this] [@@bs.splice] *)
  let pushMany _ _ = notImplemented "Js.Array" "pushMany"

  (* external reverseInPlace : 'this = "reverse" [@@bs.send.pipe: 'a t as 'this] *)
  let reverseInPlace _ _ = notImplemented "Js.Array" "reverseInPlace"
  (* external shift : 'a option = "shift" [@@bs.send.pipe: 'a t as 'this] [@@bs.return { undefined_to_opt }] *)

  let sortInPlace _ _ = notImplemented "Js.Array" "sortInPlace"
  (* external sortInPlace : 'this = "sort" [@@bs.send.pipe: 'a t as 'this] *)

  let sortInPlaceWith _ _ = notImplemented "Js.Array" "sortInPlaceWith"
  (* external sortInPlaceWith : (('a -> 'a -> int)[@bs.uncurry]) -> 'this = "sort" [@@bs.send.pipe: 'a t as 'this] *)

  let spliceInPlace _ _ = notImplemented "Js.Array" "spliceInPlace"
  (* external spliceInPlace : pos:int -> remove:int -> add:'a array -> 'this = "splice" [@@bs.send.pipe: 'a t as 'this] [@@bs.splice] *)

  let removeFromInPlace _ _ = notImplemented "Js.Array" "removeFromInPlace"
  (* external removeFromInPlace : pos:int -> 'this = "splice" [@@bs.send.pipe: 'a t as 'this] *)

  let removeCountInPlace _ _ = notImplemented "Js.Array" "removeCountInPlace"
  (* external removeCountInPlace : pos:int -> count:int -> 'this = "splice" [@@bs.send.pipe: 'a t as 'this] *)
  (* screwy naming, but screwy function *)

  let unshift _ _ = notImplemented "Js.Array" "unshift"
  (* external unshift : 'a -> int = "unshift" [@@bs.send.pipe: 'a t as 'this] *)

  let unshiftMany _ _ = notImplemented "Js.Array" "unshiftMany"
  (* external unshiftMany : 'a array -> int = "unshift" [@@bs.send.pipe: 'a t as 'this] [@@bs.splice] *)

  (* Accessor functions *)
  (* external append : 'a -> 'this = "concat" [@@bs.send.pipe: 'a t as 'this] [@@deprecated "append is not type-safe. Use `concat` instead, and see #1884"] *)
  let append _ _ = notImplemented "Js.Array" "append"

  (* external concat : 'this -> 'this = "concat" [@@bs.send.pipe: 'a t as 'this] *)
  let concat _ _ = notImplemented "Js.Array" "concat"

  (* external concatMany : 'this array -> 'this = "concat" [@@bs.send.pipe: 'a t as 'this] [@@bs.splice] *)
  let concatMany _ _ = notImplemented "Js.Array" "concatMany"

  (** ES2016 *)

  (* TODO: Not available in Node V4 *)
  (* external includes : 'a -> bool = "includes" [@@bs.send.pipe: 'a t as 'this] *)
  let includes _ _ = notImplemented "Js.Array" "includes"

  (* external indexOf : 'a -> int = "indexOf" [@@bs.send.pipe: 'a t as 'this] *)
  let indexOf _ _ = notImplemented "Js.Array" "indexOf"

  (* external indexOfFrom : 'a -> from:int -> int = "indexOf" [@@bs.send.pipe: 'a t as 'this] *)
  let indexOfFrom _ ~from:_ _ = notImplemented "Js.Array" "indexOfFrom"

  (* external join : 'a t -> string = "join" [@@bs.send] [@@deprecated "please use joinWith instead"] *)
  let join _ _ = notImplemented "Js.Array" "join"

  (* external joinWith : string -> string = "join" [@@bs.send.pipe: 'a t as 'this] *)
  let joinWith _ _ = notImplemented "Js.Array" "joinWith"

  (* external lastIndexOf : 'a -> int = "lastIndexOf" [@@bs.send.pipe: 'a t as 'this] *)
  let lastIndexOf _ _ = notImplemented "Js.Array" "lastIndexOf"

  (* external lastIndexOfFrom : 'a -> from:int -> int = "lastIndexOf" [@@bs.send.pipe: 'a t as 'this] *)
  let lastIndexOfFrom _ _ = notImplemented "Js.Array" "lastIndexOfFrom"

  (* external lastIndexOf_start : 'a -> int = "lastIndexOf" [@@bs.send.pipe: 'a t as 'this] [@@deprecated "Please use `lastIndexOf"] *)
  let lastIndexOf_start _ _ = notImplemented "Js.Array" "lastIndexOf_start"

  (* external slice : start:int -> end_:int -> 'this = "slice" [@@bs.send.pipe: 'a t as 'this] *)
  let slice _ _ = notImplemented "Js.Array" "slice"

  (* external copy : 'this = "slice" [@@bs.send.pipe: 'a t as 'this] *)
  let copy _ _ = notImplemented "Js.Array" "copy"

  (* external slice_copy : _ 'this = "slice" [@@bs.send.pipe: 'a t as 'this] [@@deprecated "Please use `copy`"] *)
  let slice_copy _ _ = notImplemented "Js.Array" "slice_copy"

  (* external sliceFrom : int -> 'this = "slice" [@@bs.send.pipe: 'a t as 'this] *)
  let sliceFrom _ _ = notImplemented "Js.Array" "sliceFrom"

  (* external slice_start : int -> 'this = "slice" [@@bs.send.pipe: 'a t as 'this] [@@deprecated "Please use `sliceFrom`"] *)
  let slice_start _ _ = notImplemented "Js.Array" "slice_start"

  (* external toString : string = "toString" [@@bs.send.pipe: 'a t as 'this] *)
  let toString _ _ = notImplemented "Js.Array" "toString"

  (* external toLocaleString : string = "toLocaleString" [@@bs.send.pipe: 'a t as 'this] *)
  let toLocaleString _ _ = notImplemented "Js.Array" "toLocaleString"

  (* Iteration functions *)
  (* commented out until bs has a plan for iterators
     (* external entries : (int * 'a) array_iter = "" [@@bs.send.pipe: 'a t as 'this] (* ES2015 *) *)
  *)
  let entries _ _ = notImplemented "Js.Array" "entries"

  (* external every : (('a -> bool)[@bs.uncurry]) -> bool = "every" [@@bs.send.pipe: 'a t as 'this] *)
  let every _ _ = notImplemented "Js.Array" "every"

  (* external everyi : (('a -> int -> bool)[@bs.uncurry]) -> bool = "every" [@@bs.send.pipe: 'a t as 'this] *)
  let everyi _ _ = notImplemented "Js.Array" "everyi"

  (* external filter : (('a -> bool)[@bs.uncurry]) -> 'this = "filter" [@@bs.send.pipe: 'a t as 'this] *)

  (** should we use [bool] or [boolean] seems they are intechangeable here *)
  let filter _ _ = notImplemented "Js.Array" "filter"

  (* external filteri : (('a -> int -> bool)[@bs.uncurry]) -> 'this = "filter" [@@bs.send.pipe: 'a t as 'this] *)
  let filteri _ _ = notImplemented "Js.Array" "filteri"

  (* external find : (('a -> bool)[@bs.uncurry]) -> 'a option = "find" [@@bs.send.pipe: 'a t as 'this] [@@bs.return { undefined_to_opt }] *)
  let find _ _ = notImplemented "Js.Array" "find"
  (* ES2015 *)

  (* external findi : (('a -> int -> bool)[@bs.uncurry]) -> 'a option = "find" [@@bs.send.pipe: 'a t as 'this] [@@bs.return { undefined_to_opt }] *)
  let findi _ _ = notImplemented "Js.Array" "findi"
  (* ES2015 *)

  (* external findIndex : (('a -> bool)[@bs.uncurry]) -> int = "findIndex" [@@bs.send.pipe: 'a t as 'this] *)
  let findIndex _ _ = notImplemented "Js.Array" "findIndex"
  (* ES2015 *)

  (* external findIndexi : (('a -> int -> bool)[@bs.uncurry]) -> int = "findIndex" [@@bs.send.pipe: 'a t as 'this] *)
  let findIndexi _ _ = notImplemented "Js.Array" "findIndexi"
  (* ES2015 *)

  (* external forEach : (('a -> unit)[@bs.uncurry]) -> unit = "forEach" [@@bs.send.pipe: 'a t as 'this] *)
  let forEach _ _ = notImplemented "Js.Array" "forEach"

  (* external forEachi : (('a -> int -> unit)[@bs.uncurry]) -> unit = "forEach" [@@bs.send.pipe: 'a t as 'this] *)
  let forEachi _ _ = notImplemented "Js.Array" "forEachi"

  (* commented out until bs has a plan for iterators
     (* external keys : int array_iter = "" [@@bs.send.pipe: 'a t as 'this] (* ES2015 *) *)
     let keys _ _ = notImplemented "Js.Array" "keys"
  *)

  (* external map : (('a -> 'b)[@bs.uncurry]) -> 'b t = "map" [@@bs.send.pipe: 'a t as 'this] *)
  let map _ _ = notImplemented "Js.Array" "map"

  (* external mapi : (('a -> int -> 'b)[@bs.uncurry]) -> 'b t = "map" [@@bs.send.pipe: 'a t as 'this] *)
  let mapi _ _ = notImplemented "Js.Array" "mapi"

  (* external reduce : (('b -> 'a -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduce" [@@bs.send.pipe: 'a t as 'this] *)
  let reduce _ _ = notImplemented "Js.Array" "reduce"

  (* external reducei : (('b -> 'a -> int -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduce" [@@bs.send.pipe: 'a t as 'this] *)
  let reducei _ _ = notImplemented "Js.Array" "reducei"

  (* external reduceRight : (('b -> 'a -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduceRight" [@@bs.send.pipe: 'a t as 'this] *)
  let reduceRight _ _ = notImplemented "Js.Array" "reduceRight"

  (* external reduceRighti : (('b -> 'a -> int -> 'b)[@bs.uncurry]) -> 'b -> 'b = "reduceRight" [@@bs.send.pipe: 'a t as 'this] *)
  let reduceRighti _ _ = notImplemented "Js.Array" "reduceRighti"

  (* external some : (('a -> bool)[@bs.uncurry]) -> bool = "some" [@@bs.send.pipe: 'a t as 'this] *)
  let some _ _ = notImplemented "Js.Array" "some"

  (* external somei : (('a -> int -> bool)[@bs.uncurry]) -> bool = "some" [@@bs.send.pipe: 'a t as 'this] *)
  let somei _ _ = notImplemented "Js.Array" "somei"

  (* commented out until bs has a plan for iterators
     (* external values : 'a array_iter = "" [@@bs.send.pipe: 'a t as 'this] (* ES2015 *) *)
     let values _ _ = notImplemented "Js.Array" "values"
  *)
  (* external unsafe_get : 'a array -> int -> 'a = "%array_unsafe_get" *)
  let unsafe_get _ _ = notImplemented "Js.Array" "unsafe_get"

  (* external unsafe_set : 'a array -> int -> 'a -> unit = "%array_unsafe_set" *)
  let unsafe_set _ _ = notImplemented "Js.Array" "unsafe_set"
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

  let source : t -> string = fun _ -> notImplemented "Js.Re" "source"

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
      let substrings = Pcre.exec ~rex ~pos:regexp.lastIndex str in
      let _, lastIndex = Pcre.get_substring_ofs substrings 0 in
      regexp.lastIndex <- lastIndex;
      Some { substrings }
    with Not_found -> None

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
  let fromCharCodeMany _ = notImplemented "Js.String" "fromCharCodeMany"

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
  let fromCodePointMany _ = notImplemented "Js.String" "fromCodePointMany"
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
  let get index str =
    let ch = Stdlib.String.get str index in
    Stdlib.String.make 1 ch

  (* external set : t -> int -> t -> t = "" [@@bs.set_index] *)

  (** [set s n c] sets the character at the given index number to the given character. If [n] is out of range, this function does nothing. *)

  (* external charAt : t -> int -> t = "charAt" [@@bs.send] *)

  (* TODO (davesnx): If the string contains characters outside the range [\u0000-\uffff], it will return the first 16-bit value at that position in the string. *)
  let charAt index str =
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
  let charCodeAt index str =
    if index < 0 || index >= Stdlib.String.length str then nan
    else float_of_int (Stdlib.Char.code (Stdlib.String.get str index))

  (* external codePointAt : t -> int -> int option = "codePointAt" [@@bs.send]  (** ES2015 *) *)

  (** [codePointAt n s] returns the code point at position [n] within string [s] as a [Some] value. The return value handles code points greater than or equal to [0x10000]. If there is no code point at the given position, the function returns [None].

@example {[
  codePointAt {js|¿😺?|js} 1 = Some 0x1f63a
  codePointAt "abc" 5 = None
]}
*)
  let codePointAt index str =
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
  let concat append original = Stdlib.String.concat "" [ original; append ]

  (* external concatMany : t -> t array -> t = "concat" [@@bs.send] [@@bs.splice] *)

  (** [concat arr original] returns a new string consisting of each item of an array of strings added to the [original] string.

@example {[
  concatMany "1st" [|"2nd"; "3rd"; "4th"|] = "1st2nd3rd4th";;
]}
*)

  let concatMany many original =
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
  let endsWith suffix str =
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
  let endsWithFrom from suffix str =
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
  let includes sub str =
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
  let includesFrom from sub str =
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
  let indexOf pattern str =
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
  let indexOfFrom from pattern str =
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
  let lastIndexOf pattern str =
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
  let lastIndexOfFrom from pattern str =
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
  let localeCompare _ _ = notImplemented "Js.String" "localeCompare"

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
  let match_ _ _ = notImplemented "Js.String" "match_"

  (* external normalize : t -> t = "normalize" [@@bs.send] (** ES2015 *) *)

  (** [normalize str] returns the normalized Unicode string using Normalization Form Canonical (NFC) Composition.

Consider the character [ã], which can be represented as the single codepoint [\u00e3] or the combination of a lower case letter A [\u0061] and a combining tilde [\u0303]. Normalization ensures that both can be stored in an equivalent binary representation.

@see <https://www.unicode.org/reports/tr15/tr15-45.html> Unicode technical report for details
*)
  let normalize _ _ = notImplemented "Js.String" "normalize"

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
  let normalizeByForm _ _ = notImplemented "Js.String" "normalizeByForm"

  (* external repeat : t -> int -> t = "repeat" [@@bs.send] (** ES2015 *) *)

  (* TODO(davesnx): RangeError *)

  (**
  [repeat n s] returns a string that consists of [n] repetitions of [s]. Raises [RangeError] if [n] is negative.

@example {[
  repeat "ha" 3 = "hahaha"
  repeat "empty" 0 = ""
]}
*)
  let repeat count str =
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
  let replace _ _ _ = notImplemented "Js.String" "replace"

  (* external replaceByRe : t -> Js_re.t -> t -> t = "replace" [@@bs.send] *)

  (** [replaceByRe regex replacement string] returns a new string where occurrences matching [regex]
have been replaced by [replacement].

@example {[
  replaceByRe "vowels be gone" [%re "/[aeiou]/g"] "x" = "vxwxls bx gxnx"
  replaceByRe "Juan Fulano" [%re "/(\\w+) (\\w+)/"] "$2, $1" = "Fulano, Juan"
]}
*)
  let replaceByRe _ _ _ = notImplemented "Js.String" "replaceByRe"

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
  Js.String.toUpperCase matchPart

let replaced = Js.String.unsafeReplaceBy0 str re matchFn

let () = Js.log replaced (* prints "bEAUtifUl vOwEls" *)
]}

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy0 _ _ = notImplemented "Js.String" "unsafeReplaceBy0"

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

let replaced = Js.String.unsafeReplaceBy1 str re matchFn

let () = Js.log replaced (* prints "increment 23 is 24" *)
]}

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy1 _ _ = notImplemented "Js.String" "unsafeReplaceBy1"

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

let replaced = Js.String.unsafeReplaceBy2 str re matchFn

let () = Js.log replaced (* prints "42" *)
]}

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy2 _ _ = notImplemented "Js.String" "unsafeReplaceBy2"

  (* external unsafeReplaceBy3 : t -> Js_re.t -> (t -> t -> t -> t -> int -> t -> t [@bs.
     uncurry]) -> t = "replace" [@@bs.send] *)

  (** returns a new string with some or all matches of a pattern with three sets of capturing
parentheses replaced by the value returned from the given function.
The function receives as its parameters the matched string, the captured strings,
the offset at which the match begins, and the whole string being matched.

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy3 _ _ = notImplemented "Js.String" "unsafeReplaceBy3"

  (* external search : t -> Js_re.t -> int = "search" [@@bs.send] *)

  (** [search regexp str] returns the starting position of the first match of [regexp] in the given [str], or -1 if there is no match.

@example {[
search "testing 1 2 3" [%re "/\\d+/"] = 8;;
search "no numbers" [%re "/\\d+/"] = -1;;
]}
*)
  let search _ _ = notImplemented "Js.String" "search"

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
  let slice ~from ~to_ str =
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
  let sliceToEnd ~from str =
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
  let split _str _delimiter = notImplemented "Js.String" "split"

  (* external splitAtMost: t -> t -> limit:int -> t array = "split" [@@bs.send] *)

  (**
  [splitAtMost delimiter ~limit: n str] splits the given [str] at every occurrence of [delimiter] and returns an array of the first [n] resulting substrings. If [n] is negative or greater than the number of substrings, the array will contain all the substrings.

@example {[
  splitAtMost "ant/bee/cat/dog/elk" "/" ~limit: 3 = [|"ant"; "bee"; "cat"|];;
  splitAtMost "ant/bee/cat/dog/elk" "/" ~limit: 0 = [| |];;
  splitAtMost "ant/bee/cat/dog/elk" "/" ~limit: 9 = [|"ant"; "bee"; "cat"; "dog"; "elk"|];;
]}
*)
  let splitAtMost _separator ~limit:_ _str =
    notImplemented "Js.String" "mplemented"

  (* external splitByRe : t -> Js_re.t -> t option array = "split" [@@bs.send] *)

  (**
  [splitByRe regex str] splits the given [str] at every occurrence of [regex] and returns an
  array of the resulting substrings.

@example {[
  splitByRe "art; bed , cog ;dad" [%re "/\\s*[,;]\\s*/"] = [|"art"; "bed"; "cog"; "dad"|];;
  splitByRe "has:no:match" [%re "/[,;]/"] = [|"has:no:match"|];;
]};
*)
  let splitByRe _ _ = notImplemented "Js.String" "splitByRe"

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
  let splitByReAtMost _ _ = notImplemented "Js.String" "splitByReAtMost"

  (* external startsWith : t -> t -> bool = "startsWith" [@@bs.send] *)

  (** ES2015:
    [startsWith substr str] returns [true] if the [str] starts with [substr], [false] otherwise.

@example {[
  startsWith "ReScript" "Re" = true;;
  startsWith "ReScript" "" = true;;
  startsWith "JavaScript" "Re" = false;;
]}
*)
  let startsWith prefix str =
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
  let startsWithFrom _str _index _ = notImplemented "Js.String" "mplemented"

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
  let substr ~from str =
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
  let substrAtMost ~from ~length str =
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
  let substring ~from ~to_ str =
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
  let substringToEnd ~from str =
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
  let toLocaleLowerCase _ _ = notImplemented "Js.String" "toLocaleLowerCase"

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
  let toLocaleUpperCase _ _ = notImplemented "Js.String" "toLocaleUpperCase"

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
  let anchor _ _ = notImplemented "Js.String" "anchor"

  (* external link : t -> t -> t = "link" [@@bs.send] (** ES2015 *) *)

  (**
  [link urlText linkText] creates a string withan HTML [<a>] element with [href] attribute of [urlText] and [linkText] as its content.

@example {[
  link "Go to page two" "page2.html" = "<a href=\"page2.html\">Go to page two</a>"
]}
*)
  let link _ _ = notImplemented "Js.String" "link"

  (* external castToArrayLike : t -> t Js_array2.array_like = "%identity" *)
  let castToArrayLike _ _ = notImplemented "Js.String" "castToArrayLike"
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
  let fromCharCodeMany _ _ = notImplemented "" "fromCharCodeMany"

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
  let fromCodePointMany _ = notImplemented "Js.String2" "fromCodePointMany"
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
  let localeCompare _ _ = notImplemented "Js.String2" "localeCompare"

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
  let match_ _ _ = notImplemented "Js.String2" "match_"

  (* external normalize : t -> t = "normalize" [@@bs.send] (** ES2015 *) *)

  (** [normalize str] returns the normalized Unicode string using Normalization Form Canonical (NFC) Composition.

Consider the character [ã], which can be represented as the single codepoint [\u00e3] or the combination of a lower case letter A [\u0061] and a combining tilde [\u0303]. Normalization ensures that both can be stored in an equivalent binary representation.

@see <https://www.unicode.org/reports/tr15/tr15-45.html> Unicode technical report for details
*)
  let normalize _ _ = notImplemented "Js.String2" "normalize"

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
  let normalizeByForm _ _ = notImplemented "Js.String2" "normalizeByForm"

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
  let replace _ _ _ = notImplemented "Js.String2" "replace"

  (* external replaceByRe : t -> Js_re.t -> t -> t = "replace" [@@bs.send] *)

  (** [replaceByRe regex replacement string] returns a new string where occurrences matching [regex]
have been replaced by [replacement].

@example {[
  replaceByRe "vowels be gone" [%re "/[aeiou]/g"] "x" = "vxwxls bx gxnx"
  replaceByRe "Juan Fulano" [%re "/(\\w+) (\\w+)/"] "$2, $1" = "Fulano, Juan"
]}
*)
  let replaceByRe _ _ _ = notImplemented "Js.String2" "replaceByRe"

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
  let unsafeReplaceBy0 _ _ = notImplemented "Js.String2" "unsafeReplaceBy0"

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
  let unsafeReplaceBy1 _ _ = notImplemented "Js.String2" "unsafeReplaceBy1"

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
  let unsafeReplaceBy2 _ _ = notImplemented "Js.String2" "unsafeReplaceBy2"

  (* external unsafeReplaceBy3 : t -> Js_re.t -> (t -> t -> t -> t -> int -> t -> t [@bs.
     uncurry]) -> t = "replace" [@@bs.send] *)

  (** returns a new string with some or all matches of a pattern with three sets of capturing
parentheses replaced by the value returned from the given function.
The function receives as its parameters the matched string, the captured strings,
the offset at which the match begins, and the whole string being matched.

@see <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter> MDN
*)
  let unsafeReplaceBy3 _ _ = notImplemented "Js.String2" "unsafeReplaceBy3"

  (* external search : t -> Js_re.t -> int = "search" [@@bs.send] *)

  (** [search regexp str] returns the starting position of the first match of [regexp] in the given [str], or -1 if there is no match.

@example {[
search "testing 1 2 3" [%re "/\\d+/"] = 8;;
search "no numbers" [%re "/\\d+/"] = -1;;
]}
*)
  let search _ _ = notImplemented "Js.String2" "search"

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
  let split _str _delimiter = notImplemented "Js.String2" "split"

  (* external splitAtMost: t -> t -> limit:int -> t array = "split" [@@bs.send] *)

  (**
  [splitAtMost delimiter ~limit: n str] splits the given [str] at every occurrence of [delimiter] and returns an array of the first [n] resulting substrings. If [n] is negative or greater than the number of substrings, the array will contain all the substrings.

@example {[
  splitAtMost "ant/bee/cat/dog/elk" "/" ~limit: 3 = [|"ant"; "bee"; "cat"|];;
  splitAtMost "ant/bee/cat/dog/elk" "/" ~limit: 0 = [| |];;
  splitAtMost "ant/bee/cat/dog/elk" "/" ~limit: 9 = [|"ant"; "bee"; "cat"; "dog"; "elk"|];;
]}
*)
  let splitAtMost _str _separator ~limit:_ =
    notImplemented "Js.String2" "mplemented"

  (* external splitByRe : t -> Js_re.t -> t option array = "split" [@@bs.send] *)

  (**
  [splitByRe regex str] splits the given [str] at every occurrence of [regex] and returns an
  array of the resulting substrings.

@example {[
  splitByRe "art; bed , cog ;dad" [%re "/\\s*[,;]\\s*/"] = [|"art"; "bed"; "cog"; "dad"|];;
  splitByRe "has:no:match" [%re "/[,;]/"] = [|"has:no:match"|];;
]};
*)
  let splitByRe _ _ = notImplemented "Js.String2" "splitByRe"

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
  let splitByReAtMost _ _ = notImplemented "Js.String2" "splitByReAtMost"

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
  let startsWithFrom _str _index _ = notImplemented "Js.String2" "mplemented"

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
  let toLocaleLowerCase _ _ = notImplemented "Js.String2" "toLocaleLowerCase"

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
  let toLocaleUpperCase _ _ = notImplemented "Js.String2" "toLocaleUpperCase"

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
  let anchor _ _ = notImplemented "Js.String2" "anchor"

  (* external link : t -> t -> t = "link" [@@bs.send] (** ES2015 *) *)

  (**
  [link urlText linkText] creates a string withan HTML [<a>] element with [href] attribute of [urlText] and [linkText] as its content.

@example {[
  link "Go to page two" "page2.html" = "<a href=\"page2.html\">Go to page two</a>"
]}
*)
  let link _ _ = notImplemented "Js.String2" "link"

  (* external castToArrayLike : t -> t Js_array2.array_like = "%identity" *)
  let castToArrayLike _ _ = notImplemented "Js.String2" "castToArrayLike"
  (* FIXME: we should not encourage people to use [%identity], better
      to provide something using [@@bs.val] so that we can track such
      casting
  *)
end

module Promise = struct
  include Promise
end

module Date = struct
  type t
  (** Provide bindings for JS Date *)

  (** returns the primitive value of this date, equivalent to getTime *)
  let valueOf _t = notImplemented "Js.Date" "valueOf"

  (** returns a date representing the current time *)
  let make _ = notImplemented "Js.Date" "make"

  let fromFloat _ = notImplemented "Js.Date" "fromFloat"
  let fromString _ = notImplemented "Js.Date" "fromString"
  let makeWithYM ~year:_ ~month:_ _ = notImplemented "Js.Date" "makeWithYM"

  let makeWithYMD ~year:_ ~month:_ ~date:_ _ =
    notImplemented "Js.Date" "makeWithYMD"

  let makeWithYMDH ~year:_ ~month:_ ~date:_ ~hours:__ _ =
    notImplemented "Js.Date" "makeWithYMDH"

  let makeWithYMDHM ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ _ t =
    notImplemented "Js.Date" "makeWithYMDHM"

  let makeWithYMDHMS ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ ~seconds:_ _ t
      =
    notImplemented "Js.Date" "makeWithYMDHMS"

  let utcWithYM ~year:_ ~month:_ _ = notImplemented "Js.Date" "utcWithYM"

  let utcWithYMD ~year:_ ~month:_ ~date:_ _ =
    notImplemented "Js.Date" "utcWithYMD"

  let utcWithYMDH ~year:_ ~month:_ ~date:_ ~hours:__ _ =
    notImplemented "Js.Date" "utcWithYMDH"

  let utcWithYMDHM ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ _ float =
    notImplemented "Js.Date" "utcWithYMDHM"

  let utcWithYMDHMS ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ ~seconds:_ _
      float =
    notImplemented "Js.Date" "utcWithYMDHMS"

  (** returns the number of milliseconds since Unix epoch *)
  let now _ = notImplemented "Js.Date" "now"

  let parse _ = notImplemented "Js.Date" "parse"

  (** returns NaN if passed invalid date string *)
  let parseAsFloat _ = notImplemented "Js.Date" "parseAsFloat"

  (** return the day of the month (1-31) *)
  let getDate _ _float = notImplemented "Js.Date" "getDate"

  (** returns the day of the week (0-6) *)
  let getDay _ _float = notImplemented "Js.Date" "getDay"

  let getFullYear _ _float = notImplemented "Js.Date" "getFullYear"
  let getHours _ _float = notImplemented "Js.Date" "getHours"
  let getMilliseconds _ _float = notImplemented "Js.Date" "getMilliseconds"
  let getMinutes _ _float = notImplemented "Js.Date" "getMinutes"

  (** returns the month (0-11) *)
  let getMonth _ _float = notImplemented "Js.Date" "getMonth"

  let getSeconds _ _float = notImplemented "Js.Date" "getSeconds"

  (** returns the number of milliseconds since Unix epoch *)
  let getTime _ _float = notImplemented "Js.Date" "getTime"

  let getTimezoneOffset _ _float = notImplemented "Js.Date" "getTimezoneOffset"

  (** return the day of the month (1-31) *)
  let getUTCDate _ _float = notImplemented "Js.Date" "getUTCDate"

  (** returns the day of the week (0-6) *)
  let getUTCDay _ _float = notImplemented "Js.Date" "getUTCDay"

  let getUTCFullYear _ _float = notImplemented "Js.Date" "getUTCFullYear"
  let getUTCHours _ _float = notImplemented "Js.Date" "getUTCHours"

  let getUTCMilliseconds _ _float =
    notImplemented "Js.Date" "getUTCMilliseconds"

  let getUTCMinutes _ _float = notImplemented "Js.Date" "getUTCMinutes"

  (** returns the month (0-11) *)
  let getUTCMonth _ _float = notImplemented "Js.Date" "getUTCMonth"

  let getUTCSeconds _ _float = notImplemented "Js.Date" "getUTCSeconds"
  let getYear _ _float = notImplemented "Js.Date" "getYear"
  let setDate _ _ = notImplemented "Js.Date" "setDate"
  let setFullYear _ _float = notImplemented "Js.Date" "setFullYear"

  let setFullYearM _ ~year:_ ~month:_ _ =
    notImplemented "Js.Date" "setFullYearM"

  let setFullYearMD _t ~year:_ ~month:_ ~date:_ _ =
    notImplemented "Js.Date" "setFullYearMD"

  let setHours _ _float = notImplemented "Js.Date" "setHours"
  let setHoursM t ~hours:_ ~minutes:_ = notImplemented "Js.Date" "setHoursM"
  let setHoursMS _t ~hours:_ ~minutes:_ = notImplemented "Js.Date" "setHoursMS"

  let setHoursMSMs _t ~hours:_ ~minutes:_ ~seconds:_ ~milliseconds:_ _ =
    notImplemented "Js.Date" "setHoursMSMs"

  let setMilliseconds _ _float = notImplemented "Js.Date" "setMilliseconds"
  let setMinutes _ _float = notImplemented "Js.Date" "setMinutes"
  let setMinutesS _ ~minutes:_ = notImplemented "Js.Date" "setMinutesS"
  let setMinutesSMs _t ~minutes:_ = notImplemented "Js.Date" "setMinutesSMs"
  let setMonth _ _float = notImplemented "Js.Date" "setMonth"
  let setMonthD t ~month:_ ~date:_ _ = notImplemented "Js.Date" "setMonthD"
  let setSeconds _ _float = notImplemented "Js.Date" "setSeconds"

  let setSecondsMs _ ~seconds:_ ~milliseconds:_ _ =
    notImplemented "Js.Date" "setSecondsMs"

  let setTime _ _float = notImplemented "Js.Date" "setTime"
  let setUTCDate _ _float = notImplemented "Js.Date" "setUTCDate"
  let setUTCFullYear _ _float = notImplemented "Js.Date" "setUTCFullYear"

  let setUTCFullYearM _ ~year:_ ~month:_ _ =
    notImplemented "Js.Date" "setUTCFullYearM"

  let setUTCFullYearMD _t ~year:_ ~month:_ ~date:_ _ =
    notImplemented "Js.Date" "setUTCFullYearMD"

  let setUTCHours _ _float = notImplemented "Js.Date" "setUTCHours"

  let setUTCHoursM t ~hours:_ ~minutes:_ =
    notImplemented "Js.Date" "setUTCHoursM"

  let setUTCHoursMS _t ~hours:_ ~minutes:_ =
    notImplemented "Js.Date" "setUTCHoursMS"

  let setUTCHoursMSMs _t ~hours:_ ~minutes:_ ~seconds:_ ~milliseconds:_ _ =
    notImplemented "Js.Date" "setUTCHoursMSMs"

  let setUTCMilliseconds _ _float =
    notImplemented "Js.Date" "setUTCMilliseconds"

  let setUTCMinutes _ _float = notImplemented "Js.Date" "setUTCMinutes"
  let setUTCMinutesS _ ~minutes:_ = notImplemented "Js.Date" "setUTCMinutesS"

  let setUTCMinutesSMs _t ~minutes:_ =
    notImplemented "Js.Date" "setUTCMinutesSMs"

  let setUTCMonth _ _float = notImplemented "Js.Date" "setUTCMonth"

  let setUTCMonthD t ~month:_ ~date:_ _ =
    notImplemented "Js.Date" "setUTCMonthD"

  let setUTCSeconds _ _float = notImplemented "Js.Date" "setUTCSeconds"
  let setUTCSecondsMs _t ~seconds:_ = notImplemented "Js.Date" "setUTCSecondsMs"
  let setUTCTime _ _float = notImplemented "Js.Date" "setUTCTime"
  let setYear _ _float = notImplemented "Js.Date" "setYear"
  let toDateString _ string = notImplemented "Js.Date" "toDateString"
  let toGMTString _ string = notImplemented "Js.Date" "toGMTString"
  let toISOString _ string = notImplemented "Js.Date" "toISOString"
  let toJSON _ string = notImplemented "Js.Date" "toJSON"
  let toJSONUnsafe _ string = notImplemented "Js.Date" "toJSONUnsafe"

  let toLocaleDateString _ string =
    notImplemented "Js.Date" "toLocaleDateString"

  (* TODO: has overloads with somewhat poor browser support *)
  let toLocaleString _ string = notImplemented "Js.Date" "toLocaleString"

  (* TODO: has overloads with somewhat poor browser support *)
  let toLocaleTimeString _ string =
    notImplemented "Js.Date" "toLocaleTimeString"

  (* TODO: has overloads with somewhat poor browser support *)
  let toString _ string = notImplemented "Js.Date" "toString"
  let toTimeString _ string = notImplemented "Js.Date" "toTimeString"
  let toUTCString _ string = notImplemented "Js.Date" "toUTCString"
end

module type Dictionary = sig
  (* Implemented as an assosiative list *)
  type 'a t
  type key = string

  val empty : unit -> 'a t
  val entries : 'a t -> (key * 'a) array
  val fromArray : (key * 'a) array -> 'a t
  val fromList : (key * 'a) list -> 'a t
  val keys : 'a t -> key array
  val values : 'a t -> 'a array
  val set : 'a t -> key -> 'a -> 'a t
  val get : 'a t -> key -> 'a option
  val unsafeGet : 'a t -> key -> 'a
  val map : ('a -> 'b) -> 'a t -> 'b t
  val unsafeDeleteKey : 'a t -> key -> 'a t
end

module Dict : Dictionary = struct
  (** Provide utilities for JS dictionary object *)

  type key = string
  type 'a t = (key * 'a) list

  exception NotFound

  let empty () : 'a t = []
  let entries (dict : 'a t) : (string * 'a) array = dict |> Stdlib.Array.of_list

  let get (dict : 'a t) (k : key) : 'a option =
    let rec get' dict k =
      match dict with
      | [] -> None
      | (k', x) :: rest -> if k = k' then Some x else get' rest k
    in
    get' dict k

  let map (f : 'a -> 'b) (dict : 'a t) =
    Stdlib.List.map (fun (k, a) -> (k, f a)) dict

  let set (dict : 'a t) (k : key) (x : 'a) : 'a t =
    let update (dict : 'a t) (key : key) (value : 'a) =
      Stdlib.List.map
        (fun (k, v) -> if Stdlib.String.equal k key then (k, value) else (k, v))
        dict
    in
    match get dict k with None -> (k, x) :: dict | Some v -> update dict k v

  let fromList (lst : (key * 'a) list) : 'a t =
    Stdlib.List.fold_left (fun acc (k, v) -> set acc k v) [] lst
    |> Stdlib.List.rev

  let fromArray (arr : (key * 'a) array) : 'a t =
    Stdlib.Array.to_list arr |> fromList

  let keys (dict : 'a t) =
    Stdlib.List.map (fun (k, _) -> k) dict |> Stdlib.Array.of_list

  let values (dict : 'a t) =
    Stdlib.List.map (fun (_, value) -> value) dict |> Stdlib.Array.of_list

  let unsafeGet (dict : 'a t) (k : key) : 'a =
    match get dict k with None -> raise NotFound | Some x -> x

  let unsafeDeleteKey (dict : 'a t) (key : key) =
    List.filter (fun (k, _) -> k <> key) dict
end

module Global = struct
  (** Contains functions available in the global scope
    ([window] in a browser context) *)

  type intervalId
  (** Identify an interval started by {! setInterval} *)

  type timeoutId
  (** Identify timeout started by {! setTimeout} *)

  let clearInterval _intervalId = notImplemented "Js.Global" "clearInterval"
  let clearTimeout _timeoutId = notImplemented "Js.Global" "clearTimeout"
  let setInterval _ _ = notImplemented "Js.Global" "setInterval"
  let setIntervalFloat _ _ = notImplemented "Js.Global" "setInterval"
  let setTimeout _ _ = notImplemented "Js.Global" "setTimeout"
  let setTimeoutFloat _ _ = notImplemented "Js.Global" "setTimeout"
  let encodeURI _string = notImplemented "Js.Global" "encodeURI"
  let decodeURI _string = notImplemented "Js.Global" "decodeURI"

  let encodeURIComponent _string =
    notImplemented "Js.Global" "encodeURIComponent"

  let decodeURIComponent _string =
    notImplemented "Js.Global" "decodeURIComponent"
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
  let test _ _ = notImplemented "Js.Types" "test"

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

  let classify _ = notImplemented "Js.Types" "classify"
end

module Json = struct
  (* Efficient JSON encoding using JavaScript API *)

  type t

  type _ kind =
    | String : String.t kind
    | Number : float kind
    | Object : t Dict.t kind
    | Array : t array kind
    | Boolean : bool kind
    | Null : Types.null_val kind

  type tagged_t =
    | JSONFalse
    | JSONTrue
    | JSONNull
    | JSONString of string
    | JSONNumber of float
    | JSONObject of t Dict.t
    | JSONArray of t array

  let classify (_x : t) : tagged_t = notImplemented "Js.Json" "mplemented"
  let test _ : bool = notImplemented "Js.Json" "test"
  let decodeString json = notImplemented "Js.Json" "decodeString"
  let decodeNumber json = notImplemented "Js.Json" "decodeNumber"
  let decodeObject json = notImplemented "Js.Json" "decodeObject"
  let decodeArray json = notImplemented "Js.Json" "decodeArray"
  let decodeBoolean (json : t) = notImplemented "Js.Json" "mplemented"
  let decodeNull json = notImplemented "Js.Json" "decodeNull"

  (* external parse : string -> t = "parse"
     [@@mel.val][@@mel.scope "JSON"] *)

  (* external parseExn : string -> t = "parse" [@@mel.val] [@@mel.scope "JSON"] *)
  let parseExn _ = notImplemented "Js.Json" "parseExn"

  (* external stringifyAny : 'a -> string option = "stringify"
     [@@mel.val] [@@mel.scope "JSON"] *)
  let stringifyAny _ = notImplemented "Js.Json" "stringifyAny"

  (* external null : t = "null" [@@mel.val] *)
  let null _ = notImplemented "Js.Json" "null"

  (* external undefined : t = "undefined" [@@mel.val] *)
  (* external string : string -> t = "%identity" *)
  let string _ = notImplemented "Js.Json" "string"

  (* external number : float -> t = "%identity" *)
  let number _ = notImplemented "Js.Json" "number"

  (* external boolean : bool -> t = "%identity" *)
  let boolean _ = notImplemented "Js.Json" "boolean"

  (* external object_ : t Js_dict.t -> t = "%identity" *)
  let object_ _ = notImplemented "Js.Json" "object_"

  (* external array : t array -> t = "%identity" *)
  let array _ = notImplemented "Js.Json" "array"

  (* external stringArray : string array -> t = "%identity" *)
  let stringArray _ = notImplemented "Js.Json" "stringArray"

  (* external numberArray : float array -> t = "%identity" *)
  let numberArray _ = notImplemented "Js.Json" "numberArray"

  (* external booleanArray : bool array -> t = "%identity" *)
  let booleanArray _ = notImplemented "Js.Json" "booleanArray"

  (* external objectArray : t Js_dict.t array -> t = "%identity" *)
  let objectArray _ = notImplemented "Js.Json" "objectArray"

  (* external stringify : t -> string = "stringify"
     [@@mel.val] [@@mel.scope "JSON"] *)
  let stringify _ = notImplemented "Js.Json" "stringify"

  (* external stringifyWithSpace :
     t -> (_[@mel.as {json|null|json}]) -> int -> string = "stringify"
     [@@mel.val] [@@mel.scope "JSON"] *)
  let stringifyWithSpace _ = notImplemented "Js.Json" "stringifyWithSpace"

  (* in memory modification does not work until your root is
     actually None, so we need wrap it as `[v]` and
     return the first element instead *)

  let patch _ = notImplemented "Js.Json" "patch"
  let serializeExn (_x : t) : string = notImplemented "Js.Json" "mplemented"

  let deserializeUnsafe (s : string) : 'a =
    notImplemented "Js.Json" "mplemented"
end

module Math = struct
  (** JavaScript Math API *)

  (** Euler's number *)
  let _E = 2.718281828459045

  (** natural logarithm of 2 *)
  let _LN2 = 0.6931471805599453

  (** natural logarithm of 10 *)
  let _LN10 = 2.302585092994046

  (** base 2 logarithm of E *)
  let _LOG2E = 1.4426950408889634

  (** base 10 logarithm of E *)
  let _LOG10E = 0.4342944819032518

  (** Pi... (ratio of the circumference and diameter of a circle) *)
  let _PI = 3.141592653589793

  (** square root of 1/2 *)
  let _SQRT1_2 = 0.7071067811865476

  (** square root of 2 *)
  let _SQRT2 = 1.41421356237

  (** absolute value *)
  let abs_int _ = notImplemented "Js.Math" "abs_int"

  let abs_float _ = notImplemented "Js.Math" "abs_float"

  (** absolute value *)

  let acos _ = notImplemented "Js.Math" "acos"

  (** arccosine in radians, can return NaN *)

  let acosh _ = notImplemented "Js.Math" "acosh"

  (** hyperbolic arccosine in raidans, can return NaN, ES2015 *)

  let asin _ = notImplemented "Js.Math" "asin"

  (** arcsine in radians, can return NaN *)

  let asinh _ = notImplemented "Js.Math" "asinh"

  (** hyperbolic arcsine in raidans, ES2015 *)

  let atan _ = notImplemented "Js.Math" "atan"

  (** arctangent in radians *)

  let atanh _ = notImplemented "Js.Math" "atanh"

  (** hyperbolic arctangent in radians, can return NaN, ES2015 *)

  let atan2 ~y:_ ~x:_ = notImplemented "Js.Math" "atan2"

  (** arctangent of the quotient of x and y, mostly... this one's a bit weird *)

  let cbrt _ = notImplemented "Js.Math" "cbrt"

  (** cube root, can return NaN, ES2015 *)

  let unsafe_ceil_int _ = notImplemented "Js.Math" "unsafe_ceil_int"

  (** may return values not representable by [int] *)

  let unsafe_ceil _ = notImplemented "Js.Math" "unsafe_ceil"

  (** smallest int greater than or equal to the argument *)
  let ceil_int _ _ = notImplemented "Js.Math" "ceil_int"

  let ceil _ = notImplemented "Js.Math" "ceil"
  let ceil_float _ = notImplemented "Js.Math" "ceil_float"

  (** smallest float greater than or equal to the argument *)

  let clz32 _ = notImplemented "Js.Math" "clz32"

  (** number of leading zero bits of the argument's 32 bit int representation, ES2015 *)
  (* can convert string, float etc. to number *)

  let cos _ = notImplemented "Js.Math" "cos"

  (** cosine in radians *)

  let cosh _ = notImplemented "Js.Math" "cosh"

  (** hyperbolic cosine in radians, ES2015 *)

  let exp _ = notImplemented "Js.Math" "exp"

  (** natural exponentional *)

  let expm1 _ = notImplemented "Js.Math" "expm1"

  (** natural exponential minus 1, ES2015 *)

  (** may return values not representable by [int] *)
  let unsafe_floor_int _ = notImplemented "Js.Math" "unsafe_floor_int"

  let unsafe_floor _ = notImplemented "Js.Math" "unsafe_floor"

  (** largest int greater than or equal to the arugment *)
  let floor_int _f = notImplemented "Js.Math" "floor_int"

  let floor _ = notImplemented "Js.Math" "floor"
  let floor_float _ = notImplemented "Js.Math" "floor_float"
  let fround _ = notImplemented "Js.Math" "fround"

  (** round to nearest single precision float, ES2015 *)

  let hypot _ = notImplemented "Js.Math" "hypot"

  (** pythagorean equation, ES2015 *)

  (** generalized pythagorean equation, ES2015 *)
  let hypotMany _ _array = notImplemented "Js.Math" "hypotMany"

  let imul _ = notImplemented "Js.Math" "imul"

  (** 32-bit integer multiplication, ES2015 *)

  let log _ = notImplemented "Js.Math" "log"

  (** natural logarithm, can return NaN *)

  let log1p _ = notImplemented "Js.Math" "log1p"

  (** natural logarithm of 1 + the argument, can return NaN, ES2015 *)

  let log10 _ = notImplemented "Js.Math" "log10"

  (** base 10 logarithm, can return NaN, ES2015 *)

  let log2 _ = notImplemented "Js.Math" "log2"

  (** base 2 logarithm, can return NaN, ES2015 *)

  let max_int _ = notImplemented "Js.Math" "max_int"

  (** max value *)

  (** max value *)
  let maxMany_int _ _array = notImplemented "Js.Math" "maxMany_int"

  let max_float _ = notImplemented "Js.Math" "max_float"

  (** max value *)

  (** max value *)
  let maxMany_float _ _array = notImplemented "Js.Math" "maxMany_float"

  let min_int _ = notImplemented "Js.Math" "min_int"

  (** min value *)

  (** min value *)
  let minMany_int _ _array = notImplemented "Js.Math" "minMany_int"

  let min_float _ = notImplemented "Js.Math" "min_float"

  (** min value *)

  (** min value *)
  let minMany_float _ _array = notImplemented "Js.Math" "minMany_float"

  (** base to the power of the exponent *)
  let pow_int ~base:_ ~exp:_ = notImplemented "Js.Math" "pow_int"

  let pow_float ~base:_ ~exp:_ = notImplemented "Js.Math" "pow_float"

  (** base to the power of the exponent *)

  let random _ = notImplemented "Js.Math" "random"

  (** random number in \[0,1) *)

  (** random number in \[min,max) *)
  let random_int _min _max = notImplemented "Js.Math" "random_int"

  let unsafe_round _ = notImplemented "Js.Math" "unsafe_round"

  (** rounds to nearest integer, returns a value not representable as [int] if NaN *)

  let round _ = notImplemented "Js.Math" "round"

  (** rounds to nearest integer *)

  let sign_int _ = notImplemented "Js.Math" "sign_int"

  (** the sign of the argument, 1, -1 or 0, ES2015 *)

  let sign_float _ = notImplemented "Js.Math" "sign_float"

  (** the sign of the argument, 1, -1, 0, -0 or NaN, ES2015 *)

  (** sine in radians *)
  let sin _ = notImplemented "Js.Math" "sin"

  (** hyperbolic sine in radians, ES2015 *)
  let sinh _ = notImplemented "Js.Math" "sinh"

  (** square root, can return NaN *)
  let sqrt _ = notImplemented "Js.Math" "sqrt"

  (** tangent in radians *)
  let tan _ = notImplemented "Js.Math" "tan"

  (** hyperbolic tangent in radians, ES2015 *)
  let tanh _ = notImplemented "Js.Math" "tanh"

  (** truncate, ie. remove fractional digits, returns a value not representable as [int] if NaN, ES2015 *)
  let unsafe_trunc _ = notImplemented "Js.Math" "unsafe_trunc"

  (** truncate, ie. remove fractional digits, returns a value not representable as [int] if NaN, ES2015 *)
  let trunc _ = notImplemented "Js.Math" "trunc"
end

module Obj = struct
  (** Provide utilities for {!Js.t} *)

  let empty _ = notImplemented "Js.Obj" "empty"
  let assign _ _ = notImplemented "Js.Obj" "assign"
  let keys _ = notImplemented "Js.Obj" "keys"
end

module Typed_array = struct
  (** Provide bindings for JS typed array *)
  module Uint16Array = struct
    type t
  end

  module Uint8ClampedArray = struct
    type t
  end

  module Float32Array = struct
    type t
  end
end

module TypedArray2 = struct
  (** Provide bindings for JS typed array *)
end

module Float = struct
  (** Provides functions for inspecting and manipulating [float]s *)

  let _NaN = Stdlib.Float.nan
  let isNaN _ = notImplemented "Js.Float" "isNaN"
  let isFinite _ = notImplemented "Js.Float" "isFinite"
  let toExponential _ = notImplemented "Js.Float" "toExponential"

  let toExponentialWithPrecision _ ~digits:_ =
    notImplemented "Js.Float" "toExponentialWithPrecision"

  let toFixed _ = notImplemented "Js.Float" "toFixed"

  let toFixedWithPrecision _ ~digits:_ =
    notImplemented "Js.Float" "toFixedWithPrecision"

  let toPrecision _ = notImplemented "Js.Float" "toPrecision"

  let toPrecisionWithPrecision _ ~digits:_ =
    notImplemented "Js.Float" "toPrecisionWithPrecision"

  let toString _ = notImplemented "Js.Float" "toString"

  let toStringWithRadix _ ~radix:_ =
    notImplemented "Js.Float" "toStringWithRadix"

  let fromString _ = notImplemented "Js.Float" "fromString"
end

module Int = struct
  (** Provides functions for inspecting and manipulating [int]s *)

  let toExponential _ = notImplemented "Js.Int" "toExponential"

  let toExponentialWithPrecision _ ~digits:_ =
    notImplemented "Js.Int" "toExponentialWithPrecision"

  let toPrecision _ = notImplemented "Js.Int" "toPrecision"

  let toPrecisionWithPrecision _ ~digits:_ =
    notImplemented "Js.Int" "toPrecisionWithPrecision"

  let toString _ = notImplemented "Js.Int" "toString"
  let toStringWithRadix _ ~radix:_ = notImplemented "Js.Int" "toStringWithRadix"
  let toFloat _ = notImplemented "Js.Int" "toFloat"
  let equal _a _b = notImplemented "Js.Int" "equal"
  let max = 2147483647
  let min = -2147483648
end

module Bigint = struct
  (** Provide utilities for bigint *)
end

module Option = struct
  (** Provide utilities for option *)

  type 'a t = 'a option

  let some _ = notImplemented "Js.Option" "some"
  let isSome _ = notImplemented "Js.Option" "isSome"
  let isSomeValue _ _ _ = notImplemented "Js.Option" "isSomeValue"
  let isNone _ = notImplemented "Js.Option" "isNone"
  let getExn _ = notImplemented "Js.Option" "getExn"
  let equal _ _ = notImplemented "Js.Option" "equal"
  let andThen _ _ = notImplemented "Js.Option" "andThen"
  let map _ _ = notImplemented "Js.Option" "map"
  let getWithDefault _ _ = notImplemented "Js.Option" "getWithDefault"
  let default _ = notImplemented "Js.Option" "default"
  let filter _ _ = notImplemented "Js.Option" "filter"
  let firstSome _ _ = notImplemented "Js.Option" "firstSome"
end

module Result = struct
  (** Define the interface for result *)
  type (+'good, +'bad) t = Ok of 'good | Error of 'bad
  [@@deprecated "Please use `Belt.Result.t` instead"]
end

module List = struct
  type 'a t = 'a list
  (** Provide utilities for list *)

  let length _ = notImplemented "Js.List" "length"
  let cons _ = notImplemented "Js.List" "cons"
  let isEmpty _ = notImplemented "Js.List" "isEmpty"
  let hd _ = notImplemented "Js.List" "hd"
  let tl _ = notImplemented "Js.List" "tl"
  let nth _ = notImplemented "Js.List" "nth"
  let revAppend _ = notImplemented "Js.List" "revAppend"
  let rev _ = notImplemented "Js.List" "rev"
  let mapRev _ = notImplemented "Js.List" "mapRev"
  let map _ _ = notImplemented "Js.List" "map"
  let iter _ _ = notImplemented "Js.List" "iter"
  let iteri _ _ = notImplemented "Js.List" "iteri"
  let foldLeft _ _ _ = notImplemented "Js.List" "foldLeft"
  let foldRight _ _ _ = notImplemented "Js.List" "foldRight"
  let flatten _ = notImplemented "Js.List" "flatten"
  let filter _ _ = notImplemented "Js.List" "filter"
  let filterMap _ _ = notImplemented "Js.List" "filterMap"
  let countBy _ _ = notImplemented "Js.List" "countBy"
  let init _ _ = notImplemented "Js.List" "init"
  let toVector _ = notImplemented "Js.List" "toVector"
  let equal _ _ = notImplemented "Js.List" "equal"
end

module Vector = struct
  (** Provide utilities for Vector *)

  type 'a t = 'a array

  let filterInPlace _ = notImplemented "Js.Vector" "filterInPlace"
  let empty _ = notImplemented "Js.Vector" "empty"
  let pushBack _ = notImplemented "Js.Vector" "pushBack"
  let copy _ = notImplemented "Js.Vector" "copy"
  let memByRef _ = notImplemented "Js.Vector" "memByRef"
  let iter _ = notImplemented "Js.Vector" "iter"
  let iteri _ = notImplemented "Js.Vector" "iteri"
  let toList _ = notImplemented "Js.Vector" "toList"
  let map _ = notImplemented "Js.Vector" "map"
  let mapi _ = notImplemented "Js.Vector" "mapi"
  let foldLeft _ = notImplemented "Js.Vector" "foldLeft"
  let foldRight _ = notImplemented "Js.Vector" "foldRight"

  external length : 'a t -> int = "%array_length"
  external get : 'a t -> int -> 'a = "%array_safe_get"
  external set : 'a t -> int -> 'a -> unit = "%array_safe_set"
  external make : int -> 'a -> 'a t = "caml_make_vect"

  let init _ = notImplemented "Js.Vector" "init"
  let append _ = notImplemented "Js.Vector" "append"

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

  (* external trace : _ unit = "trace" [@@bs.val] [@@bs.scope "console"] *)
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

  type t
end

module WeakSet = struct
  (** Provides bindings for ES6 WeakSet *)

  type t
end

module Map = struct
  (** Provides bindings for ES6 Map *)

  type t
end

module WeakMap = struct
  (** Provides bindings for ES6 WeakMap *)

  type t
end
