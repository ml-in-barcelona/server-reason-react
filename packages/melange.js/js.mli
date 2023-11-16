(** The Js equivalent library (very unsafe) *)

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

module Internal : sig end

type 'a null = 'a option
type 'a undefined = 'a null
type 'a nullable = 'a undefined

external toOption : 'a null -> 'a option = "%identity"
external nullToOption : 'a null -> 'a option = "%identity"
external undefinedToOption : 'a null -> 'a option = "%identity"
external fromOpt : 'a option -> 'a undefined = "%identity"
val undefined : 'a option
val null : 'a option
val empty : 'a option

type (+'a, +'e) promise

val typeof : 'a -> 'b
[@@alert
  not_implemented "is not implemented in native under server-reason-react.js"]

module Null : sig
  type 'a t = 'a nullable

  external toOption : 'a t -> 'a nullable = "%identity"
  external fromOpt : 'a nullable -> 'a t = "%identity"
  val empty : 'a nullable
  val return : 'a -> 'a nullable
  val getUnsafe : 'a t -> 'a
  val test : 'a nullable -> bool

  val getExn : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val bind : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val iter : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromOption : 'a nullable -> 'a t
  val from_opt : 'a nullable -> 'a t
end

module Undefined : sig
  type 'a t = 'a nullable

  external return : 'a -> 'a t = "%identity"
  val empty : 'a nullable
  external toOption : 'a t -> 'a nullable = "%identity"
  external fromOpt : 'a nullable -> 'a t = "%identity"

  val getExn : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUnsafe : 'a t -> 'a

  val bind : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val iter : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val testAny : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val test : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromOption : 'a nullable -> 'a t
  val from_opt : 'a nullable -> 'a t
end

module Nullable : sig
  type 'a t = 'a nullable

  external toOption : 'a t -> 'a nullable = "%identity"
  external to_opt : 'a t -> 'a nullable = "%identity"
  val return : 'a -> 'a t
  val isNullable : 'a t -> bool
  val null : 'a t
  val undefined : 'a t
  val bind : 'b t -> ('b -> 'b) -> 'b t
  val iter : 'a t -> ('a -> unit) -> unit
  val fromOption : 'a nullable -> 'a t
  val from_opt : 'a nullable -> 'a t
end

module Null_undefined = Nullable

module Exn : sig
  type t

  type exn +=
    | Error of string
    | EvalError of string
    | RangeError of string
    | ReferenceError of string
    | SyntaxError of string
    | TypeError of string
    | UriError of string

  val asJsExn : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val stack : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val message : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val name : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fileName : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val anyToExnInternal : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val isCamlExceptionOrOpenVariant : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val raiseError : string -> 'a
  val raiseEvalError : string -> 'a
  val raiseRangeError : string -> 'a
  val raiseReferenceError : string -> 'a
  val raiseSyntaxError : string -> 'a
  val raiseTypeError : string -> 'a
  val raiseUriError : string -> 'a
end

