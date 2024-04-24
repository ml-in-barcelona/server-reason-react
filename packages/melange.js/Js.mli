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

(* TODO: we shouldn't expose 'a option *)
type 'a null = 'a option

(* TODO: we shouldn't expose 'a option *)
type 'a undefined = 'a null

(* TODO: we shouldn't expose 'a option *)
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
  val captures : result -> string Nullable.t array
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

  val valueOf : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val make : unit -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromFloat : float -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fromString : string -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val makeWithYM : year:float -> month:float -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val makeWithYMD : year:float -> month:float -> date:float -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val makeWithYMDH : year:float -> month:float -> date:float -> hours:float -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val makeWithYMDHM :
    year:float -> month:float -> date:float -> hours:float -> minutes:float -> t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val makeWithYMDHMS :
    year:float ->
    month:float ->
    date:float ->
    hours:float ->
    minutes:float ->
    seconds:float ->
    t
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val utcWithYM : year:float -> month:float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val utcWithYMD : year:float -> month:float -> date:float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val utcWithYMDH :
    year:float -> month:float -> date:float -> hours:float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val utcWithYMDHM :
    year:float ->
    month:float ->
    date:float ->
    hours:float ->
    minutes:float ->
    float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val utcWithYMDHMS :
    year:float ->
    month:float ->
    date:float ->
    hours:float ->
    minutes:float ->
    seconds:float ->
    float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val now : unit -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val parseAsFloat : string -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getDate : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getDay : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getFullYear : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getHours : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getMilliseconds : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getMinutes : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getMonth : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getSeconds : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getTime : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getTimezoneOffset : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCDate : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCDay : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCFullYear : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCHours : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCMilliseconds : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCMinutes : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCMonth : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val getUTCSeconds : t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setDate : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setFullYear : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setFullYearM : year:float -> month:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setFullYearMD : year:float -> month:float -> date:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setHours : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setHoursM : hours:float -> minutes:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setHoursMS : hours:float -> minutes:float -> seconds:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setHoursMSMs :
    hours:float ->
    minutes:float ->
    seconds:float ->
    milliseconds:float ->
    t ->
    float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setMilliseconds : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setMinutes : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setMinutesS : minutes:float -> seconds:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setMinutesSMs :
    minutes:float -> seconds:float -> milliseconds:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setMonth : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setMonthD : month:float -> date:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setSeconds : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setSecondsMs : seconds:float -> milliseconds:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setTime : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCDate : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCFullYear : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCFullYearM : year:float -> month:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCFullYearMD : year:float -> month:float -> date:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCHours : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCHoursM : hours:float -> minutes:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCHoursMS :
    hours:float -> minutes:float -> seconds:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCHoursMSMs :
    hours:float ->
    minutes:float ->
    seconds:float ->
    milliseconds:float ->
    t ->
    float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMilliseconds : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMinutes : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMinutesS : minutes:float -> seconds:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMinutesSMs :
    minutes:float -> seconds:float -> milliseconds:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMonth : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCMonthD : month:float -> date:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCSeconds : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCSecondsMs : seconds:float -> milliseconds:float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setUTCTime : float -> t -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toDateString : t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toISOString : t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toJSON : t -> string option
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toJSONUnsafe : t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toLocaleDateString : t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toLocaleString : t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toLocaleTimeString : t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toString : t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toTimeString : t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toUTCString : t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]
end

module type Dictionary = sig
  type 'a t

  type key = string
  (** Key type *)

  val get : 'a t -> key -> 'a option
  (** [get dict key] returns [None] if the [key] is not found in the
    dictionary, [Some value] otherwise *)

  val unsafeGet : 'a t -> key -> 'a

  val set : 'a t -> key -> 'a -> unit
  (** [set dict key value] sets the [key]/[value] in [dict] *)

  val keys : 'a t -> string array
  (** [keys dict] returns all the keys in the dictionary [dict]*)

  val empty : unit -> 'a t
  (** [empty ()] returns an empty dictionary *)

  val unsafeDeleteKey : string t -> string -> unit
  (** Experimental internal function *)

  val entries : 'a t -> (key * 'a) array
  (** [entries dict] returns the key value pairs in [dict] *)

  val values : 'a t -> 'a array
  (** [values dict] returns the values in [dict] *)

  val fromList : (key * 'a) list -> 'a t
  (** [fromList entries] creates a new dictionary containing each
[(key, value)] pair in [entries] *)

  val fromArray : (key * 'a) array -> 'a t
  (** [fromArray entries] creates a new dictionary containing each
[(key, value)] pair in [entries] *)

  val map : f:('a -> 'b) -> 'a t -> 'b t
  (** [map f dict] maps [dict] to a new dictionary with the same keys,
using [f] to map each value *)
end

module Dict : Dictionary

module Global : sig
  type intervalId
  type timeoutId

  val clearInterval : intervalId -> unit
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val clearTimeout : timeoutId -> unit
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setInterval : f:(unit -> unit) -> int -> intervalId
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setIntervalFloat : f:(unit -> unit) -> float -> intervalId
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setTimeout : f:(unit -> unit) -> int -> timeoutId
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val setTimeoutFloat : f:(unit -> unit) -> float -> timeoutId
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val encodeURI : string -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val decodeURI : string -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val encodeURIComponent : string -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val decodeURIComponent : string -> string
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

  val abs_int : int -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val abs_float : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val acos : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val acosh : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val asin : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val asinh : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val atan : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val atanh : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val atan2 : y:float -> x:float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val cbrt : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafe_ceil_int : float -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val ceil_int : float -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val ceil_float : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val clz32 : int -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val cos : float -> float

  val cosh : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val exp : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val expm1 : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafe_floor_int : float -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val floor_int : float -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val floor_float : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val fround : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val hypot : float -> float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val hypotMany : float array -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val imul : int -> int -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val log : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val log1p : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val log10 : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val log2 : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val max_int : int -> int -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val maxMany_int : int array -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val max_float : float -> float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val maxMany_float : float array -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val min_int : int -> int -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val minMany_int : int array -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val min_float : float -> float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val minMany_float : float array -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val pow_float : base:float -> exp:float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val random : unit -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val random_int : int -> int -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafe_round : float -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val round : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sign_int : int -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sign_float : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sin : float -> float

  val sinh : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val sqrt : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val tan : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val tanh : float -> float
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val unsafe_trunc : float -> int
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val trunc : float -> float
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
  type t = float

  val _NaN : float
  val isNaN : float -> bool
  val isFinite : float -> bool

  val toExponential : ?digits:int -> t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toFixed : ?digits:int -> t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toPrecision : ?digits:int -> t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toString : ?radix:int -> t -> string
  val fromString : string -> float
end

module Int : sig
  type t = int

  val toExponential : ?digits:int -> t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toPrecision : ?digits:t -> t -> string
  [@@alert
    not_implemented "is not implemented in native under server-reason-react.js"]

  val toString : ?radix:t -> t -> string
  val toFloat : int -> float
  val equal : t -> t -> bool
  val max : int
  val min : int
end

module Bigint : sig end

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
