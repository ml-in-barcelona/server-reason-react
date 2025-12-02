(** JavaScript String API *)

type t = string

val make : 'a -> t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val fromCharCode : int -> t

val fromCharCodeMany : int array -> t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val fromCodePoint : int -> t

val fromCodePointMany : int array -> t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val length : t -> int
val get : t -> int -> t
val charAt : index:int -> t -> t
val charCodeAt : index:int -> t -> float
val codePointAt : index:int -> t -> int Js_internal.nullable
val concat : other:t -> t -> t
val concatMany : strings:t array -> t -> t
val endsWith : suffix:t -> ?len:int -> t -> bool
val includes : search:t -> ?start:int -> t -> bool
val indexOf : search:t -> ?start:int -> t -> int
val lastIndexOf : search:t -> ?start:int -> t -> int

val localeCompare : other:t -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val match_ : regexp:Js_re.t -> t -> t Js_internal.nullable array Js_internal.nullable

val normalize : ?form:[ `NFC | `NFD | `NFKC | `NFKD ] -> t -> t
(** Returns the Unicode Normalization Form of a string. *)

val repeat : count:int -> t -> t
val replace : search:t -> replacement:t -> t -> t
val replaceByRe : regexp:Js_re.t -> replacement:t -> t -> t

val unsafeReplaceBy0 : regexp:Js_re.t -> f:(t -> int -> t -> t) -> t -> t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val unsafeReplaceBy1 : regexp:Js_re.t -> f:(t -> t -> int -> t -> t) -> t -> t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val unsafeReplaceBy2 : regexp:Js_re.t -> f:(t -> t -> t -> int -> t -> t) -> t -> t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val unsafeReplaceBy3 : regexp:Js_re.t -> f:(t -> t -> t -> t -> int -> t -> t) -> t -> t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val search : regexp:Js_re.t -> t -> int
(** Searches for a match in a string. Returns the index of the first match, or -1 if not found. *)

val slice : ?start:int -> ?end_:int -> t -> t
val split : ?sep:t -> ?limit:int -> t -> t array
val splitByRe : regexp:Js_re.t -> ?limit:int -> t -> t Js_internal.nullable array
val startsWith : prefix:t -> ?start:int -> t -> bool
val substr : ?start:int -> ?len:int -> t -> t
val substring : ?start:int -> ?end_:int -> t -> t
val toLowerCase : t -> t
val toLocaleLowerCase : t -> t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val toUpperCase : t -> t
val toLocaleUpperCase : t -> t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val trim : t -> t
val anchor : name:t -> t -> t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val link : href:t -> t -> t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