module Array2 : sig
  type 'a t = 'a array
  type 'a array_like

  val from : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromMap : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val isArray : 'a array -> bool
  val length : 'a array -> int

  val copyWithin : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val copyWithinFrom : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val copyWithinFromRange : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fillInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fillFromInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fillRangeInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val pop : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val push : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val pushMany : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val reverseInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sortInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sortInPlaceWith : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val spliceInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val removeFromInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val removeCountInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unshift : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unshiftMany : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val append : 'a array -> 'a -> 'a array
  val concat : 'a array -> 'a array -> 'a array
  val concatMany : 'a array -> 'a list -> 'a array
  val includes : 'a array -> 'a -> bool
  val indexOf : 'a array -> 'a -> int
  val indexOfFrom : 'a array -> 'a -> from:int -> int
  val joinWith : string array -> string -> string
  val join : string array -> string
  val lastIndexOf : 'a -> 'a array -> int
  val lastIndexOfFrom : 'a array -> 'a -> from:int -> int
  val slice : 'a array -> start:int -> end_:int -> 'a array
  val copy : 'a array -> 'a array
  val sliceFrom : 'a array -> int -> 'a array

  val toString : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toLocaleString : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val entries : 'a array -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val everyi : 'a array -> ('a -> int -> bool) -> bool
  val every : 'a array -> ('a -> bool) -> bool
  val filter : 'a array -> ('a -> bool) -> 'a array
  val filteri : 'a array -> (int -> 'a -> bool) -> 'a array
  val findi : 'a array -> ('a -> int -> bool) -> 'a nullable
  val find : 'a array -> ('a -> bool) -> 'a nullable
  val findIndexi : 'a array -> ('a -> int -> bool) -> int
  val findIndex : 'a array -> ('a -> bool) -> int
  val forEach : 'a array -> ('a -> unit) -> unit
  val forEachi : 'a array -> (int -> 'a -> unit) -> unit
  val map : 'a array -> ('a -> 'b) -> 'b array
  val mapi : 'a array -> (int -> 'a -> 'b) -> 'b array
  val reduce : 'a array -> ('b -> 'a -> 'b) -> 'b -> 'b
  val reducei : 'a array -> ('b -> 'a -> int -> 'b) -> 'b -> 'b
  val reduceRight : 'a array -> ('a -> 'b -> 'b) -> 'b -> 'b
  val reduceRighti : 'a array -> ('a -> 'b -> int -> 'b) -> 'b -> 'b
  val some : 'a array -> ('a -> bool) -> bool
  val somei : 'a array -> ('a -> int -> bool) -> bool
  val unsafe_get : 'a array -> int -> 'a
  val unsafe_set : 'a array -> int -> 'a -> unit
end

