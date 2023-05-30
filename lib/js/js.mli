type 'a t = 'a constraint 'a = < .. >

(* module Fn : sig
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
   end *)

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

val typeof : 'a -> string

module Null : sig
  type +'a t = 'a null
  (** Local alias for ['a Js.null] *)

  val return : 'a -> 'a t
  (** Constructs a value of ['a Js.null] containing a value of ['a] *)

  val test : 'a t -> bool
    [@@deprecated "Use = Js.null directly"]
  (** Returns [true] if the given value is [empty] ([null]), [false] otherwise *)

  val empty : 'a t
  (** The empty value, [null] *)

  val getUnsafe : 'a t -> 'a
  val getExn : 'a t -> 'a

  val bind : 'a t -> ('a -> 'b) -> 'b t
  (** Maps the contained value using the given function

If ['a Js.null] contains a value, that value is unwrapped, mapped to a ['b] using
the given function [a' -> 'b], then wrapped back up and returned as ['b Js.null]

@example {[
let maybeGreetWorld (maybeGreeting: string Js.null) =
  Js.Null.bind maybeGreeting (fun greeting -> greeting ^ " world!")
]}
*)

  val iter : 'a t -> ('a -> unit) -> unit
  (** Iterates over the contained value with the given function

If ['a Js.null] contains a value, that value is unwrapped and applied to
the given function.

@example {[
let maybeSay (maybeMessage: string Js.null) =
  Js.Null.iter maybeMessage (fun message -> Js.log message)
]}
*)

  val fromOption : 'a option -> 'a t
  (** Maps ['a option] to ['a Js.null]

{%html:
<table>
<tr> <td>Some a <td>-> <td>return a
<tr> <td>None <td>-> <td>empty
</table>
%}
*)

  val from_opt : 'a option -> 'a t [@@deprecated "Use fromOption instead"]

  external toOption : 'a t -> 'a option = "%identity"
  (** Maps ['a Js.null] to ['a option]

{%html:
<table>
<tr> <td>return a <td>-> <td>Some a
<tr> <td>empty <td>-> <td>None
</table>
%}
*)
end

module Undefined : sig
  type 'a t = 'a nullable
  (** Local alias for ['a Js.undefined] *)

  external return : 'a -> 'a t = "%identity"
  val empty : 'a nullable
  external toOption : 'a t -> 'a nullable = "%identity"
  external fromOpt : 'a nullable -> 'a t = "%identity"

  (** Constructs a value of ['a Js.undefined] containing a value of ['a] *)

  val test : 'a t -> bool
    [@@deprecated "Use = Js.undefined directly"]
  (** Returns [true] if the given value is [empty] ([undefined]), [false] otherwise *)

  val testAny : 'a -> bool
  (**
   @since 1.6.1
   Returns [true] if the given value is [empty] ([undefined])
*)

  (** The empty value, [undefined] *)

  val getUnsafe : 'a t -> 'a
  val getExn : 'a t -> 'a

  val bind : 'a t -> ('a -> 'b) -> 'b t
  (** Maps the contained value using the given function

If ['a Js.undefined] contains a value, that value is unwrapped, mapped to a ['b] using
the given function [a' -> 'b], then wrapped back up and returned as ['b Js.undefined]

@example {[
let maybeGreetWorld (maybeGreeting: string Js.undefined) =
  Js.Undefined.bind maybeGreeting (fun greeting -> greeting ^ " world!")
]}
*)

  val iter : 'a t -> ('a -> unit) -> unit
  (** Iterates over the contained value with the given function

If ['a Js.undefined] contains a value, that value is unwrapped and applied to
the given function.

@example {[
let maybeSay (maybeMessage: string Js.undefined) =
  Js.Undefined.iter maybeMessage (fun message -> Js.log message)
]}
*)

  val fromOption : 'a option -> 'a t
  (** Maps ['a option] to ['a Js.undefined]

{%html:
<table>
<tr> <td>Some a <td>-> <td>return a
<tr> <td>None <td>-> <td>empty
</table>
%}
*)

  val from_opt : 'a option -> 'a t [@@deprecated "Use fromOption instead"]

  (** Maps ['a Js.undefined] to ['a option]

{%html:
<table>
<tr> <td>return a <td>-> <td>Some a
<tr> <td>empty <td>-> <td>None
</table>
%}
*)
end

module Nullable : sig
  (** Contains functionality for dealing with values that can be both [null] and [undefined] *)

  type +'a t = 'a nullable
  (** Local alias for ['a Js.null_undefined] *)

  external toOption : 'a t -> 'a nullable = "%identity"
  external to_opt : 'a t -> 'a nullable = "%identity"
  val return : 'a -> 'a t

  val isNullable : 'a t -> bool
  (** Constructs a value of ['a Js.null_undefined] containing a value of ['a] *)

  val null : 'a t
  (** Returns [true] if the given value is [null] or [undefined], [false] otherwise *)

  val undefined : 'a t
  (** The [null] value of type ['a Js.null_undefined]*)

  val bind : 'a t -> ('a -> 'b) -> 'b t
  (** The [undefined] value of type ['a Js.null_undefined] *)

  val iter : 'a t -> ('a -> unit) -> unit
  val fromOption : 'a nullable -> 'a t
  val from_opt : 'a nullable -> 'a t
end

module Null_undefined = Nullable

module Exn : sig
  type t
  type exn += private Error of t

  val asJsExn : exn -> t option
  val stack : t -> string option
  val message : t -> string option
  val name : t -> string option
  val fileName : t -> string option

  val isCamlExceptionOrOpenVariant : 'a -> bool
  (** internal use only *)

  val anyToExnInternal : 'a -> exn
  (**
  * [anyToExnInternal obj] will take any value [obj] and wrap it
  * in a Js.Exn.Error if given value is not an exn already. If
  * [obj] is an exn, it will return [obj] without any changes.
  *
  * This function is mostly useful for cases where you want to unify a type of a value
  * that potentially is either exn, a JS error, or any other JS value really (e.g. for
  * a value passed to a Promise.catch callback)
  *
  * IMPORTANT: This is an internal API and may be changed / removed any time in the future.
  *
  * @example {[
  *   switch (Js.Exn.unsafeAnyToExn("test")) {
  *     | Js.Exn.Error(v) =>
  *       switch(Js.Exn.message(v)) {
  *         | Some(str) => Js.log("We won't end up here")
            | None => Js.log2("We will land here: ", v)
  *       }
  *   }
  * ]}
  * **)

  external makeError : string -> t = "%identity"

  (* Raise Js exception Error object with stacktrace *)

  val raiseError : string -> 'a
  val raiseEvalError : string -> 'a
  val raiseRangeError : string -> 'a
  val raiseReferenceError : string -> 'a
  val raiseSyntaxError : string -> 'a
  val raiseTypeError : string -> 'a
  val raiseUriError : string -> 'a
end

module Array2_ : sig
  type 'a t = 'a array
  type 'a array_like

  val from : 'a -> 'b -> 'c
  val fromMap : 'a -> 'b -> 'c
  val isArray : 'a -> 'b -> 'c
  val length : 'a -> 'b -> 'c
  val copyWithin : 'a -> 'b -> 'c
  val copyWithinFrom : 'a -> 'b -> 'c
  val copyWithinFromRange : 'a -> 'b -> 'c
  val fillInPlace : 'a -> 'b -> 'c
  val fillFromInPlace : 'a -> 'b -> 'c
  val fillRangeInPlace : 'a -> 'b -> 'c
  val pop : 'a -> 'b -> 'c
  val push : 'a -> 'b -> 'c
  val pushMany : 'a -> 'b -> 'c
  val reverseInPlace : 'a -> 'b -> 'c
  val shift : 'a -> 'b -> 'c
  val sortInPlace : 'a -> 'b -> 'c
  val sortInPlaceWith : 'a -> 'b -> 'c
  val spliceInPlace : 'a -> 'b -> 'c
  val removeFromInPlace : 'a -> 'b -> 'c
  val removeCountInPlace : 'a -> 'b -> 'c
  val unshift : 'a -> 'b -> 'c
  val unshiftMany : 'a -> 'b -> 'c
  val append : 'a -> 'b -> 'c
  val concat : 'a -> 'b -> 'c
  val concatMany : 'a -> 'b -> 'c
  val includes : 'a -> 'b -> 'c
  val indexOf : 'a -> 'b -> 'c
  val indexOfFrom : 'a -> 'b -> 'c
  val joinWith : 'a -> 'b -> 'c
  val lastIndexOf : 'a -> 'b -> 'c
  val lastIndexOfFrom : 'a -> 'b -> 'c
  val slice : 'a -> 'b -> 'c
  val copy : 'a -> 'b -> 'c
  val sliceFrom : 'a -> 'b -> 'c
  val toString : 'a -> 'b -> 'c
  val toLocaleString : 'a -> 'b -> 'c
  val every : 'a -> 'b -> 'c
  val everyi : 'a -> 'b -> 'c
  val filter : 'a -> 'b -> 'c
  val filteri : 'a -> 'b -> 'c
  val find : 'a array -> ('a -> bool) -> 'a nullable
  val findi : 'a -> 'b -> 'c
  val findIndex : 'a -> 'b -> 'c
  val findIndexi : 'a -> 'b -> 'c
  val forEach : 'a array -> ('a -> unit) -> unit
  val forEachi : 'a array -> (int -> 'a -> unit) -> unit
  val map : 'a array -> ('a -> 'b) -> 'b array
  val mapi : 'a array -> (int -> 'a -> 'b) -> 'b array
  val reduce : 'a array -> ('b -> 'a -> 'b) -> 'b -> 'b
  val reducei : 'a array -> ('b -> 'a -> int -> 'b) -> 'b -> 'b
  val reduceRight : 'a -> 'b -> 'c
  val reduceRighti : 'a -> 'b -> 'c
  val some : 'a -> 'b -> 'c
  val somei : 'a -> 'b -> 'c
  val unsafe_get : 'a -> 'b -> 'c
  val unsafe_set : 'a -> 'b -> 'c
end

module Array : sig
  type 'a t = 'a array
  type 'a array_like = 'a Array2_.array_like

  val from : 'a -> 'b -> 'c
  val fromMap : 'a -> 'b -> 'c
  val isArray : 'a -> 'b -> 'c
  val length : 'a -> 'b
  val copyWithin : 'a -> 'b -> 'c
  val copyWithinFrom : 'a -> 'b -> 'c
  val copyWithinFromRange : 'a -> 'b -> 'c
  val fillInPlace : 'a -> 'b -> 'c
  val fillFromInPlace : 'a -> 'b -> 'c
  val fillRangeInPlace : 'a -> 'b -> 'c
  val pop : 'a -> 'b -> 'c
  val push : 'a -> 'b -> 'c
  val pushMany : 'a -> 'b -> 'c
  val reverseInPlace : 'a -> 'b -> 'c
  val sortInPlace : 'a -> 'b -> 'c
  val sortInPlaceWith : 'a -> 'b -> 'c
  val spliceInPlace : 'a -> 'b -> 'c
  val removeFromInPlace : 'a -> 'b -> 'c
  val removeCountInPlace : 'a -> 'b -> 'c
  val unshift : 'a -> 'b -> 'c
  val unshiftMany : 'a -> 'b -> 'c
  val append : 'a -> 'b -> 'c
  val concat : 'a -> 'b -> 'c
  val concatMany : 'a -> 'b -> 'c
  val includes : 'a -> 'b -> 'c
  val indexOf : 'a -> 'b -> 'c
  val indexOfFrom : 'a -> from:'b -> 'c -> 'd
  val join : 'a -> 'b -> 'c
  val joinWith : 'a -> 'b -> 'c
  val lastIndexOf : 'a -> 'b -> 'c
  val lastIndexOfFrom : 'a -> 'b -> 'c
  val lastIndexOf_start : 'a -> 'b -> 'c
  val slice : 'a -> 'b -> 'c
  val copy : 'a -> 'b -> 'c
  val slice_copy : 'a -> 'b -> 'c
  val sliceFrom : 'a -> 'b -> 'c
  val slice_start : 'a -> 'b -> 'c
  val toString : 'a -> 'b -> 'c
  val toLocaleString : 'a -> 'b -> 'c
  val every : 'a -> 'b -> 'c
  val everyi : 'a -> 'b -> 'c
  val filter : 'a -> 'b -> 'c
  val filteri : 'a -> 'b -> 'c
  val find : 'a -> 'b -> 'c
  val findi : 'a -> 'b -> 'c
  val findIndex : 'a -> 'b -> 'c
  val findIndexi : 'a -> 'b -> 'c
  val forEach : 'a -> 'b -> 'c
  val forEachi : 'a -> 'b -> 'c
  val map : 'a -> 'b -> 'c
  val mapi : 'a -> 'b -> 'c
  val reduce : 'a -> 'b -> 'c
  val reducei : 'a -> 'b -> 'c
  val reduceRight : 'a -> 'b -> 'c
  val reduceRighti : 'a -> 'b -> 'c
  val some : 'a -> 'b -> 'c
  val somei : 'a -> 'b -> 'c
  val unsafe_get : 'a -> 'b -> 'c
  val unsafe_set : 'a -> 'b -> 'c
end

module Re : sig
  type t
  (* The RegExp object *)

  type result
  (* The result of a executing a RegExp on a string. *)

  val captures : result -> string nullable array
  (** An array of the match and captures, the first is the full match and the remaining are the substring captures. *)

  val matches : result -> string array
  (** Deprecated. Use captures instead. An array of the matches, the first is the full match and the remaining are the substring matches. *)

  val index : result -> int
  (** 0-based index of the match in the input string. *)

  val input : result -> string
  (* The original input string. *)

  val fromString : string -> t
  (** Constructs a RegExp object (Js.Re.t) from a string. Regex literals %re("/.../") should generally be preferred, but fromString is useful when you need to dynamically construct a regex using strings, exactly like when you do so in JavaScript. *)

  (* let firstReScriptFileExtension = (filename, content) -> {
         let result = Js.Re.fromString(filename ++ "\.(res|resi)")->Js.Re.exec_(content)
         switch result {
         | Some(r) -> Js.Nullable.toOption(Js.Re.captures(r)[1])
         | None -> None
         }
       }
     firstReScriptFileExtension("School", "School.res School.resi Main.js School.bs.js")
  *)

  val fromStringWithFlags : string -> flags:string -> t
  (* Constructs a RegExp object (Js.Re.t) from a string with the given flags. See Js.Re.fromString.

     Valid flags:

     g global i ignore case m multiline u unicode (es2015) y sticky (es2015)
  *)

  val flags : t -> string
  (** Returns the enabled flags as a string. *)

  val global : t -> bool
  (** Returns a bool indicating whether the global flag is set. *)

  val ignoreCase : t -> bool
  (** Returns a bool indicating whether the ignoreCase flag is set. *)

  val lastIndex : t -> int
  (*+ Returns the index where the next match will start its search. This property will be modified when the RegExp object is used, if the global ("g") flag is set. *)

  (* let re = %re("/ab*/g")
     let str = "abbcdefabh"

     let break = ref(false)
     while !break.contents {
       switch Js.Re.exec_(re, str) {
       | Some(result) -> Js.Nullable.iter(Js.Re.captures(result)[0], (. match_) -> {
           let next = Belt.Int.toString(Js.Re.lastIndex(re))
           Js.log("Found " ++ (match_ ++ (". Next match starts at " ++ next)))
         })
       | None -> break := true
       }
     } *)

  val setLastIndex : t -> int -> unit
  (** Sets the index at which the next match will start its search from. *)

  val multiline : t -> bool
  (** Returns a bool indicating whether the multiline flag is set. *)

  val source : t -> string
  (** Returns the pattern as a string. *)

  val sticky : t -> bool
  (** Returns a bool indicating whether the sticky flag is set. *)

  val unicode : t -> bool
  (** Returns a bool indicating whether the unicode flag is set. *)

  val exec_ : t -> string -> result option
  (** Executes a search on a given string using the given RegExp object. Returns Some(Js.Re.result) if a match is found, None otherwise. *)

  (* let re = %re("/quick\s(brown).+?(jumps)/ig")
     let result = Js.Re.exec_(re, "The Quick Brown Fox Jumps Over The Lazy Dog") *)

  val exec : string -> t -> result option
  (** Deprecated. please use Js.Re.exec_ instead. *)

  val test_ : t -> string -> bool
  (** Tests whether the given RegExp object will match a given string. Returns true if a match is found, false otherwise. *)

  (* A simple implementation of Js.String.startsWith

     let str = "hello world!"

     let startsWith = (target, substring) -> Js.Re.fromString("^" ++ substring)->Js.Re.test_(target)

     Js.log(str->startsWith("hello")) /* prints "true" */ *)

  val test : string -> t -> bool
  (** Deprecated. please use Js.Re.test_ instead. *)
end

module String : sig
  type t = string

  val make : 'a -> 'b -> 'c
  val fromCharCode : 'a -> 'b -> 'c
  val fromCharCodeMany : 'a -> 'b -> 'c
  val fromCodePoint : 'a -> 'b -> 'c
  val fromCodePointMany : 'a -> 'b -> 'c
  val length : 'a -> 'b -> 'c
  val get : 'a -> 'b -> 'c
  val charAt : 'a -> 'b -> 'c
  val charCodeAt : 'a -> 'b -> 'c
  val codePointAt : 'a -> 'b -> 'c
  val concat : 'a -> 'b -> 'c
  val concatMany : 'a -> 'b -> 'c
  val endsWith : 'a -> 'b -> 'c
  val endsWithFrom : 'a -> 'b -> 'c
  val includes : 'a -> 'b -> 'c
  val includesFrom : 'a -> 'b -> 'c
  val indexOf : 'a -> 'b -> 'c
  val indexOfFrom : 'a -> 'b -> 'c
  val lastIndexOf : 'a -> 'b -> 'c
  val lastIndexOfFrom : 'a -> 'b -> 'c
  val localeCompare : 'a -> 'b -> 'c
  val match_ : 'a -> 'b -> 'c
  val normalize : 'a -> 'b -> 'c
  val normalizeByForm : 'a -> 'b -> 'c
  val repeat : 'a -> 'b -> 'c
  val replace : 'a -> 'b -> 'c
  val replaceByRe : 'a -> 'b -> 'c
  val unsafeReplaceBy0 : 'a -> 'b -> bool
  val unsafeReplaceBy1 : 'a -> 'b -> 'c
  val unsafeReplaceBy2 : 'a -> 'b -> 'c
  val unsafeReplaceBy3 : 'a -> 'b -> 'c
  val search : 'a -> 'b -> 'c
  val slice : 'a -> 'b -> 'c
  val sliceToEnd : 'a -> 'b -> 'c
  val split : 'a -> 'b -> 'c
  val splitAtMost : 'a -> 'b -> 'c
  val splitLimited : 'a -> 'b -> 'c
  val splitByRe : 'a -> 'b -> 'c
  val splitByReAtMost : 'a -> 'b -> 'c
  val splitRegexpLimited : 'a -> 'b -> 'c
  val startsWith : 'a -> 'b -> 'c
  val startsWithFrom : 'a -> 'b -> 'c
  val substr : 'a -> 'b -> 'c
  val substrAtMost : 'a -> 'b -> 'c
  val substring : 'a -> 'b -> 'c
  val substringToEnd : 'a -> 'b -> 'c
  val toLowerCase : 'a -> 'b -> 'c
  val toLocaleLowerCase : 'a -> 'b -> 'c
  val toUpperCase : 'a -> 'b -> 'c
  val toLocaleUpperCase : 'a -> 'b -> 'c
  val trim : 'a -> 'b -> 'c
  val anchor : 'a -> 'b -> 'c
  val link : 'a -> 'b -> 'c
  val castToArrayLike : 'a -> 'b -> 'c
end

module String2 : sig
  type t = string

  val make : int -> char -> string
  val fromCharCode : int -> string
  val fromCharCodeMany : 'a -> 'b -> 'c
  val fromCodePoint : int -> string
  val fromCodePointMany : 'a -> 'b
  val length : string -> int
  val get : string -> int -> string
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
  val match_ : 'a -> 'b -> 'c
  val normalize : 'a -> 'b -> 'c
  val normalizeByForm : 'a -> 'b -> 'c
  val repeat : string -> int -> string
  val replace : 'a -> 'b -> 'c -> 'd
  val replaceByRe : 'a -> 'b -> 'c -> 'd
  val unsafeReplaceBy0 : 'a -> 'b -> 'c
  val unsafeReplaceBy1 : 'a -> 'b -> 'c
  val unsafeReplaceBy2 : 'a -> 'b -> 'c
  val unsafeReplaceBy3 : 'a -> 'b -> 'c
  val search : 'a -> 'b -> 'c
  val slice : string -> from:int -> to_:int -> string
  val sliceToEnd : string -> from:int -> string
  val split : 'a -> 'b -> 'c
  val splitAtMost : 'a -> 'b -> limit:'c -> 'd
  val splitByRe : 'a -> 'b -> 'c
  val splitByReAtMost : 'a -> 'b -> 'c
  val startsWith : string -> string -> bool
  val startsWithFrom : 'a -> 'b -> 'c -> 'd
  val substr : string -> from:int -> string
  val substrAtMost : string -> from:int -> length:int -> string
  val substring : string -> from:int -> to_:int -> string
  val substringToEnd : string -> from:int -> string
  val toLowerCase : string -> string
  val toLocaleLowerCase : 'a -> 'b -> 'c
  val toUpperCase : string -> string
  val toLocaleUpperCase : 'a -> 'b -> 'c
  val trim : string -> string
  val anchor : 'a -> 'b -> 'c
  val link : 'a -> 'b -> 'c
  val castToArrayLike : 'a -> 'b -> 'c
end

module Promise : sig end
module Date : sig end

module Dict : sig
  type 'a t
  (** Dictionary type (ie an '\{ \}' JS object). However it is restricted
      to hold a single type; therefore values must have the same type.

      This Dictionary type is mostly used with the [Js_json.t] type. *)

  type key = string
  (** Key type *)

  val get : 'a t -> key -> 'a option
  (** [get dict key] returns [None] if the [key] is not found in the
      dictionary, [Some value] otherwise *)

  (* external unsafeGet : 'a t -> key -> 'a = "" [@@bs.get_index] *)
  val unsafeGet : 'a t -> key -> 'a
  (** [unsafeGet dict key] return the value if the [key] exists,
      otherwise an {b undefined} value is returned. Must be used only
      when the existence of a key is certain. (i.e. when having called [keys]
      function previously.

  @example {[
    Array.iter (fun key -> Js.log (Js_dict.unsafeGet dic key)) (Js_dict.keys dict)
  ]}
  *)

  (* external set : 'a t -> key -> 'a -> unit = "" [@@bs.set_index] *)
  val set : 'a t -> key -> 'a -> unit
  (** [set dict key value] sets the [key]/[value] in [dict] *)

  (* external keys : 'a t -> string array = "Object.keys" [@@bs.val] *)
  val keys : 'a t -> string array
  (** [keys dict] returns all the keys in the dictionary [dict]*)

  val empty : unit -> 'a t
  (** [empty ()] returns an empty dictionary *)
  (* external empty : unit -> 'a t = "" [@@bs.obj] *)

  val unsafeDeleteKey : string t -> string -> unit
  (** Experimental internal function *)

  (* external entries : 'a t -> (key * 'a) array = "Object.entries" [@@bs.val] *)
  val entries : 'a t -> (key * 'a) array
  (** [entries dict] returns the key value pairs in [dict] (ES2017) *)

  (* external values : 'a t -> 'a array = "Object.values" [@@bs.val] *)
  val values : 'a t -> 'a array
  (** [values dict] returns the values in [dict] (ES2017) *)

  val fromList : (key * 'a) list -> 'a t
  (** [fromList entries] creates a new dictionary containing each
  [(key, value)] pair in [entries] *)

  val fromArray : (key * 'a) array -> 'a t
  (** [fromArray entries] creates a new dictionary containing each
  [(key, value)] pair in [entries] *)

  val map : ('a -> 'b) -> 'a t -> 'b t
  (** [map f dict] maps [dict] to a new dictionary with the same keys,
  using [f] to map each value *)
end

module Global : sig end
module Json : sig end
module Math : sig end
module Obj : sig end
module Typed_array : sig end
module TypedArray2 : sig end

module Types : sig
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

  val test : 'a -> 'b t -> bool
  (** @example{[
    test "x" String = true
    ]}*)

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

  val classify : 'a -> tagged_t
end

module Float : sig end
module Int : sig end
module Bigint : sig end

module Option : sig
  type 'a t = 'a option

  val some : 'a -> 'a option
  val isSome : 'a option -> bool
  val isSomeValue : ('a -> 'a -> bool) -> 'a -> 'a option -> bool
  val isNone : 'a option -> bool
  val getExn : 'a option -> 'a
  val equal : ('a -> 'b -> bool) -> 'a option -> 'b option -> bool
  val andThen : ('a -> 'b option) -> 'a option -> 'b option
  val map : ('a -> 'b) -> 'a option -> 'b option
  val getWithDefault : 'a -> 'a option -> 'a

  val default : 'a -> 'a option -> 'a
    [@@deprecated
      "Use getWithDefault instead since default has special meaning in ES \
       module"]

  val filter : ('a -> bool) -> 'a option -> 'a option
  val firstSome : 'a option -> 'a option -> 'a option
end

module Result : sig
  type (+'good, +'bad) t = Ok of 'good | Error of 'bad
  [@@deprecated "Please use `Belt.Result.t` instead"]
end

module List : sig
  [@@@deprecated "Use Belt.List instead"]

  type 'a t = 'a list

  val length : 'a t -> int
  val cons : 'a -> 'a t -> 'a t
  val isEmpty : 'a t -> bool
  val hd : 'a t -> 'a option
  val tl : 'a t -> 'a t option
  val nth : 'a t -> int -> 'a option
  val revAppend : 'a t -> 'a t -> 'a t
  val rev : 'a t -> 'a t
  val mapRev : ('a -> 'b) -> 'a t -> 'b t
  val map : ('a -> 'b) -> 'a t -> 'b t
  val iter : ('a -> unit) -> 'a t -> unit
  val iteri : (int -> 'a -> unit) -> 'a t -> unit

  val foldLeft : ('a -> 'b -> 'a) -> 'a -> 'b list -> 'a
  (** Application order is left to right, tail recurisve *)

  val foldRight : ('a -> 'b -> 'b) -> 'a list -> 'b -> 'b
  (** Application order is right to left
      tail-recursive. *)

  val flatten : 'a t t -> 'a t
  val filter : ('a -> bool) -> 'a t -> 'a t
  val filterMap : ('a -> 'b option) -> 'a t -> 'b t
  val countBy : ('a -> bool) -> 'a list -> int
  val init : int -> (int -> 'a) -> 'a t
  val toVector : 'a t -> 'a array
  val equal : ('a -> 'a -> bool) -> 'a list -> 'a list -> bool
end

module Vector : sig
  [@@@deprecated "Use Belt.Array instead"]

  type 'a t = 'a array

  val filterInPlace : ('a -> bool) -> 'a t -> unit
  val empty : 'a t -> unit
  val pushBack : 'a -> 'a t -> unit

  val copy : 'a t -> 'a t
  (** shallow copy *)

  val memByRef : 'a -> 'a t -> bool
  val iter : ('a -> unit) -> 'a t -> unit
  val iteri : (int -> 'a -> unit) -> 'a t -> unit

  (* [@@deprecated "Use Js.List.toVector instead"] *)
  (* val ofList : 'a list -> 'a t   *)
  (* removed, we choose that {!Js.List} depends on Vector to avoid cylic dependency
*)

  val toList : 'a t -> 'a list
  val map : ('a -> 'b) -> 'a t -> 'b t
  val mapi : (int -> 'a -> 'b) -> 'a t -> 'b t
  val foldLeft : ('a -> 'b -> 'a) -> 'a -> 'b t -> 'a
  val foldRight : ('b -> 'a -> 'a) -> 'b t -> 'a -> 'a

  external length : 'a t -> int = "%array_length"
  (** Return the length (number of elements) of the given array. *)

  external get : 'a t -> int -> 'a = "%array_safe_get"
  (** [Array.get a n] returns the element number [n] of array [a].
   The first element has number 0.
   The last element has number [Array.length a - 1].
   You can also write [a.(n)] instead of [Array.get a n].

   Raise [Invalid_argument "index out of bounds"]
   if [n] is outside the range 0 to [(Array.length a - 1)]. *)

  external set : 'a t -> int -> 'a -> unit = "%array_safe_set"
  (** [Array.set a n x] modifies array [a] in place, replacing
   element number [n] with [x].
   You can also write [a.(n) <- x] instead of [Array.set a n x].

   Raise [Invalid_argument "index out of bounds"]
   if [n] is outside the range 0 to [Array.length a - 1]. *)

  external make : int -> 'a -> 'a t = "caml_make_vect"
  (** [Array.make n x] returns a fresh array of length [n],
   initialized with [x].
   All the elements of this new array are initially
   physically equal to [x] (in the sense of the [==] predicate).
   Consequently, if [x] is mutable, it is shared among all elements
   of the array, and modifying [x] through one of the array entries
   will modify all other entries at the same time.

   Raise [Invalid_argument] if [n < 0] or [n > Sys.max_array_length].
   If the value of [x] is a floating-point number, then the maximum
   size is only [Sys.max_array_length / 2].*)

  val init : int -> (int -> 'a) -> 'a t
  (** @param n size
    @param fn callback
    @raise RangeError when [n] is negative  *)

  val append : 'a -> 'a t -> 'a t
  (** [append x a] returns a fresh array with x appended to a *)

  external unsafe_get : 'a t -> int -> 'a = "%array_unsafe_get"
  external unsafe_set : 'a t -> int -> 'a -> unit = "%array_unsafe_set"
end

module Console : sig
  val log : 'a -> unit
  val log2 : 'a -> 'b -> unit
  val log3 : 'a -> 'b -> 'c -> unit
  val log4 : 'a -> 'b -> 'c -> 'd -> unit
  val logMany : 'a array -> unit
  val info : 'a -> unit
  val info2 : 'a -> 'b -> unit
  val info3 : 'a -> 'b -> 'c -> unit
  val info4 : 'a -> 'b -> 'c -> 'd -> unit
  val infoMany : 'a array -> unit
  val error : 'a -> unit
  val error2 : 'a -> 'b -> unit
  val error3 : 'a -> 'b -> 'c -> unit
  val error4 : 'a -> 'b -> 'c -> 'd -> unit
  val errorMany : 'a array -> unit
  val warn : 'a -> unit
  val warn2 : 'a -> 'b -> unit
  val warn3 : 'a -> 'b -> 'c -> unit
  val warn4 : 'a -> 'b -> 'c -> 'd -> unit
  val warnMany : 'a array -> unit
  val trace : unit -> unit
  val timeStart : 'a -> unit
  val timeEnd : 'a -> unit
end

val log : 'a -> unit
val log2 : 'a -> 'b -> unit
val log3 : 'a -> 'b -> 'c -> unit
val log4 : 'a -> 'b -> 'c -> 'd -> unit
val logMany : 'a array -> unit

module Set : sig end
module WeakSet : sig end
module Map : sig end
module WeakMap : sig end
