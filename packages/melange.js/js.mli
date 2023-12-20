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

module Array : sig
  type 'a t = 'a array
  type 'a array_like

  val from : 'a array_like -> 'a t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromMap : 'a array_like -> f:('a -> 'b) -> 'b t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val isArray : 'a array -> bool
  val length : 'a array -> int

  val copyWithin : to_:int -> ?start:int -> ?end_:int -> 'a t -> 'a t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fill : value:'a -> ?start:int -> ?end_:int -> 'a t -> 'a t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val pop : 'a t -> 'a nullable
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val push : value:'a -> 'a t -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val pushMany : values:'a t -> 'a t -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val reverseInPlace : 'a t -> 'a t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val shift : 'a t -> 'a option
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sortInPlace : 'a t -> 'a t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sortInPlaceWith : f:('a -> 'a -> int) -> 'a t -> 'a t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val spliceInPlace : start:int -> remove:int -> add:'a t -> 'a t -> 'a t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val removeFromInPlace : start:int -> 'a t -> 'a t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val removeCountInPlace : start:int -> count:int -> 'a t -> 'a t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unshift : value:'a -> 'a t -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unshiftMany : values:'a t -> 'a t -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val concat : other:'a t -> 'a t -> 'a t
  val concatMany : arrays:'a t t -> 'a t -> 'a t
  val includes : value:'a -> 'a t -> bool
  val indexOf : value:'a -> ?start:int -> 'a t -> int
  val join : ?sep:string -> 'a t -> string
  val lastIndexOf : value:'a -> 'a t -> int
  val lastIndexOfFrom : value:'a -> start:int -> 'a t -> int
  val slice : ?start:int -> ?end_:int -> 'a t -> 'a t
  val copy : 'a array -> 'a array

  val toString : 'a t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toLocaleString : 'a t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val everyi : f:('a -> int -> bool) -> 'a t -> bool
  val every : f:('a -> bool) -> 'a t -> bool
  val filter : f:('a -> bool) -> 'a t -> 'a t
  val filteri : f:('a -> int -> bool) -> 'a t -> 'a t
  val findi : f:('a -> int -> bool) -> 'a t -> 'a nullable
  val find : f:('a -> bool) -> 'a t -> 'a nullable
  val findIndexi : f:('a -> int -> bool) -> 'a t -> int
  val findIndex : f:('a -> bool) -> 'a t -> int
  val forEach : f:('a -> unit) -> 'a t -> unit
  val forEachi : f:('a -> int -> unit) -> 'a t -> unit
  val map : f:('a -> 'b) -> 'a t -> 'b t
  val mapi : f:('a -> int -> 'b) -> 'a t -> 'b t
  val reduce : f:('b -> 'a -> 'b) -> init:'b -> 'a t -> 'b
  val reducei : f:('b -> 'a -> int -> 'b) -> init:'b -> 'a t -> 'b
  val reduceRight : f:('b -> 'a -> 'b) -> init:'b -> 'a t -> 'b
  val reduceRighti : f:('b -> 'a -> int -> 'b) -> init:'b -> 'a t -> 'b
  val some : f:('a -> bool) -> 'a t -> bool
  val somei : f:('a -> int -> bool) -> 'a t -> bool
  val unsafe_get : 'a array -> int -> 'a
  val unsafe_set : 'a array -> int -> 'a -> unit
end

module Re : sig
  type t
  type result

  val captures : result -> string Nullable.t array
  val index : result -> int
  val input : result -> string
  val fromString : string -> t
  val fromStringWithFlags : string -> flags:string -> t
  val flags : t -> string
  val global : t -> bool
  val ignoreCase : t -> bool
  val lastIndex : t -> int
  val setLastIndex : t -> int -> unit
  val multiline : t -> bool
  val source : t -> string
  val sticky : t -> bool
  val unicode : t -> bool
  val exec : str:string -> t -> result option
  val test : str:string -> t -> bool

  val matches : result -> string array
  (** Only available in native, not in melange *)
end

module String : sig
  type t = string

  val make : 'a -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromCharCode : int -> t

  val fromCharCodeMany : int array -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromCodePoint : int -> t

  val fromCodePointMany : int array -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val length : t -> int
  val get : t -> int -> t
  val charAt : index:int -> t -> t
  val charCodeAt : index:int -> t -> float
  val codePointAt : index:int -> t -> int nullable
  val concat : other:t -> t -> t
  val concatMany : strings:t array -> t -> t
  val endsWith : suffix:t -> ?len:int -> t -> bool
  val includes : search:t -> ?start:int -> t -> bool
  val indexOf : search:t -> ?start:int -> t -> int
  val lastIndexOf : search:t -> ?start:int -> t -> int

  val localeCompare : other:t -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val match_ : regexp:Re.t -> t -> t nullable array nullable

  val normalize : ?form:[ `NFC | `NFD | `NFKC | `NFKD ] -> t -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val repeat : count:int -> t -> t

  val replace : search:t -> replacement:t -> t -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val replaceByRe : regexp:Re.t -> replacement:t -> t -> t

  val unsafeReplaceBy0 : regexp:Re.t -> f:(t -> int -> t -> t) -> t -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafeReplaceBy1 : regexp:Re.t -> f:(t -> t -> int -> t -> t) -> t -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafeReplaceBy2 :
    regexp:Re.t -> f:(t -> t -> t -> int -> t -> t) -> t -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafeReplaceBy3 :
    regexp:Re.t -> f:(t -> t -> t -> t -> int -> t -> t) -> t -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val search : regexp:Re.t -> t -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val slice : ?start:int -> ?end_:int -> t -> t

  val split : ?sep:t -> ?limit:int -> t -> t array
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val splitByRe : regexp:Re.t -> ?limit:int -> t -> t nullable array
  val startsWith : prefix:t -> ?start:int -> t -> bool
  val substr : ?start:int -> ?len:int -> t -> t
  val substring : ?start:int -> ?end_:int -> t -> t
  val toLowerCase : t -> t

  val toLocaleLowerCase : t -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toUpperCase : t -> t

  val toLocaleUpperCase : t -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val trim : t -> t

  val anchor : name:t -> t -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val link : href:t -> t -> t
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