module Array : sig
  type 'a t = 'a array
  type 'a array_like = 'a Array2.array_like

  val from : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromMap : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val isArray : 'a array -> bool
  val length : 'a array -> int

  val copyWithin : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val copyWithinFrom : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val copyWithinFromRange : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fillInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fillFromInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fillRangeInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val pop : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val push : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val pushMany : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val reverseInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sortInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sortInPlaceWith : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val spliceInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val removeFromInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val removeCountInPlace : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unshift : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unshiftMany : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val append : 'a -> 'a array -> 'a array
  val concat : 'a array -> 'a array -> 'a array
  val concatMany : 'a list -> 'a array -> 'a array
  val includes : 'a -> 'a array -> bool
  val indexOf : 'a -> 'a array -> int
  val indexOfFrom : 'a array -> from:int -> 'a -> int
  val joinWith : string -> string array -> string
  val join : string array -> string
  val lastIndexOf : 'a array -> 'a -> int
  val lastIndexOfFrom : 'a array -> from:int -> 'a -> int

  val lastIndexOf_start : 'a -> 'a array -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val slice : start:int -> end_:int -> 'a array -> 'a array
  val copy : 'a array -> 'a array

  val slice_copy : unit -> 'a array -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sliceFrom : int -> 'a array -> 'a array

  val slice_start : int -> 'a array -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toString : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toLocaleString : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val entries : 'a array -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val everyi : ('a -> int -> bool) -> 'a array -> bool
  val every : ('a -> bool) -> 'a array -> bool
  val filter : ('a -> bool) -> 'a array -> 'a array
  val filteri : (int -> 'a -> bool) -> 'a array -> 'a array
  val findi : ('a -> int -> bool) -> 'a array -> 'a nullable
  val find : ('a -> bool) -> 'a array -> 'a nullable
  val findIndexi : ('a -> int -> bool) -> 'a array -> int
  val findIndex : ('a -> bool) -> 'a array -> int
  val forEach : ('a -> unit) -> 'a array -> unit
  val forEachi : (int -> 'a -> unit) -> 'a array -> unit
  val map : ('a -> 'b) -> 'a array -> 'b array
  val mapi : (int -> 'a -> 'b) -> 'a array -> 'b array
  val reduce : ('a -> 'b -> 'a) -> 'a -> 'b array -> 'a
  val reducei : ('a -> 'b -> int -> 'a) -> 'a -> 'b array -> 'a
  val reduceRight : ('a -> 'b -> 'b) -> 'b -> 'a array -> 'b
  val reduceRighti : ('a -> 'b -> int -> 'b) -> 'b -> 'a array -> 'b
  val some : ('a -> bool) -> 'a array -> bool
  val somei : ('a -> int -> bool) -> 'a array -> bool
  val unsafe_get : 'a array -> int -> 'a
  val unsafe_set : 'a array -> int -> 'a -> unit
end

module Re : sig
  type flag =
    [ `ANCHORED
    | `AUTO_CALLOUT
    | `CASELESS
    | `DOLLAR_ENDONLY
    | `DOTALL
    | `EXTENDED
    | `EXTRA
    | `FIRSTLINE
    | `GLOBAL
    | `MULTILINE
    | `NO_AUTO_CAPTURE
    | `NO_UTF8_CHECK
    | `STICKY
    | `UNGREEDY
    | `UNICODE
    | `UTF8 ]

  type t = { regex : Pcre.regexp; flags : flag list; mutable lastIndex : int }
  type result = { substrings : Pcre.substrings }

  val captures : result -> string null array
  val matches : result -> string array
  val index : result -> int
  val input : result -> string
  val source : t -> string
  val fromString : string -> t
  val char_of_cflag : Pcre.cflag -> char null
  val flag_of_char : char -> flag
  val parse_flags : string -> flag list
  val cflag_of_flag : flag -> Pcre.cflag null
  val fromStringWithFlags : string -> flags:string -> t
  val flags : t -> string
  val flag : t -> flag -> bool
  val global : t -> bool
  val ignoreCase : t -> bool
  val multiline : t -> bool
  val sticky : t -> bool
  val unicode : t -> bool
  val lastIndex : t -> int
  val setLastIndex : t -> int -> unit
  val exec_ : t -> string -> result null
  val exec : string -> t -> result null
  val test_ : t -> string -> bool
  val test : string -> t -> bool
end

module String2 : sig
  type t = string

  val make : int -> char -> string
  val fromCharCode : int -> string

  val fromCharCodeMany : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromCodePoint : int -> string
  val fromCodePointMany : 'a -> 'b
  val length : string -> int
  val get : string -> int -> string

  val set : 'a -> 'b -> 'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val charAt : string -> int -> string
  val charCodeAt : string -> int -> float
  val codePointAt : string -> int -> int nullable
  val concat : string -> string -> string
  val concatMany : string -> string array -> string
  val endsWith : string -> string -> bool
  val endsWithFrom : string -> string -> int -> bool
  val includes : string -> string -> bool
  val includesFrom : string -> string -> int -> bool
  val indexOf : string -> string -> int
  val indexOfFrom : string -> string -> int -> int
  val lastIndexOf : string -> string -> int
  val lastIndexOfFrom : string -> string -> int -> int

  val localeCompare : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val match_ : string -> Re.t -> string array nullable

  val normalize : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val normalizeByForm : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val repeat : string -> int -> string

  val replace : 'a -> 'b -> 'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val replaceByRe : string -> Re.t -> string -> string

  val unsafeReplaceBy0 : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafeReplaceBy1 : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafeReplaceBy2 : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafeReplaceBy3 : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val search : 'a -> 'b -> 'c
  val slice : string -> from:int -> to_:int -> string
  val sliceToEnd : string -> from:int -> string
  val split : 'a -> 'b -> 'c

  val splitAtMost : 'a -> 'b -> limit:'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val splitByReAtMost : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val splitByRe : string -> Re.t -> string nullable array
  val startsWith : string -> string -> bool

  val startsWithFrom : 'a -> 'b -> 'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val substr : string -> from:int -> string
  val substrAtMost : string -> from:int -> length:int -> string
  val substring : string -> from:int -> to_:int -> string
  val substringToEnd : string -> from:int -> string
  val toLowerCase : string -> string

  val toLocaleLowerCase : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toUpperCase : string -> string

  val toLocaleUpperCase : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val trim : string -> string

  val anchor : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val link : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val castToArrayLike : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

module String : sig
  type t = string

  val make : int -> char -> string
  val fromCharCode : int -> string

  val fromCharCodeMany : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromCodePoint : int -> string
  val fromCodePointMany : 'a -> 'b
  val length : string -> int
  val get : int -> string -> string
  val charAt : int -> string -> string
  val charCodeAt : int -> string -> float
  val codePointAt : int -> string -> int nullable
  val concatMany : string array -> string -> string
  val endsWith : string -> string -> bool
  val endsWithFrom : string -> int -> string -> bool
  val includes : string -> string -> bool
  val includesFrom : int -> string -> string -> bool
  val indexOf : string -> string -> int
  val indexOfFrom : int -> string -> string -> int
  val localeCompare : 'a -> 'b -> 'c
  val match_ : Re.t -> string -> string array nullable

  val normalize : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val normalizeByForm : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val replace : 'a -> 'b -> 'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val replaceByRe : Re.t -> string -> string -> string

  val unsafeReplaceBy0 : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafeReplaceBy1 : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafeReplaceBy2 : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafeReplaceBy3 : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val search : 'a -> 'b -> 'c
  val slice : from:int -> to_:int -> string -> string
  val sliceToEnd : from:int -> string -> string
  val split : 'a -> 'b -> 'c

  val splitAtMost : 'a -> limit:'b -> 'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val splitByRe : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val splitByReAtMost : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val startsWith : string -> string -> bool

  val startsWithFrom : 'a -> 'b -> 'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val substr : from:int -> string -> string
  val substrAtMost : from:int -> length:int -> string -> string
  val substring : from:int -> to_:int -> string -> string
  val substringToEnd : from:int -> string -> string
  val toLowerCase : string -> string

  val toLocaleLowerCase : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toUpperCase : string -> string
  val toLocaleUpperCase : 'a -> 'b -> 'c
  val trim : string -> string

  val anchor : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val link : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val castToArrayLike : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

module Promise : sig
  type 'a t = 'a Lwt.t
  type error = exn

  val make : (resolve:('a -> unit) -> reject:(exn -> unit) -> unit) -> 'a Lwt.t
  val resolve : 'a -> 'a Lwt.t
  val reject : exn -> 'a Lwt.t
  val all : 'a Lwt.t array -> 'a array Lwt.t
  val all2 : 'a Lwt.t * 'b Lwt.t -> ('a * 'b) Lwt.t
  val all3 : 'a Lwt.t * 'b Lwt.t * 'c Lwt.t -> ('a * 'b * 'c) Lwt.t

  val all4 :
    'a Lwt.t * 'b Lwt.t * 'c Lwt.t * 'd Lwt.t -> ('a * 'b * 'c * 'd) Lwt.t

  val all5 :
    'a Lwt.t * 'b Lwt.t * 'c Lwt.t * 'd Lwt.t * 'e Lwt.t ->
    ('a * 'b * 'c * 'd * 'e) Lwt.t

  val all6 :
    'a Lwt.t * 'b Lwt.t * 'c Lwt.t * 'd Lwt.t * 'e Lwt.t * 'f Lwt.t ->
    ('a * 'b * 'c * 'd * 'e * 'f) Lwt.t

  val race : 'a Lwt.t array -> 'a Lwt.t
  val then_ : ('a -> 'b Lwt.t) -> 'a Lwt.t -> 'b Lwt.t
  val catch : (exn -> 'a Lwt.t) -> 'a Lwt.t -> 'a Lwt.t
end

module Date : sig
  type t

  val valueOf : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val make : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromFloat : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromString : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val makeWithYM : year:'a -> month:'b -> 'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val makeWithYMD : year:'a -> month:'b -> date:'c -> 'd -> 'e
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val makeWithYMDH : year:'a -> month:'b -> date:'c -> hours:'d -> 'e -> 'f
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val makeWithYMDHM :
    year:'a -> month:'b -> date:'c -> hours:'d -> minutes:'e -> 'f -> 'g -> 'h
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val makeWithYMDHMS :
    year:'a ->
    month:'b ->
    date:'c ->
    hours:'d ->
    minutes:'e ->
    seconds:'f ->
    'g ->
    'h ->
    'i
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val utcWithYM : year:'a -> month:'b -> 'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val utcWithYMD : year:'a -> month:'b -> date:'c -> 'd -> 'e
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val utcWithYMDH : year:'a -> month:'b -> date:'c -> hours:'d -> 'e -> 'f
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val utcWithYMDHM :
    year:'a -> month:'b -> date:'c -> hours:'d -> minutes:'e -> 'f -> 'g -> 'h
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val utcWithYMDHMS :
    year:'a ->
    month:'b ->
    date:'c ->
    hours:'d ->
    minutes:'e ->
    seconds:'f ->
    'g ->
    'h ->
    'i
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val now : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val parse : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val parseAsFloat : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getDate : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getDay : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getFullYear : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getHours : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getMilliseconds : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getMinutes : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getMonth : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getSeconds : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getTime : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getTimezoneOffset : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCDate : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCDay : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCFullYear : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCHours : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCMilliseconds : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCMinutes : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCMonth : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCSeconds : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getYear : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setDate : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setFullYear : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setFullYearM : 'a -> year:'b -> month:'c -> 'd -> 'e
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setFullYearMD : 'a -> year:'b -> month:'c -> date:'d -> 'e -> 'f
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setHours : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setHoursM : 'a -> hours:'b -> minutes:'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setHoursMS : 'a -> hours:'b -> minutes:'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setHoursMSMs :
    'a -> hours:'b -> minutes:'c -> seconds:'d -> milliseconds:'e -> 'f -> 'g

  val setMilliseconds : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setMinutes : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setMinutesS : 'a -> minutes:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setMinutesSMs : 'a -> minutes:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setMonth : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setMonthD : 'a -> month:'b -> date:'c -> 'd -> 'e
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setSeconds : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setSecondsMs : 'a -> seconds:'b -> milliseconds:'c -> 'd -> 'e
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setTime : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCDate : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCFullYear : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCFullYearM : 'a -> year:'b -> month:'c -> 'd -> 'e
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCFullYearMD : 'a -> year:'b -> month:'c -> date:'d -> 'e -> 'f
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCHours : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCHoursM : 'a -> hours:'b -> minutes:'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCHoursMS : 'a -> hours:'b -> minutes:'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCHoursMSMs :
    'a -> hours:'b -> minutes:'c -> seconds:'d -> milliseconds:'e -> 'f -> 'g
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMilliseconds : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMinutes : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMinutesS : 'a -> minutes:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMinutesSMs : 'a -> minutes:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMonth : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMonthD : 'a -> month:'b -> date:'c -> 'd -> 'e
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCSeconds : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCSecondsMs : 'a -> seconds:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCTime : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setYear : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toDateString : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toGMTString : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toISOString : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toJSON : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toJSONUnsafe : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toLocaleDateString : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toLocaleString : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toLocaleTimeString : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toString : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toTimeString : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toUTCString : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

module type Dictionary = sig
  type 'a t
  type key = string

  val empty : unit -> 'a t
  val entries : 'a t -> (key * 'a) array
  val fromArray : (key * 'a) array -> 'a t
  val fromList : (key * 'a) list -> 'a t
  val keys : 'a t -> key array
  val values : 'a t -> 'a array
  val set : 'a t -> key -> 'a -> unit
  val get : 'a t -> key -> 'a nullable
  val unsafeGet : 'a t -> key -> 'a
  val map : ('a -> 'b) -> 'a t -> 'b t
  val unsafeDeleteKey : 'a t -> key -> unit
end

module Dict : Dictionary

module Global : sig
  type intervalId
  type timeoutId

  val clearInterval : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val clearTimeout : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setInterval : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setIntervalFloat : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setTimeout : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setTimeoutFloat : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val encodeURI : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val decodeURI : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val encodeURIComponent : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val decodeURIComponent : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

module Types : sig
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

  val test : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

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

  val classify : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

module Json : sig
  type t

  type _ kind =
    | String : string kind
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

  val classify : t -> tagged_t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val test : 'a -> bool
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val decodeString : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val decodeNumber : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val decodeObject : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val decodeArray : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val decodeBoolean : t -> 'a
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val decodeNull : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val parseExn : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val stringifyAny : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val null : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val string : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val number : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val boolean : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val object_ : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val array : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val stringArray : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val numberArray : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val booleanArray : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val objectArray : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val stringify : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val stringifyWithSpace : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val patch : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val serializeExn : t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val deserializeUnsafe : string -> 'a
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

module Math : sig
  val _E : float
  val _LN2 : float
  val _LN10 : float
  val _LOG2E : float
  val _LOG10E : float
  val _PI : float
  val _SQRT1_2 : float
  val _SQRT2 : float

  val abs_int : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val abs_float : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val acos : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val acosh : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val asin : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val asinh : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val atan : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val atanh : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val atan2 : y:'a -> x:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val cbrt : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafe_ceil_int : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafe_ceil : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val ceil_int : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val ceil : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val ceil_float : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val clz32 : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val cos : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val cosh : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val exp : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val expm1 : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafe_floor_int : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafe_floor : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val floor_int : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val floor : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val floor_float : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fround : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val hypot : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val hypotMany : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val imul : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val log : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val log1p : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val log10 : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val log2 : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val max_int : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val maxMany_int : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val max_float : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val maxMany_float : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val min_int : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val minMany_int : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val min_float : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val minMany_float : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val pow_int : base:'a -> exp:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val pow_float : base:'a -> exp:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val random : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val random_int : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafe_round : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val round : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sign_int : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sign_float : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sin : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sinh : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sqrt : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val tan : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val tanh : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafe_trunc : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val trunc : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

module Obj : sig
  val empty : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val assign : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val keys : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

module Typed_array : sig
  module Uint16Array : sig
    type t
  end

  module Uint8ClampedArray : sig
    type t
  end

  module Float32Array : sig
    type t
  end
end

module TypedArray2 : sig end

module Float : sig
  val _NaN : float
  val isNaN : float -> bool
  val isFinite : float -> bool

  val toExponential : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toExponentialWithPrecision : 'a -> digits:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toFixed : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toFixedWithPrecision : 'a -> digits:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toPrecision : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toPrecisionWithPrecision : 'a -> digits:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toString : float -> string

  val toStringWithRadix : 'a -> radix:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromString : string -> float
end

module Int : sig
  val toExponential : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toExponentialWithPrecision : 'a -> digits:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toPrecision : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toPrecisionWithPrecision : 'a -> digits:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toString : int -> string

  val toStringWithRadix : 'a -> radix:'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toFloat : int -> float
  val equal : string -> string -> bool
  val max : int
  val min : int
end

module Bigint : sig end

module Option : sig
  type 'a t = 'a nullable

  val some : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val isSome : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val isSomeValue : 'a -> 'b -> 'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val isNone : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getExn : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val equal : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val andThen : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val map : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getWithDefault : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val default : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val filter : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val firstSome : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

module List : sig
  type 'a t = 'a list

  val length : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val cons : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val isEmpty : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val hd : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val tl : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val nth : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val revAppend : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val rev : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val mapRev : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val map : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val iter : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val iteri : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val foldLeft : 'a -> 'b -> 'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val foldRight : 'a -> 'b -> 'c -> 'd
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val flatten : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val filter : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val filterMap : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val countBy : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val init : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toVector : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val equal : 'a -> 'b -> 'c
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

module Vector : sig
  type 'a t = 'a array

  val filterInPlace : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val empty : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val pushBack : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val copy : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val memByRef : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val iter : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val iteri : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toList : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val map : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val mapi : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val foldLeft : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val foldRight : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  external length : 'a t -> int = "%array_length"
  external get : 'a t -> int -> 'a = "%array_safe_get"
  external set : 'a t -> int -> 'a -> unit = "%array_safe_set"
  external make : int -> 'a -> 'a t = "caml_make_vect"

  val init : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val append : 'a -> 'b
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  external unsafe_get : 'a t -> int -> 'a = "%array_unsafe_get"
  external unsafe_set : 'a t -> int -> 'a -> unit = "%array_unsafe_set"
end

module Console : sig
  val log : string -> unit
  val log2 : string -> string -> unit
  val log3 : string -> string -> string -> unit
  val log4 : string -> string -> string -> string -> unit
  val logMany : string array -> unit
  val info : string -> unit
  val info2 : string -> string -> unit
  val info3 : string -> string -> string -> unit
  val info4 : string -> string -> string -> string -> unit
  val infoMany : string array -> unit
  val error : string -> unit
  val error2 : string -> string -> unit
  val error3 : string -> string -> string -> unit
  val error4 : string -> string -> string -> string -> unit
  val errorMany : string array -> unit
  val warn : string -> unit
  val warn2 : string -> string -> unit
  val warn3 : string -> string -> string -> unit
  val warn4 : string -> string -> string -> string -> unit
  val warnMany : string array -> unit

  val trace : unit -> unit
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val timeStart : 'a -> unit
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val timeEnd : 'a -> unit
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

val log : string -> unit
val log2 : string -> string -> unit
val log3 : string -> string -> string -> unit
val log4 : string -> string -> string -> string -> unit
val logMany : string array -> unit

module Set : sig
  type 'a t
end

module WeakSet : sig
  type 'a t
end

module Map : sig
  type ('k, 'v) t
end

module WeakMap : sig
  type ('k, 'v) t
end
