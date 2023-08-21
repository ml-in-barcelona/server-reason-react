exception Not_implemented of string

let notImplemented module_ function_ =
  raise
    (Not_implemented
       (Printf.sprintf
          "'%s.%s' is not implemented in native under server-reason-react.js"
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

  (* Use opaque instead of [._n] to prevent some optimizations happening *)
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

module Array2 = struct
  type 'a t = 'a array
  (** JavaScript Array API *)

  type 'a array_like

  let from _ = notImplemented "Js.Array2" "from"
  let fromMap _ _ = notImplemented "Js.Array2" "fromMap"

  (* This doesn't behave the same as melange-js, since it's a runtime check
     so lists are represented as arrays in the runtime: isArray([1, 2]) == true *)
  let isArray (_arr : 'a array) = true
  let length arr = Stdlib.Array.length arr

  (* Mutator functions *)
  let copyWithin _ _ = notImplemented "Js.Array2" "copyWithin"
  let copyWithinFrom _ _ = notImplemented "Js.Array2" "copyWithinFrom"
  let copyWithinFromRange _ _ = notImplemented "Js.Array2" "copyWithinFromRange"
  let fillInPlace _ _ = notImplemented "Js.Array2" "fillInPlace"
  let fillFromInPlace _ _ = notImplemented "Js.Array2" "fillFromInPlace"
  let fillRangeInPlace _ _ = notImplemented "Js.Array2" "fillRangeInPlace"
  let pop _ _ = notImplemented "Js.Array2" "pop"
  let push _ _ = notImplemented "Js.Array2" "push"
  let pushMany _ _ = notImplemented "Js.Array2" "pushMany"
  let reverseInPlace _ _ = notImplemented "Js.Array2" "reverseInPlace"
  let sortInPlace _ _ = notImplemented "Js.Array2" "sortInPlace"
  let sortInPlaceWith _ _ = notImplemented "Js.Array2" "sortInPlaceWith"
  let spliceInPlace _ _ = notImplemented "Js.Array2" "spliceInPlace"
  let removeFromInPlace _ _ = notImplemented "Js.Array2" "removeFromInPlace"
  let removeCountInPlace _ _ = notImplemented "Js.Array2" "removeCountInPlace"
  let unshift _ _ = notImplemented "Js.Array2" "unshift"
  let unshiftMany _ _ = notImplemented "Js.Array2" "unshiftMany"

  (* Accessor functions *)
  let append arr item = Stdlib.Array.append arr (Stdlib.Array.of_list [ item ])
  let concat first second = Stdlib.Array.append first second
  let concatMany arr many = Stdlib.Array.append arr (Stdlib.Array.of_list many)
  let includes arr item = Stdlib.Array.exists (fun x -> x = item) arr

  let indexOf arr item =
    let rec aux idx =
      if idx >= Stdlib.Array.length arr then -1
      else if arr.(idx) = item then idx
      else aux (idx + 1)
    in
    aux 0

  let indexOfFrom arr item ~from =
    let rec aux idx =
      if idx >= Stdlib.Array.length arr then -1
      else if arr.(idx) = item then idx
      else aux (idx + 1)
    in
    if from < 0 || from >= Stdlib.Array.length arr then -1 else aux from

  let joinWith arr joiner = Stdlib.Array.to_list arr |> String.concat joiner
  let join arr = Stdlib.Array.to_list arr |> String.concat ","

  let lastIndexOf item arr =
    let rec aux idx =
      if idx < 0 then -1 else if arr.(idx) = item then idx else aux (idx - 1)
    in
    aux (Stdlib.Array.length arr - 1)

  let lastIndexOfFrom arr item ~from =
    let rec aux idx =
      if idx < 0 then -1 else if arr.(idx) = item then idx else aux (idx - 1)
    in
    if from < 0 || from >= Stdlib.Array.length arr then -1 else aux from

  let slice arr ~start ~end_ =
    let len = Stdlib.Array.length arr in
    let s = max 0 (if start < 0 then len + start else start) in
    let e = min len (if end_ < 0 then len + end_ else end_) in
    if s >= e then [||] else Stdlib.Array.sub arr s (e - s)

  let copy arr = Stdlib.Array.copy arr

  let sliceFrom arr start =
    let len = Stdlib.Array.length arr in
    let s = max 0 (if start < 0 then len + start else start) in
    if s >= len then [||] else Stdlib.Array.sub arr s (len - s)

  let toString _ = notImplemented "Js.Array2" "toString"
  let toLocaleString _ = notImplemented "Js.Array2" "toLocaleString"

  (* Iteration functions *)
  let entries (_ : 'a array) = notImplemented "Js.Array2" "entries"

  let everyi arr fn =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then true
      else if fn arr.(idx) idx then aux (idx + 1)
      else false
    in
    aux 0

  let every arr fn =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then true else if fn arr.(idx) then aux (idx + 1) else false
    in
    aux 0

  let filter arr fn =
    arr |> Stdlib.Array.to_list |> List.filter fn |> Stdlib.Array.of_list

  let filteri arr fn =
    arr |> Stdlib.Array.to_list |> List.filteri fn |> Stdlib.Array.of_list

  let findi arr fn =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then None
      else if fn arr.(idx) idx then Some arr.(idx)
      else aux (idx + 1)
    in
    aux 0

  let find arr fn =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then None
      else if fn arr.(idx) then Some arr.(idx)
      else aux (idx + 1)
    in
    aux 0

  let findIndexi arr fn =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then -1 else if fn arr.(idx) idx then idx else aux (idx + 1)
    in
    aux 0

  let findIndex arr fn =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then -1 else if fn arr.(idx) then idx else aux (idx + 1)
    in
    aux 0

  let forEach arr fn = Stdlib.Array.iter fn arr
  let forEachi arr fn = Stdlib.Array.iteri fn arr
  let map arr fn = Stdlib.Array.map fn arr
  let mapi arr fn = Stdlib.Array.mapi fn arr

  let reduce arr fn init =
    let r = ref init in
    for i = 0 to length arr - 1 do
      r := fn !r (Stdlib.Array.unsafe_get arr i)
    done;
    !r

  let reducei arr fn init =
    let r = ref init in
    for i = 0 to length arr - 1 do
      r := fn !r (Stdlib.Array.unsafe_get arr i) i
    done;
    !r

  let reduceRight arr fn init =
    let r = ref init in
    for i = length arr - 1 downto 0 do
      r := fn (Stdlib.Array.unsafe_get arr i) !r
    done;
    !r

  let reduceRighti arr fn init =
    let r = ref init in
    for i = length arr - 1 downto 0 do
      r := fn (Stdlib.Array.unsafe_get arr i) !r i
    done;
    !r

  let some arr fn =
    let n = Stdlib.Array.length arr in
    let rec loop i =
      if i = n then false
      else if fn (Stdlib.Array.unsafe_get arr i) then true
      else loop (succ i)
    in
    loop 0

  let somei arr fn =
    let n = Stdlib.Array.length arr in
    let rec loop i =
      if i = n then false
      else if fn (Stdlib.Array.unsafe_get arr i) i then true
      else loop (succ i)
    in
    loop 0

  let unsafe_get arr idx = Stdlib.Array.unsafe_get arr idx
  let unsafe_set arr idx item = Stdlib.Array.unsafe_set arr idx item
end

module Array = struct
  (** JavaScript Array API *)

  type 'a t = 'a array
  type 'a array_like = 'a Array2.array_like

  let from _ = notImplemented "Js.Array" "from"
  let fromMap _ _ = notImplemented "Js.Array" "fromMap"

  (* This doesn't behave the same as melange-js, since it's a runtime check
     so lists are represented as arrays in the runtime: isArray([1, 2]) == true *)
  let isArray (_arr : 'a array) = true
  let length = Array2.length

  (* Mutator functions *)
  let copyWithin _ _ = notImplemented "Js.Array" "copyWithin"
  let copyWithinFrom _ _ = notImplemented "Js.Array" "copyWithinFrom"
  let copyWithinFromRange _ _ = notImplemented "Js.Array" "copyWithinFromRange"
  let fillInPlace _ _ = notImplemented "Js.Array" "fillInPlace"
  let fillFromInPlace _ _ = notImplemented "Js.Array" "fillFromInPlace"
  let fillRangeInPlace _ _ = notImplemented "Js.Array" "fillRangeInPlace"
  let pop _ _ = notImplemented "Js.Array" "pop"
  let push _ _ = notImplemented "Js.Array" "push"
  let pushMany _ _ = notImplemented "Js.Array" "pushMany"
  let reverseInPlace _ _ = notImplemented "Js.Array" "reverseInPlace"
  let sortInPlace _ _ = notImplemented "Js.Array" "sortInPlace"
  let sortInPlaceWith _ _ = notImplemented "Js.Array" "sortInPlaceWith"
  let spliceInPlace _ _ = notImplemented "Js.Array" "spliceInPlace"
  let removeFromInPlace _ _ = notImplemented "Js.Array" "removeFromInPlace"
  let removeCountInPlace _ _ = notImplemented "Js.Array" "removeCountInPlace"
  let unshift _ _ = notImplemented "Js.Array" "unshift"
  let unshiftMany _ _ = notImplemented "Js.Array" "unshiftMany"

  (* Accessor functions *)
  let append item arr = Array2.append arr item
  let concat first second = Array2.concat first second
  let concatMany many arr = Array2.concatMany arr many
  let includes item arr = Array2.includes arr item
  let indexOf item arr = Array2.indexOf arr item
  let indexOfFrom arr ~from item = Array2.indexOfFrom arr item ~from
  let joinWith joiner arr = Array2.joinWith arr joiner
  let join arr = Array2.join arr
  let lastIndexOf arr item = Array2.lastIndexOf item arr
  let lastIndexOfFrom arr ~from item = Array2.lastIndexOfFrom arr item ~from

  let lastIndexOf_start (_item : 'a) (_arr : 'a array) =
    notImplemented "Js.Array" "lastIndexOf_start"

  let slice ~start ~end_ arr = Array2.slice arr ~start ~end_
  let copy = Stdlib.Array.copy

  let slice_copy (_ : unit) (_ : 'a array) =
    notImplemented "Js.Array" "slice_copy"

  let sliceFrom start arr = Array2.sliceFrom arr start

  let slice_start (_ : int) (_ : 'a array) =
    notImplemented "Js.Array" "slice_start"

  let toString _ = notImplemented "Js.Array" "toString"
  let toLocaleString _ = notImplemented "Js.Array" "toLocaleString"

  (* Iteration functions *)
  let entries (_ : 'a array) = notImplemented "Js.Array" "entries"
  let everyi fn arr = Array2.everyi arr fn
  let every fn arr = Array2.every arr fn
  let filter fn arr = Array2.filter arr fn
  let filteri fn arr = Array2.filteri arr fn
  let findi fn arr = Array2.findi arr fn
  let find fn arr = Array2.find arr fn
  let findIndexi fn arr = Array2.findIndexi arr fn
  let findIndex fn arr = Array2.findIndex arr fn
  let forEach fn arr = Array2.forEach arr fn
  let forEachi fn arr = Array2.forEachi arr fn
  let map fn arr = Array2.map arr fn
  let mapi fn arr = Array2.mapi arr fn
  let reduce fn init arr = Array2.reduce arr fn init
  let reducei fn init arr = Array2.reducei arr fn init
  let reduceRight fn init arr = Array2.reduceRight arr fn init
  let reduceRighti fn init arr = Array2.reduceRighti arr fn init
  let some fn arr = Array2.some arr fn
  let somei fn arr = Array2.somei arr fn
  let unsafe_get arr idx = Stdlib.Array.unsafe_get arr idx
  let unsafe_set arr idx item = Stdlib.Array.unsafe_set arr idx item
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
    | 's' -> `DOTALL
    | other ->
        raise
          (Invalid_argument
             (Printf.sprintf "Invalid flag '%c'. Only g, i, m, u, y, s" other))

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

  let test : string -> t -> bool = fun str regex -> test_ regex str
end

module String2 = struct
  (** JavaScript String API *)

  type t = string

  (* TODO (davesnx): This changes the interface from String() *)
  let make i ch = Stdlib.String.make i ch

  let fromCharCode code =
    let uchar = Uchar.of_int code in
    let char_value = Uchar.to_char uchar in
    Stdlib.String.make 1 char_value

  let fromCharCodeMany _ _ = notImplemented "" "fromCharCodeMany"

  let fromCodePoint code_point =
    let ch = Char.chr code_point in
    Stdlib.String.make 1 ch

  let fromCodePointMany _ = notImplemented "Js.String2" "fromCodePointMany"
  let length = Stdlib.String.length

  let get str index =
    let ch = Stdlib.String.get str index in
    Stdlib.String.make 1 ch

  (** [set s n c] sets the character at the given index number to the given character. If [n] is out of range, this function does nothing. *)
  let set _ _ _ = notImplemented "Js.String2" "set"

  (* TODO (davesnx): If the string contains characters outside the range [\u0000-\uffff], it will return the first 16-bit value at that position in the string. *)
  let charAt str index =
    if index < 0 || index >= Stdlib.String.length str then ""
    else
      let ch = Stdlib.String.get str index in
      Stdlib.String.make 1 ch

  let charCodeAt s n =
    if n < 0 || n >= Stdlib.String.length s then nan
    else float_of_int (Stdlib.Char.code (Stdlib.String.get s n))

  let codePointAt str index =
    let str_length = Stdlib.String.length str in
    if index >= 0 && index < str_length then
      let uchar = Uchar.of_char (Stdlib.String.get str index) in
      Some (Uchar.to_int uchar)
    else None

  let concat str1 str2 = Stdlib.String.concat "" [ str1; str2 ]

  let concatMany original many =
    let many_list = Stdlib.Array.to_list many in
    Stdlib.String.concat "" (original :: many_list)

  let endsWith str suffix =
    let str_length = Stdlib.String.length str in
    let suffix_length = Stdlib.String.length suffix in
    if str_length < suffix_length then false
    else
      Stdlib.String.sub str (str_length - suffix_length) suffix_length = suffix

  let endsWithFrom str suffix from =
    let str_length = Stdlib.String.length str in
    let suffix_length = Stdlib.String.length suffix in
    let start_idx = Stdlib.max 0 (from - suffix_length) in
    if str_length - start_idx < suffix_length then false
    else Stdlib.String.sub str start_idx suffix_length = suffix

  let includes str sub =
    let str_length = Stdlib.String.length str in
    let sub_length = Stdlib.String.length sub in
    let rec includes_helper idx =
      if idx + sub_length > str_length then false
      else if Stdlib.String.sub str idx sub_length = sub then true
      else includes_helper (idx + 1)
    in
    includes_helper 0

  let includesFrom str sub from =
    let str_length = Stdlib.String.length str in
    let sub_length = Stdlib.String.length sub in
    let rec includes_helper idx =
      if idx + sub_length > str_length then false
      else if Stdlib.String.sub str idx sub_length = sub then true
      else includes_helper (idx + 1)
    in
    includes_helper from

  let indexOf str pattern =
    let str_length = Stdlib.String.length str in
    let pattern_length = Stdlib.String.length pattern in
    let rec index_helper idx =
      if idx + pattern_length > str_length then -1
      else if Stdlib.String.sub str idx pattern_length = pattern then idx
      else index_helper (idx + 1)
    in
    index_helper 0

  let indexOfFrom str pattern from =
    let str_length = Stdlib.String.length str in
    let pattern_length = Stdlib.String.length pattern in
    let rec index_helper idx =
      if idx + pattern_length > str_length then -1
      else if Stdlib.String.sub str idx pattern_length = pattern then idx
      else index_helper (idx + 1)
    in
    index_helper from

  let lastIndexOf str pattern =
    let str_length = Stdlib.String.length str in
    let pattern_length = Stdlib.String.length pattern in
    let rec last_index_helper idx =
      if idx < 0 || idx + pattern_length > str_length then -1
      else if Stdlib.String.sub str idx pattern_length = pattern then idx
      else last_index_helper (idx - 1)
    in
    last_index_helper (str_length - pattern_length)

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

  let localeCompare _ _ = notImplemented "Js.String2" "localeCompare"

  let match_ str regex =
    let match_next str regex =
      match Re.exec_ regex str with
      | None -> None
      | Some result -> Some (Re.matches result)
    in

    let rec match_all str regex =
      match Re.exec_ regex str with
      | None -> None
      | Some result ->
          Re.setLastIndex regex 0;
          let matches = Re.matches result in
          let matched_str = Stdlib.Array.get matches 0 in
          let suffix_start = Re.index result + String.length matched_str in
          let suffix =
            Stdlib.String.sub str suffix_start (String.length str - suffix_start)
          in
          let suffix_matches =
            match_all suffix regex |> Stdlib.Option.value ~default:[||]
          in
          Some (Stdlib.Array.append matches suffix_matches)
    in

    if Re.global regex then match_all str regex else match_next str regex

  let normalize _ _ = notImplemented "Js.String2" "normalize"
  let normalizeByForm _ _ = notImplemented "Js.String2" "normalizeByForm"

  (* TODO(davesnx): RangeError *)
  let repeat str count =
    let rec repeat' str acc remaining =
      if remaining <= 0 then acc else repeat' str (str ^ acc) (remaining - 1)
    in
    repeat' str "" count

  let replace _ _ _ = notImplemented "Js.String2" "replace"

  let replaceByRe str pattern replacement =
    let rec replace_all str =
      match Re.exec_ pattern str with
      | None -> str
      | Some result ->
          Re.setLastIndex pattern 0;
          let matches = Re.matches result in
          let matched_str = Stdlib.Array.get matches 0 in
          let prefix = Stdlib.String.sub str 0 (Re.index result) in
          let suffix_start = Re.index result + String.length matched_str in
          let suffix =
            Stdlib.String.sub str suffix_start (String.length str - suffix_start)
          in
          prefix ^ replacement ^ replace_all suffix
    in
    let replace_first str =
      match Re.exec_ pattern str with
      | None -> str
      | Some result ->
          let matches = Re.matches result in
          let matched_str = Stdlib.Array.get matches 0 in
          let prefix = Stdlib.String.sub str 0 (Re.index result) in
          let suffix_start = Re.index result + String.length matched_str in
          let suffix =
            Stdlib.String.sub str suffix_start (String.length str - suffix_start)
          in
          prefix ^ replacement ^ suffix
    in

    if Re.global pattern then replace_all str else replace_first str

  let unsafeReplaceBy0 _ _ = notImplemented "Js.String2" "unsafeReplaceBy0"
  let unsafeReplaceBy1 _ _ = notImplemented "Js.String2" "unsafeReplaceBy1"
  let unsafeReplaceBy2 _ _ = notImplemented "Js.String2" "unsafeReplaceBy2"
  let unsafeReplaceBy3 _ _ = notImplemented "Js.String2" "unsafeReplaceBy3"
  let search _ _ = notImplemented "Js.String2" "search"

  let slice str ~from ~to_ =
    let str_length = Stdlib.String.length str in
    let start_idx = Stdlib.max 0 (Stdlib.min from str_length) in
    let end_idx = Stdlib.max start_idx (Stdlib.min to_ str_length) in
    if start_idx >= end_idx then ""
    else Stdlib.String.sub str start_idx (end_idx - start_idx)

  let sliceToEnd str ~from =
    let str_length = Stdlib.String.length str in
    let start_idx = Stdlib.max 0 (Stdlib.min from str_length) in
    Stdlib.String.sub str start_idx (str_length - start_idx)

  let split _str _delimiter = notImplemented "Js.String2" "split"

  let splitAtMost _str _separator ~limit:_ =
    notImplemented "Js.String2" "mplemented"

  let splitByReAtMost _ _ = notImplemented "Js.String2" "splitByReAtMost"

  let splitByRe str pattern =
    let rev_array arr =
      arr |> Stdlib.Array.to_list |> Stdlib.List.rev |> Stdlib.Array.of_list
    in
    let rec split_all str acc =
      match Re.exec_ pattern str with
      | None -> Stdlib.Array.append [| Some str |] acc |> rev_array
      | Some result ->
          Re.setLastIndex pattern 0;
          let matches = Re.matches result in
          let matched_str = Stdlib.Array.get matches 0 in
          let prefix = String.sub str 0 (Re.index result) in
          let suffix_start = Re.index result + String.length matched_str in
          let suffix =
            String.sub str suffix_start (String.length str - suffix_start)
          in
          let suffix_matches = Stdlib.Array.append [| Some prefix |] acc in
          split_all suffix suffix_matches
    in

    let split_next str acc =
      match Re.exec_ pattern str with
      | None -> Stdlib.Array.append [| Some str |] acc |> rev_array
      | Some result ->
          Re.setLastIndex pattern 0;
          let matches = Re.matches result in
          let matched_str = Stdlib.Array.get matches 0 in
          let prefix = String.sub str 0 (Re.index result) in
          let suffix_start = Re.index result + String.length matched_str in
          let suffix =
            String.sub str suffix_start (String.length str - suffix_start)
          in
          Stdlib.Array.append [| Some prefix |] (split_all suffix acc)
    in

    if Re.global pattern then split_all str [||] else split_next str [||]

  let startsWith str prefix =
    Stdlib.String.length prefix <= Stdlib.String.length str
    && Stdlib.String.sub str 0 (Stdlib.String.length prefix) = prefix

  let startsWithFrom _str _index _ = notImplemented "Js.String2" "mplemented"

  let substr str ~from =
    let str_length = Stdlib.String.length str in
    let start_idx = Stdlib.max 0 (Stdlib.min from str_length) in
    if start_idx >= str_length then ""
    else Stdlib.String.sub str start_idx (str_length - start_idx)

  let substrAtMost str ~from ~length =
    let str_length = Stdlib.String.length str in
    let start_idx = max 0 (min from str_length) in
    let end_idx = min (start_idx + length) str_length in
    if start_idx >= end_idx then ""
    else Stdlib.String.sub str start_idx (end_idx - start_idx)

  let substring str ~from ~to_ =
    let length = Stdlib.String.length str in
    let start_idx = max 0 (min from length) in
    let end_idx = max 0 (min to_ length) in
    if start_idx >= end_idx then
      Stdlib.String.sub str end_idx (start_idx - end_idx)
    else Stdlib.String.sub str start_idx (end_idx - start_idx)

  let substringToEnd str ~from =
    let length = Stdlib.String.length str in
    if from >= length then ""
    else if from < 0 then str
    else Stdlib.String.sub str from (length - from)

  let toLowerCase str = Stdlib.String.lowercase_ascii str
  let toLocaleLowerCase _ _ = notImplemented "Js.String2" "toLocaleLowerCase"
  let toUpperCase str = Stdlib.String.uppercase_ascii str
  let toLocaleUpperCase _ _ = notImplemented "Js.String2" "toLocaleUpperCase"

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

  let anchor _ _ = notImplemented "Js.String2" "anchor"
  let link _ _ = notImplemented "Js.String2" "link"
  let castToArrayLike _ _ = notImplemented "Js.String2" "castToArrayLike"
end

module String = struct
  type t = string
  (** JavaScript String API *)

  (* TODO (davesnx): This changes the interface from String() *)
  let make i ch = Stdlib.String.make i ch
  let fromCharCode = String2.fromCharCode
  let fromCharCodeMany _ = notImplemented "Js.String" "fromCharCodeMany"
  let fromCodePoint = String2.fromCodePoint
  let fromCodePointMany _ = notImplemented "Js.String" "fromCodePointMany"
  let length = String2.length
  let get index str = String2.get str index
  let charAt index str = String2.charAt str index
  let charCodeAt index str = String2.charCodeAt str index
  let codePointAt index str = String2.codePointAt str index
  let concatMany many original = String2.concatMany original many
  let endsWith suffix str = String2.endsWith str suffix
  let endsWithFrom from suffix str = String2.endsWithFrom str from suffix
  let includes sub str = String2.includes str sub
  let includesFrom from sub str = String2.includesFrom str sub from
  let indexOf pattern str = String2.indexOf str pattern
  let indexOfFrom from pattern str = String2.indexOfFrom str pattern from
  let localeCompare _ _ = notImplemented "Js.String" "localeCompare"
  let match_ regex str = String2.match_ str regex
  let normalize _ _ = notImplemented "Js.String" "normalize"
  let normalizeByForm _ _ = notImplemented "Js.String" "normalizeByForm"
  let replace _ _ _ = notImplemented "Js.String" "replace"

  let replaceByRe regex replacer input =
    String2.replaceByRe input regex replacer

  let unsafeReplaceBy0 _ _ = notImplemented "Js.String" "unsafeReplaceBy0"
  let unsafeReplaceBy1 _ _ = notImplemented "Js.String" "unsafeReplaceBy1"
  let unsafeReplaceBy2 _ _ = notImplemented "Js.String" "unsafeReplaceBy2"
  let unsafeReplaceBy3 _ _ = notImplemented "Js.String" "unsafeReplaceBy3"
  let search _ _ = notImplemented "Js.String" "search"
  let slice ~from ~to_ str = String2.slice str ~from ~to_
  let sliceToEnd ~from str = String2.sliceToEnd str ~from
  let split _str _delimiter = notImplemented "Js.String" "split"

  let splitAtMost _separator ~limit:_ _str =
    notImplemented "Js.String" "mplemented"

  let splitByRe _ _ = notImplemented "Js.String" "splitByRe"
  let splitByReAtMost _ _ = notImplemented "Js.String" "splitByReAtMost"
  let startsWith prefix str = String2.startsWith str prefix
  let startsWithFrom _str _index _ = notImplemented "Js.String" "mplemented"
  let substr ~from str = String2.substr str ~from
  let substrAtMost ~from ~length str = String2.substrAtMost str ~from ~length
  let substring ~from ~to_ str = String2.substring str ~from ~to_
  let substringToEnd ~from str = String2.substringToEnd str ~from
  let toLowerCase = String2.toLowerCase
  let toLocaleLowerCase _ _ = notImplemented "Js.String" "toLocaleLowerCase"
  let toUpperCase = String2.toUpperCase
  let toLocaleUpperCase _ _ = notImplemented "Js.String" "toLocaleUpperCase"
  let trim = String2.trim
  let anchor _ _ = notImplemented "Js.String" "anchor"
  let link _ _ = notImplemented "Js.String" "link"
  let castToArrayLike _ _ = notImplemented "Js.String" "castToArrayLike"
end

module Promise = struct
  type +'a t = 'a Lwt.t
  type error = exn

  let make (fn : resolve:('a -> unit) -> reject:(exn -> unit) -> unit) :
      'a Lwt.t =
    let promise, resolver = Lwt.task () in
    let resolve value = Lwt.wakeup_later resolver value in
    let reject exn = Lwt.wakeup_later_exn resolver exn in
    fn ~resolve ~reject;
    promise

  let resolve = Lwt.return
  let reject = Lwt.fail

  let all (promises : 'a Lwt.t array) : 'a array Lwt.t =
    Lwt.map Stdlib.Array.of_list (Lwt.all (Stdlib.Array.to_list promises))

  let all2 (a, b) =
    let%lwt res_a = a in
    let%lwt res_b = b in
    Lwt.return (res_a, res_b)

  let all3 (a, b, c) =
    let%lwt res_a = a in
    let%lwt res_b = b in
    let%lwt res_c = c in
    Lwt.return (res_a, res_b, res_c)

  let all4 (a, b, c, d) =
    let%lwt res_a = a in
    let%lwt res_b = b in
    let%lwt res_c = c in
    let%lwt res_d = d in
    Lwt.return (res_a, res_b, res_c, res_d)

  let all5 (a, b, c, d, e) =
    let%lwt res_a = a in
    let%lwt res_b = b in
    let%lwt res_c = c in
    let%lwt res_d = d in
    let%lwt res_e = e in
    Lwt.return (res_a, res_b, res_c, res_d, res_e)

  let all6 (a, b, c, d, e, f) =
    let%lwt res_a = a in
    let%lwt res_b = b in
    let%lwt res_c = c in
    let%lwt res_d = d in
    let%lwt res_e = e in
    let%lwt res_f = f in
    Lwt.return (res_a, res_b, res_c, res_d, res_e, res_f)

  let race (promises : 'a Lwt.t array) : 'a Lwt.t =
    Lwt.pick (Stdlib.Array.to_list promises)

  let then_ p fn = Lwt.bind fn p

  let catch (handler : exn -> 'a Lwt.t) (promise : 'a Lwt.t) : 'a Lwt.t =
    Lwt.catch (fun () -> promise) handler
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
  val set : 'a t -> key -> 'a -> unit
  val get : 'a t -> key -> 'a option
  val unsafeGet : 'a t -> key -> 'a
  val map : ('a -> 'b) -> 'a t -> 'b t
  val unsafeDeleteKey : 'a t -> key -> unit
end

module Dict : Dictionary = struct
  (** Provide utilities for JS dictionary object *)

  type key = string
  type 'a t = (key, 'a) Hashtbl.t

  let empty () : 'a t = Hashtbl.create 10

  let entries (dict : 'a t) : (string * 'a) array =
    Hashtbl.fold (fun k v acc -> (k, v) :: acc) dict [] |> Stdlib.Array.of_list

  let get (dict : 'a t) (k : key) : 'a option =
    try Some (Hashtbl.find dict k) with Not_found -> None

  let map (f : 'a -> 'b) (dict : 'a t) =
    Hashtbl.fold
      (fun k v acc ->
        Hashtbl.add acc k (f v);
        acc)
      dict (empty ())

  let set (dict : 'a t) (k : key) (x : 'a) : unit = Hashtbl.replace dict k x

  let fromList (lst : (key * 'a) list) : 'a t =
    let length = Stdlib.List.length lst in
    let dict = Hashtbl.create length in
    Stdlib.List.iter (fun (k, v) -> Hashtbl.add dict k v) lst;
    dict

  let fromArray (arr : (key * 'a) array) : 'a t =
    let length = Stdlib.Array.length arr in
    let dict = Hashtbl.create length in
    Stdlib.Array.iter (fun (k, v) -> Hashtbl.add dict k v) arr;
    dict

  let keys (dict : 'a t) =
    Hashtbl.fold (fun k _ acc -> k :: acc) dict [] |> Stdlib.Array.of_list

  let values (dict : 'a t) =
    Hashtbl.fold (fun _k value acc -> value :: acc) dict []
    |> Stdlib.Array.of_list

  let unsafeGet (dict : 'a t) (k : key) : 'a = Hashtbl.find dict k
  let unsafeDeleteKey (dict : 'a t) (key : key) = Hashtbl.remove dict key
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
  let parseExn _ = notImplemented "Js.Json" "parseExn"
  let stringifyAny _ = notImplemented "Js.Json" "stringifyAny"
  let null _ = notImplemented "Js.Json" "null"
  let string _ = notImplemented "Js.Json" "string"
  let number _ = notImplemented "Js.Json" "number"
  let boolean _ = notImplemented "Js.Json" "boolean"
  let object_ _ = notImplemented "Js.Json" "object_"
  let array _ = notImplemented "Js.Json" "array"
  let stringArray _ = notImplemented "Js.Json" "stringArray"
  let numberArray _ = notImplemented "Js.Json" "numberArray"
  let booleanArray _ = notImplemented "Js.Json" "booleanArray"
  let objectArray _ = notImplemented "Js.Json" "objectArray"
  let stringify _ = notImplemented "Js.Json" "stringify"
  let stringifyWithSpace _ = notImplemented "Js.Json" "stringifyWithSpace"
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
  let acos _ = notImplemented "Js.Math" "acos"
  let acosh _ = notImplemented "Js.Math" "acosh"
  let asin _ = notImplemented "Js.Math" "asin"
  let asinh _ = notImplemented "Js.Math" "asinh"
  let atan _ = notImplemented "Js.Math" "atan"
  let atanh _ = notImplemented "Js.Math" "atanh"
  let atan2 ~y:_ ~x:_ = notImplemented "Js.Math" "atan2"
  let cbrt _ = notImplemented "Js.Math" "cbrt"
  let unsafe_ceil_int _ = notImplemented "Js.Math" "unsafe_ceil_int"
  let unsafe_ceil _ = notImplemented "Js.Math" "unsafe_ceil"
  let ceil_int _ _ = notImplemented "Js.Math" "ceil_int"
  let ceil _ = notImplemented "Js.Math" "ceil"
  let ceil_float _ = notImplemented "Js.Math" "ceil_float"
  let clz32 _ = notImplemented "Js.Math" "clz32"
  let cos _ = notImplemented "Js.Math" "cos"
  let cosh _ = notImplemented "Js.Math" "cosh"
  let exp _ = notImplemented "Js.Math" "exp"
  let expm1 _ = notImplemented "Js.Math" "expm1"
  let unsafe_floor_int _ = notImplemented "Js.Math" "unsafe_floor_int"
  let unsafe_floor _ = notImplemented "Js.Math" "unsafe_floor"
  let floor_int _f = notImplemented "Js.Math" "floor_int"
  let floor _ = notImplemented "Js.Math" "floor"
  let floor_float _ = notImplemented "Js.Math" "floor_float"
  let fround _ = notImplemented "Js.Math" "fround"
  let hypot _ = notImplemented "Js.Math" "hypot"
  let hypotMany _ _array = notImplemented "Js.Math" "hypotMany"
  let imul _ = notImplemented "Js.Math" "imul"
  let log _ = notImplemented "Js.Math" "log"
  let log1p _ = notImplemented "Js.Math" "log1p"
  let log10 _ = notImplemented "Js.Math" "log10"
  let log2 _ = notImplemented "Js.Math" "log2"
  let max_int _ = notImplemented "Js.Math" "max_int"
  let maxMany_int _ _array = notImplemented "Js.Math" "maxMany_int"
  let max_float _ = notImplemented "Js.Math" "max_float"
  let maxMany_float _ _array = notImplemented "Js.Math" "maxMany_float"
  let min_int _ = notImplemented "Js.Math" "min_int"
  let minMany_int _ _array = notImplemented "Js.Math" "minMany_int"
  let min_float _ = notImplemented "Js.Math" "min_float"
  let minMany_float _ _array = notImplemented "Js.Math" "minMany_float"
  let pow_int ~base:_ ~exp:_ = notImplemented "Js.Math" "pow_int"
  let pow_float ~base:_ ~exp:_ = notImplemented "Js.Math" "pow_float"
  let random _ = notImplemented "Js.Math" "random"
  let random_int _min _max = notImplemented "Js.Math" "random_int"
  let unsafe_round _ = notImplemented "Js.Math" "unsafe_round"
  let round _ = notImplemented "Js.Math" "round"
  let sign_int _ = notImplemented "Js.Math" "sign_int"
  let sign_float _ = notImplemented "Js.Math" "sign_float"
  let sin _ = notImplemented "Js.Math" "sin"
  let sinh _ = notImplemented "Js.Math" "sinh"
  let sqrt _ = notImplemented "Js.Math" "sqrt"
  let tan _ = notImplemented "Js.Math" "tan"
  let tanh _ = notImplemented "Js.Math" "tanh"
  let unsafe_trunc _ = notImplemented "Js.Math" "unsafe_trunc"
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
  let isNaN float = Stdlib.Float.is_nan float
  let isFinite float = Stdlib.Float.is_finite float
  let toExponential _ = notImplemented "Js.Float" "toExponential"

  let toExponentialWithPrecision _ ~digits:_ =
    notImplemented "Js.Float" "toExponentialWithPrecision"

  let toFixed _ = notImplemented "Js.Float" "toFixed"

  let toFixedWithPrecision _ ~digits:_ =
    notImplemented "Js.Float" "toFixedWithPrecision"

  let toPrecision _ = notImplemented "Js.Float" "toPrecision"

  let toPrecisionWithPrecision _ ~digits:_ =
    notImplemented "Js.Float" "toPrecisionWithPrecision"

  (* TODO: This isn't equivalent *)
  let toString = Stdlib.string_of_float

  let toStringWithRadix _ ~radix:_ =
    notImplemented "Js.Float" "toStringWithRadix"

  let fromString = Stdlib.float_of_string
end

module Int = struct
  (** Provides functions for inspecting and manipulating [int]s *)

  let toExponential _ = notImplemented "Js.Int" "toExponential"

  let toExponentialWithPrecision _ ~digits:_ =
    notImplemented "Js.Int" "toExponentialWithPrecision"

  let toPrecision _ = notImplemented "Js.Int" "toPrecision"

  let toPrecisionWithPrecision _ ~digits:_ =
    notImplemented "Js.Int" "toPrecisionWithPrecision"

  let toString int = Stdlib.string_of_int int
  let toStringWithRadix _ ~radix:_ = notImplemented "Js.Int" "toStringWithRadix"
  let toFloat int = Stdlib.float_of_int int
  let equal = Stdlib.String.equal
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
  let trace () = ()
  let timeStart _ = ()
  let timeEnd _ = ()
end

let log = Console.log
let log2 = Console.log2
let log3 = Console.log3
let log4 = Console.log4
let logMany = Console.logMany

module Set = struct
  (** Provides bindings for ES6 Set *)

  type 'a t
end

module WeakSet = struct
  (** Provides bindings for ES6 WeakSet *)

  type 'a t
end

module Map = struct
  (** Provides bindings for ES6 Map *)

  type ('k, 'v) t
end

module WeakMap = struct
  (** Provides bindings for ES6 WeakMap *)

  type ('k, 'v) t
end
