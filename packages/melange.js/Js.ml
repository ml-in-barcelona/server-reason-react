module CamomileCaseMape = Camomile.CaseMap.Make (Camomile.UTF8)

exception Not_implemented of string

let notImplemented module_ function_ =
  raise
    (Not_implemented
       (Printf.sprintf
          "'%s.%s' is not implemented in native on `server-reason-react.js`. \
           You are running code that depends on the browser, this is not \
           supported. If this case should run on native and there's no browser \
           dependency, please open an issue at %s"
          module_ function_
          "https://github.com/ml-in-barcelona/server-reason-react/issues"))

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
     See also {unsafe_lt} *)

(* external unsafe_gt : 'a -> 'a -> bool = "#unsafe_gt" *)
(**  [unsafe_gt a b] will be compiled as [a > b].
     See also {unsafe_lt} *)

(* external unsafe_ge : 'a -> 'a -> bool = "#unsafe_ge" *)
(**  [unsafe_ge a b] will be compiled as [a >= b].
     See also {unsafe_lt} *)

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
    match to_opt x with None -> ((x : 'a t) : 'b t) | Some x -> return (f x)

  let iter x f = match to_opt x with None -> () | Some x -> f x
  let fromOption x = match x with None -> undefined | Some x -> return x
  let from_opt = fromOption
end

module Null_undefined = Nullable

module Exn = struct
  type t

  type exn +=
    | Error of string
    | EvalError of string
    | RangeError of string
    | ReferenceError of string
    | SyntaxError of string
    | TypeError of string
    | UriError of string

  let asJsExn _ = notImplemented "Js.Exn" "asJsExn"
  let stack _ = notImplemented "Js.Exn" "stack"
  let message _ = notImplemented "Js.Exn" "message"
  let name _ = notImplemented "Js.Exn" "name"
  let fileName _ = notImplemented "Js.Exn" "fileName"
  let anyToExnInternal _ = notImplemented "Js.Exn" "anyToExnInternal"

  let isCamlExceptionOrOpenVariant _ =
    notImplemented "Js.Exn" "isCamlExceptionOrOpenVariant"

  let raiseError str = raise (Error str)
  let raiseEvalError str = raise (EvalError str)
  let raiseRangeError str = raise (RangeError str)
  let raiseReferenceError str = raise (ReferenceError str)
  let raiseSyntaxError str = raise (SyntaxError str)
  let raiseTypeError str = raise (TypeError str)
  let raiseUriError str = raise (UriError str)
end

module Array : sig
  (** JavaScript Array API *)

  type 'a t = 'a array
  type 'a array_like

  val from : 'a array_like -> 'a array
  val fromMap : 'a array_like -> f:('a -> 'b) -> 'b array
  val isArray : 'a -> bool
  val length : 'a array -> int
  val copyWithin : to_:int -> ?start:int -> ?end_:int -> 'a t -> 'a t
  val fill : value:'a -> ?start:int -> ?end_:int -> 'a t -> 'a t
  val pop : 'a t -> 'a option
  val push : value:'a -> 'a t -> int
  val pushMany : values:'a array -> 'a t -> int
  val reverseInPlace : 'a t -> 'a t
  val shift : 'a t -> 'a option
  val sortInPlace : 'a t -> 'a t
  val sortInPlaceWith : f:('a -> 'a -> int) -> 'a t -> 'a t
  val spliceInPlace : start:int -> remove:int -> add:'a array -> 'a t -> 'a t
  val removeFromInPlace : start:int -> 'a t -> 'a t
  val removeCountInPlace : start:int -> count:int -> 'a t -> 'a t
  val unshift : value:'a -> 'a t -> int
  val unshiftMany : values:'a array -> 'a t -> int
  val concat : other:'a t -> 'a t -> 'a t
  val concatMany : arrays:'a t array -> 'a t -> 'a t
  val includes : value:'a -> 'a t -> bool
  val join : ?sep:string -> string t -> string
  val indexOf : value:'a -> ?start:int -> 'a t -> int
  val lastIndexOf : value:'a -> 'a t -> int
  val lastIndexOfFrom : value:'a -> start:int -> 'a t -> int
  val copy : 'a t -> 'a t
  val slice : ?start:int -> ?end_:int -> 'a t -> 'a t
  val toString : 'a t -> string
  val toLocaleString : 'a t -> string
  val every : f:('a -> bool) -> 'a t -> bool
  val everyi : f:('a -> int -> bool) -> 'a t -> bool
  val filter : f:('a -> bool) -> 'a t -> 'a t
  val filteri : f:('a -> int -> bool) -> 'a t -> 'a t
  val find : f:('a -> bool) -> 'a t -> 'a option
  val findi : f:('a -> int -> bool) -> 'a t -> 'a option
  val findIndex : f:('a -> bool) -> 'a t -> int
  val findIndexi : f:('a -> int -> bool) -> 'a t -> int
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
end = struct
  type 'a t = 'a array
  type 'a array_like

  let from _ = notImplemented "Js.Array" "from"
  let fromMap _ ~f:_ = notImplemented "Js.Array" "fromMap"

  (* This doesn't behave the same as melange-js, since it's a runtime check
     so lists are represented as arrays in the runtime: isArray([1, 2]) == true *)
  let isArray (_arr : 'a) = true
  let length arr = Stdlib.Array.length arr

  (* Mutator functions *)
  let copyWithin ~to_:_ ?start:_ ?end_:_ _ =
    notImplemented "Js.Array" "copyWithin"

  let fill ~value:_ ?start:_ ?end_:_ _ = notImplemented "Js.Array" "fill"
  let pop _ = notImplemented "Js.Array" "pop"
  let push ~value:_ _ = notImplemented "Js.Array" "push"
  let pushMany ~values:_ _ = notImplemented "Js.Array" "pushMany"
  let reverseInPlace _ = notImplemented "Js.Array" "reverseInPlace"
  let sortInPlace _ = notImplemented "Js.Array" "sortInPlace"
  let sortInPlaceWith ~f:_ _ = notImplemented "Js.Array" "sortInPlaceWith"

  let spliceInPlace ~start:_ ~remove:_ ~add:_ _ =
    notImplemented "Js.Array" "spliceInPlace"

  let removeFromInPlace ~start:_ _ =
    notImplemented "Js.Array" "removeFromInPlace"

  let removeCountInPlace ~start:_ ~count:_ _ =
    notImplemented "Js.Array" "removeCountInPlace"

  let shift _ = notImplemented "Js.Array" "shift"
  let unshift ~value:_ _ = notImplemented "Js.Array" "unshift"
  let unshiftMany ~values:_ _ = notImplemented "Js.Array" "unshiftMany"

  (* Accessor functions *)
  let concat ~other:second first = Stdlib.Array.append first second

  let concatMany ~arrays arr =
    Stdlib.Array.concat (arr :: Stdlib.Array.to_list arrays)

  let includes ~value arr = Stdlib.Array.exists (fun x -> x = value) arr

  let indexOf ~value ?start arr =
    let rec aux idx =
      if idx >= Stdlib.Array.length arr then -1
      else if arr.(idx) = value then idx
      else aux (idx + 1)
    in
    match start with
    | None -> aux 0
    | Some from ->
        if from < 0 || from >= Stdlib.Array.length arr then -1 else aux from

  let join ?sep arr =
    (* js bindings can really take in `'a array`, while native is constrained to `string array` *)
    match sep with
    | None -> Stdlib.Array.to_list arr |> String.concat ","
    | Some sep -> Stdlib.Array.to_list arr |> String.concat sep

  let lastIndexOf ~value arr =
    let rec aux idx =
      if idx < 0 then -1 else if arr.(idx) = value then idx else aux (idx - 1)
    in
    aux (Stdlib.Array.length arr - 1)

  let lastIndexOfFrom ~value ~start arr =
    let rec aux idx =
      if idx < 0 then -1 else if arr.(idx) = value then idx else aux (idx - 1)
    in
    if start < 0 || start >= Stdlib.Array.length arr then -1 else aux start

  let slice ?start ?end_ arr =
    let len = Stdlib.Array.length arr in
    let start = match start with None -> 0 | Some s -> s in
    let end_ =
      match end_ with None -> Stdlib.Array.length arr | Some e -> e
    in
    let s = max 0 (if start < 0 then len + start else start) in
    let e = min len (if end_ < 0 then len + end_ else end_) in
    if s >= e then [||] else Stdlib.Array.sub arr s (e - s)

  let copy = Stdlib.Array.copy
  let toString _ = notImplemented "Js.Array" "toString"
  let toLocaleString _ = notImplemented "Js.Array" "toLocaleString"

  (* Iteration functions *)
  let everyi ~f arr =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then true
      else if f arr.(idx) idx then aux (idx + 1)
      else false
    in
    aux 0

  let every ~f arr =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then true else if f arr.(idx) then aux (idx + 1) else false
    in
    aux 0

  let filter ~f arr =
    arr |> Stdlib.Array.to_list |> List.filter f |> Stdlib.Array.of_list

  let filteri ~f arr =
    arr |> Stdlib.Array.to_list
    |> List.filteri (fun i a -> f a i)
    |> Stdlib.Array.of_list

  let findi ~f arr =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then None
      else if f arr.(idx) idx then Some arr.(idx)
      else aux (idx + 1)
    in
    aux 0

  let find ~f arr =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then None
      else if f arr.(idx) then Some arr.(idx)
      else aux (idx + 1)
    in
    aux 0

  let findIndexi ~f arr =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then -1 else if f arr.(idx) idx then idx else aux (idx + 1)
    in
    aux 0

  let findIndex ~f arr =
    let len = Stdlib.Array.length arr in
    let rec aux idx =
      if idx >= len then -1 else if f arr.(idx) then idx else aux (idx + 1)
    in
    aux 0

  let forEach ~f arr = Stdlib.Array.iter f arr
  let forEachi ~f arr = Stdlib.Array.iteri (fun i a -> f a i) arr
  let map ~f arr = Stdlib.Array.map f arr
  let mapi ~f arr = Stdlib.Array.mapi (fun i a -> f a i) arr

  let reduce ~f ~init arr =
    let r = ref init in
    for i = 0 to length arr - 1 do
      r := f !r (Stdlib.Array.unsafe_get arr i)
    done;
    !r

  let reducei ~f ~init arr =
    let r = ref init in
    for i = 0 to length arr - 1 do
      r := f !r (Stdlib.Array.unsafe_get arr i) i
    done;
    !r

  let reduceRight ~f ~init arr =
    let r = ref init in
    for i = length arr - 1 downto 0 do
      r := f !r (Stdlib.Array.unsafe_get arr i)
    done;
    !r

  let reduceRighti ~f ~init arr =
    let r = ref init in
    for i = length arr - 1 downto 0 do
      r := f !r (Stdlib.Array.unsafe_get arr i) i
    done;
    !r

  let some ~f arr =
    let n = Stdlib.Array.length arr in
    let rec loop i =
      if i = n then false
      else if f (Stdlib.Array.unsafe_get arr i) then true
      else loop (succ i)
    in
    loop 0

  let somei ~f arr =
    let n = Stdlib.Array.length arr in
    let rec loop i =
      if i = n then false
      else if f (Stdlib.Array.unsafe_get arr i) i then true
      else loop (succ i)
    in
    loop 0

  let unsafe_get arr idx = Stdlib.Array.unsafe_get arr idx
  let unsafe_set arr idx item = Stdlib.Array.unsafe_set arr idx item
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
end = struct
  (** Provide bindings to Js regex expression *)

  (* The RegExp object *)
  type t = Quickjs.RegExp.t

  (* The result of a executing a RegExp on a string. *)
  type result = Quickjs.RegExp.result

  (* Maps with nullable since Melange does too: https://melange.re/v3.0.0/api/re/melange/Js/Re/index.html#val-captures *)
  let captures : result -> string nullable array =
   fun result ->
    Quickjs.RegExp.captures result
    |> Stdlib.Array.map (fun x -> Nullable.return x)

  let index : result -> int = Quickjs.RegExp.index
  let input : result -> string = Quickjs.RegExp.input
  let source : t -> string = Quickjs.RegExp.source

  let fromString : string -> t =
   fun str ->
    match Quickjs.RegExp.compile str ~flags:"" with
    | Ok regex -> regex
    | Error (_, msg) -> raise (Invalid_argument msg)

  let fromStringWithFlags : string -> flags:string -> t =
   fun str ~flags ->
    match Quickjs.RegExp.compile str ~flags with
    | Ok regex -> regex
    | Error (_, msg) -> raise (Invalid_argument msg)

  let flags : t -> string = fun regexp -> Quickjs.RegExp.flags regexp
  let global : t -> bool = fun regexp -> Quickjs.RegExp.global regexp
  let ignoreCase : t -> bool = fun regexp -> Quickjs.RegExp.ignorecase regexp
  let multiline : t -> bool = fun regexp -> Quickjs.RegExp.multiline regexp
  let sticky : t -> bool = fun regexp -> Quickjs.RegExp.sticky regexp
  let unicode : t -> bool = fun regexp -> Quickjs.RegExp.unicode regexp
  let lastIndex : t -> int = fun regex -> Quickjs.RegExp.lastIndex regex

  let setLastIndex : t -> int -> unit =
   fun regex index -> Quickjs.RegExp.setLastIndex regex index

  let exec : str:string -> t -> result option =
   fun ~str rex ->
    match Quickjs.RegExp.exec rex str with
    | result -> Some result
    | exception _ -> None

  let test_ : t -> string -> bool =
   fun regexp str -> Quickjs.RegExp.test regexp str

  let test : str:string -> t -> bool = fun ~str regex -> test_ regex str
end

module String : sig
  type t = string

  val make : 'a -> t
  val fromCharCode : int -> t
  val fromCharCodeMany : int array -> t
  val fromCodePoint : int -> t
  val fromCodePointMany : int array -> t
  val length : t -> int
  val get : t -> int -> t
  val charAt : index:int -> t -> t
  val charCodeAt : index:int -> t -> float
  val codePointAt : index:int -> t -> int option
  val concat : other:t -> t -> t
  val concatMany : strings:t array -> t -> t
  val endsWith : suffix:t -> ?len:int -> t -> bool
  val includes : search:t -> ?start:int -> t -> bool
  val indexOf : search:t -> ?start:int -> t -> int
  val lastIndexOf : search:t -> ?start:int -> t -> int
  val localeCompare : other:t -> t -> float
  val match_ : regexp:Re.t -> t -> t option array option
  val normalize : ?form:[ `NFC | `NFD | `NFKC | `NFKD ] -> t -> t
  val repeat : count:int -> t -> t
  val replace : search:t -> replacement:t -> t -> t
  val replaceByRe : regexp:Re.t -> replacement:t -> t -> t
  val unsafeReplaceBy0 : regexp:Re.t -> f:(t -> int -> t -> t) -> t -> t
  val unsafeReplaceBy1 : regexp:Re.t -> f:(t -> t -> int -> t -> t) -> t -> t

  val unsafeReplaceBy2 :
    regexp:Re.t -> f:(t -> t -> t -> int -> t -> t) -> t -> t

  val unsafeReplaceBy3 :
    regexp:Re.t -> f:(t -> t -> t -> t -> int -> t -> t) -> t -> t

  val search : regexp:Re.t -> t -> int
  val slice : ?start:int -> ?end_:int -> t -> t
  val split : ?sep:t -> ?limit:int -> t -> t array
  val splitByRe : regexp:Re.t -> ?limit:int -> t -> t option array
  val startsWith : prefix:t -> ?start:int -> t -> bool
  val substr : ?start:int -> ?len:int -> t -> t
  val substring : ?start:int -> ?end_:int -> t -> t
  val toLowerCase : t -> t
  val toLocaleLowerCase : t -> t
  val toUpperCase : t -> t
  val toLocaleUpperCase : t -> t
  val trim : t -> t
  val anchor : name:t -> t -> t
  val link : href:t -> t -> t
end = struct
  type t = string
  (** JavaScript String API *)

  let make whatever = notImplemented "Js.String" "make"

  let fromCharCode code =
    let uchar = Uchar.of_int code in
    let char_value = Uchar.to_char uchar in
    Stdlib.String.make 1 char_value

  let fromCharCodeMany _ = notImplemented "Js.String" "fromCharCodeMany"

  let fromCodePoint code_point =
    let ch = Char.chr code_point in
    Stdlib.String.make 1 ch

  let fromCodePointMany _ = notImplemented "Js.String" "fromCodePointMany"
  let length = Stdlib.String.length

  let get str index =
    let ch = Stdlib.String.get str index in
    Stdlib.String.make 1 ch

  (* TODO (davesnx): If the string contains characters outside the range [\u0000-\uffff], it will return the first 16-bit value at that position in the string. *)
  let charAt ~index str =
    if index < 0 || index >= Stdlib.String.length str then ""
    else
      let ch = Stdlib.String.get str index in
      Stdlib.String.make 1 ch

  let charCodeAt ~index:n s =
    if n < 0 || n >= Stdlib.String.length s then nan
    else float_of_int (Stdlib.Char.code (Stdlib.String.get s n))

  let codePointAt ~index str =
    let str_length = Stdlib.String.length str in
    if index >= 0 && index < str_length then
      let uchar = Uchar.of_char (Stdlib.String.get str index) in
      Some (Uchar.to_int uchar)
    else None

  let concat ~other:str2 str1 = Stdlib.String.concat "" [ str1; str2 ]

  let concatMany ~strings:many original =
    let many_list = Stdlib.Array.to_list many in
    Stdlib.String.concat "" (original :: many_list)

  let endsWith ~suffix ?len str =
    let str_length = Stdlib.String.length str in
    let end_idx =
      match len with Some i -> Stdlib.min str_length i | None -> str_length
    in
    let sub_str = Stdlib.String.sub str 0 end_idx in
    Stdlib.String.ends_with ~suffix sub_str

  let includes ~search ?start str =
    let str_length = Stdlib.String.length str in
    let search_length = Stdlib.String.length search in
    let rec includes_helper idx =
      if idx + search_length > str_length then false
      else if Stdlib.String.sub str idx search_length = search then true
      else includes_helper (idx + 1)
    in
    let from = match start with None -> 0 | Some f -> f in
    includes_helper from

  let indexOf ~search ?start str =
    let str_length = Stdlib.String.length str in
    let search_length = Stdlib.String.length search in
    let rec index_helper idx =
      if idx + search_length > str_length then -1
      else if Stdlib.String.sub str idx search_length = search then idx
      else index_helper (idx + 1)
    in
    let from = match start with None -> 0 | Some f -> f in
    index_helper from

  let lastIndexOf ~search ?(start = max_int) str =
    let len = String.length str in
    let rec find_index i =
      if i < 0 || i > start then -1
      else
        let sub_len = min (len - i) (String.length search) in
        if String.sub str i sub_len = search then i else find_index (i - 1)
    in
    find_index (min (len - 1) start)

  let localeCompare ~other:_ _ = notImplemented "Js.String" "localeCompare"

  let match_ ~regexp str =
    let match_next str regex =
      match Re.exec ~str regex with
      | None -> None
      | Some result -> Some (Re.captures result)
    in

    let match_all : t -> Re.t -> t nullable array nullable =
     fun str regex ->
      match match_next str regex with
      | None -> None
      | Some result -> (
          match match_next str regex with
          | None -> Some result
          | Some second -> Some (Stdlib.Array.append result second))
    in

    if Re.global regexp then match_all str regexp else match_next str regexp

  let normalize ?form:_ _ = notImplemented "Js.String" "normalize"

  (* TODO(davesnx): RangeError *)
  let repeat ~count str =
    let rec repeat' str acc remaining =
      if remaining <= 0 then acc else repeat' str (str ^ acc) (remaining - 1)
    in
    repeat' str "" count

  (* If pattern is a string, only the first occurrence will be replaced.
     https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace *)
  let replace ~search ~replacement str =
    let search_regexp = Str.regexp_string search in
    Str.replace_first search_regexp replacement str

  let replaceByRe ~regexp ~replacement str =
    let rec replace_all str =
      Re.setLastIndex regexp 0;
      match Re.exec ~str regexp with
      | None -> str
      | Some result when Stdlib.Array.length (Re.captures result) == 0 -> str
      | Some result ->
          let matches = Re.captures result in
          let matched_str = Stdlib.Array.get matches 0 |> Option.get in
          let prefix = Stdlib.String.sub str 0 (Re.index result) in
          let suffix_start = Re.index result + String.length matched_str in
          let suffix =
            Stdlib.String.sub str suffix_start (String.length str - suffix_start)
          in
          Re.setLastIndex regexp suffix_start;
          prefix ^ replacement ^ replace_all suffix
    in
    let replace_first str =
      match Re.exec ~str regexp with
      | None -> str
      | Some result ->
          let matches = Re.captures result in
          let matched_str = Stdlib.Array.get matches 0 |> Option.get in
          let prefix = Stdlib.String.sub str 0 (Re.index result) in
          let suffix_start = Re.index result + String.length matched_str in
          let suffix =
            Stdlib.String.sub str suffix_start (String.length str - suffix_start)
          in
          prefix ^ replacement ^ suffix
    in

    if Re.global regexp then replace_all str else replace_first str

  let unsafeReplaceBy0 ~regexp:_ ~f:_ _ =
    notImplemented "Js.String" "unsafeReplaceBy0"

  let unsafeReplaceBy1 ~regexp:_ ~f:_ _ =
    notImplemented "Js.String" "unsafeReplaceBy1"

  let unsafeReplaceBy2 ~regexp:_ ~f:_ _ =
    notImplemented "Js.String" "unsafeReplaceBy2"

  let unsafeReplaceBy3 ~regexp:_ ~f:_ _ =
    notImplemented "Js.String" "unsafeReplaceBy3"

  let search ~regexp:_ _ = notImplemented "Js.String" "search"

  let slice ?start ?end_ str =
    let str_length = Stdlib.String.length str in
    let start = match start with None -> 0 | Some s -> s in
    let end_ = match end_ with None -> str_length | Some s -> s in
    let start_idx = Stdlib.max 0 (Stdlib.min start str_length) in
    let end_idx = Stdlib.max start_idx (Stdlib.min end_ str_length) in
    if start_idx >= end_idx then ""
    else Stdlib.String.sub str start_idx (end_idx - start_idx)

  let split ?sep ?limit str =
    let sep = Option.value sep ~default:str in
    let regexp = Str.regexp_string sep in
    (* On js split, it don't return an empty string on end when separator is an empty string *)
    (* but "split_delim" does *)
    (* https://melange.re/unstable/playground/?language=OCaml&code=SnMubG9nKEpzLlN0cmluZy5zcGxpdCB%2Bc2VwOiIiICJzdGFydCIpOw%3D%3D&live=off *)
    let split = if sep <> "" then Str.split_delim else Str.split in
    let items = split regexp str |> Stdlib.Array.of_list in
    let limit = Option.value limit ~default:(Stdlib.Array.length items) in
    match limit with
    | limit when limit >= 0 && limit < Stdlib.Array.length items ->
        Stdlib.Array.sub items 0 limit
    | _ -> items

  let splitByRe ~regexp ?limit str =
    let rev_array arr =
      arr |> Stdlib.Array.to_list |> Stdlib.List.rev |> Stdlib.Array.of_list
    in
    let rec split_all str acc =
      Re.setLastIndex regexp 0;
      match Re.exec ~str regexp with
      | Some result when Stdlib.Array.length (Re.captures result) = 0 ->
          Stdlib.Array.append [| Some str |] acc |> rev_array
      | None -> Stdlib.Array.append [| Some str |] acc |> rev_array
      | Some result ->
          let matches = Re.captures result in
          let matched_str = Stdlib.Array.get matches 0 |> Option.get in
          let prefix = String.sub str 0 (Re.index result) in
          let suffix_start = Re.index result + String.length matched_str in
          let suffix =
            String.sub str suffix_start (String.length str - suffix_start)
          in
          let suffix_matches = Stdlib.Array.append [| Some prefix |] acc in
          split_all suffix suffix_matches
    in

    let split_next str acc =
      Re.setLastIndex regexp 0;
      match Re.exec ~str regexp with
      | None -> Stdlib.Array.append [| Some str |] acc |> rev_array
      | Some result ->
          let matches = Re.captures result in
          let matched_str = Stdlib.Array.get matches 0 |> Option.get in
          let index = Re.index result in
          let prefix = String.sub str 0 index in
          let suffix_start = index + String.length matched_str in
          let suffix =
            String.sub str suffix_start (String.length str - suffix_start)
          in
          Stdlib.Array.append [| Some prefix |] (split_all suffix acc)
    in

    if Re.global regexp then split_all str [||] else split_next str [||]

  let startsWith ~prefix ?(start = 0) str =
    let len_prefix = String.length prefix in
    let len_str = String.length str in
    if start < 0 || start > len_str then false
    else
      let rec compare_prefix i =
        i = len_prefix
        || i < len_str
           && prefix.[i] = str.[start + i]
           && compare_prefix (i + 1)
      in
      compare_prefix 0

  let substr ?(start = 0) ?len str =
    let str_length = Stdlib.String.length str in
    let len = match len with None -> str_length | Some s -> s in
    let start_idx = max 0 (min start str_length) in
    let end_idx = min (start_idx + len) str_length in
    if start_idx >= end_idx then ""
    else Stdlib.String.sub str start_idx (end_idx - start_idx)

  let substring ?start ?end_ str =
    let str_length = Stdlib.String.length str in
    let start = match start with None -> 0 | Some s -> s in
    let end_ = match end_ with None -> str_length | Some s -> s in
    let start_idx = max 0 (min start str_length) in
    let end_idx = max 0 (min end_ str_length) in
    if start_idx >= end_idx then
      Stdlib.String.sub str end_idx (start_idx - end_idx)
    else Stdlib.String.sub str start_idx (end_idx - start_idx)

  let toLowerCase s = CamomileCaseMape.lowercase s
  let toLocaleLowerCase _ = notImplemented "Js.String" "toLocaleLowerCase"
  let toUpperCase s = CamomileCaseMape.uppercase s
  let toLocaleUpperCase _ = notImplemented "Js.String" "toLocaleUpperCase"

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

  let anchor ~name:_ _ = notImplemented "Js.String" "anchor"
  let link ~href:_ _ = notImplemented "Js.String" "link"
end

module Promise = struct
  type +'a t = 'a Lwt.t
  type error = exn

  let make (fn : resolve:('a -> unit) -> reject:(exn -> unit) -> unit) : 'a t =
    let promise, resolver = Lwt.task () in
    let resolve value = Lwt.wakeup_later resolver value in
    let reject exn = Lwt.wakeup_later_exn resolver exn in
    fn ~resolve ~reject;
    promise

  let resolve = Lwt.return
  let reject = Lwt.fail

  let all (promises : 'a t array) : 'a array t =
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

  let race (promises : 'a t array) : 'a t =
    Lwt.pick (Stdlib.Array.to_list promises)

  let then_ p fn = Lwt.bind fn p

  let catch (handler : exn -> 'a t) (promise : 'a t) : 'a t =
    Lwt.catch (fun () -> promise) handler
end

module Date : sig
  type t

  val valueOf : t -> float
  val make : unit -> t
  val fromFloat : float -> t
  val fromString : string -> t
  val makeWithYM : year:float -> month:float -> t
  val makeWithYMD : year:float -> month:float -> date:float -> t
  val makeWithYMDH : year:float -> month:float -> date:float -> hours:float -> t

  val makeWithYMDHM :
    year:float -> month:float -> date:float -> hours:float -> minutes:float -> t

  val makeWithYMDHMS :
    year:float ->
    month:float ->
    date:float ->
    hours:float ->
    minutes:float ->
    seconds:float ->
    t

  val utcWithYM : year:float -> month:float -> float
  val utcWithYMD : year:float -> month:float -> date:float -> float

  val utcWithYMDH :
    year:float -> month:float -> date:float -> hours:float -> float

  val utcWithYMDHM :
    year:float ->
    month:float ->
    date:float ->
    hours:float ->
    minutes:float ->
    float

  val utcWithYMDHMS :
    year:float ->
    month:float ->
    date:float ->
    hours:float ->
    minutes:float ->
    seconds:float ->
    float

  val now : unit -> float
  val parseAsFloat : string -> float
  val getDate : t -> float
  val getDay : t -> float
  val getFullYear : t -> float
  val getHours : t -> float
  val getMilliseconds : t -> float
  val getMinutes : t -> float
  val getMonth : t -> float
  val getSeconds : t -> float
  val getTime : t -> float
  val getTimezoneOffset : t -> float
  val getUTCDate : t -> float
  val getUTCDay : t -> float
  val getUTCFullYear : t -> float
  val getUTCHours : t -> float
  val getUTCMilliseconds : t -> float
  val getUTCMinutes : t -> float
  val getUTCMonth : t -> float
  val getUTCSeconds : t -> float
  val setDate : float -> t -> float
  val setFullYear : float -> t -> float
  val setFullYearM : year:float -> month:float -> t -> float
  val setFullYearMD : year:float -> month:float -> date:float -> t -> float
  val setHours : float -> t -> float
  val setHoursM : hours:float -> minutes:float -> t -> float
  val setHoursMS : hours:float -> minutes:float -> seconds:float -> t -> float

  val setHoursMSMs :
    hours:float ->
    minutes:float ->
    seconds:float ->
    milliseconds:float ->
    t ->
    float

  val setMilliseconds : float -> t -> float
  val setMinutes : float -> t -> float
  val setMinutesS : minutes:float -> seconds:float -> t -> float

  val setMinutesSMs :
    minutes:float -> seconds:float -> milliseconds:float -> t -> float

  val setMonth : float -> t -> float
  val setMonthD : month:float -> date:float -> t -> float
  val setSeconds : float -> t -> float
  val setSecondsMs : seconds:float -> milliseconds:float -> t -> float
  val setTime : float -> t -> float
  val setUTCDate : float -> t -> float
  val setUTCFullYear : float -> t -> float
  val setUTCFullYearM : year:float -> month:float -> t -> float
  val setUTCFullYearMD : year:float -> month:float -> date:float -> t -> float
  val setUTCHours : float -> t -> float
  val setUTCHoursM : hours:float -> minutes:float -> t -> float

  val setUTCHoursMS :
    hours:float -> minutes:float -> seconds:float -> t -> float

  val setUTCHoursMSMs :
    hours:float ->
    minutes:float ->
    seconds:float ->
    milliseconds:float ->
    t ->
    float

  val setUTCMilliseconds : float -> t -> float
  val setUTCMinutes : float -> t -> float
  val setUTCMinutesS : minutes:float -> seconds:float -> t -> float

  val setUTCMinutesSMs :
    minutes:float -> seconds:float -> milliseconds:float -> t -> float

  val setUTCMonth : float -> t -> float
  val setUTCMonthD : month:float -> date:float -> t -> float
  val setUTCSeconds : float -> t -> float
  val setUTCSecondsMs : seconds:float -> milliseconds:float -> t -> float
  val setUTCTime : float -> t -> float
  val toDateString : t -> string
  val toISOString : t -> string
  val toJSON : t -> string option
  val toJSONUnsafe : t -> string
  val toLocaleDateString : t -> string
  val toLocaleString : t -> string
  val toLocaleTimeString : t -> string
  val toString : t -> string
  val toTimeString : t -> string
  val toUTCString : t -> string
end = struct
  type t
  (** Provide bindings for JS Date *)

  (** returns the primitive value of this date, equivalent to getTime *)
  let valueOf _t = notImplemented "Js.Date" "valueOf"

  (** returns a date representing the current time *)
  let make _ = notImplemented "Js.Date" "make"

  let fromFloat _ = notImplemented "Js.Date" "fromFloat"
  let fromString _ = notImplemented "Js.Date" "fromString"
  let makeWithYM ~year:_ ~month:_ = notImplemented "Js.Date" "makeWithYM"

  let makeWithYMD ~year:_ ~month:_ ~date:_ =
    notImplemented "Js.Date" "makeWithYMD"

  let makeWithYMDH ~year:_ ~month:_ ~date:_ ~hours:_ =
    notImplemented "Js.Date" "makeWithYMDH"

  let makeWithYMDHM ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ =
    notImplemented "Js.Date" "makeWithYMDHM"

  let makeWithYMDHMS ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ ~seconds:_ =
    notImplemented "Js.Date" "makeWithYMDHMS"

  let utcWithYM ~year:_ ~month:_ = notImplemented "Js.Date" "utcWithYM"

  let utcWithYMD ~year:_ ~month:_ ~date:_ =
    notImplemented "Js.Date" "utcWithYMD"

  let utcWithYMDH ~year:_ ~month:_ ~date:_ ~hours:_ =
    notImplemented "Js.Date" "utcWithYMDH"

  let utcWithYMDHM ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ =
    notImplemented "Js.Date" "utcWithYMDHM"

  let utcWithYMDHMS ~year:_ ~month:_ ~date:_ ~hours:_ ~minutes:_ ~seconds:_ =
    notImplemented "Js.Date" "utcWithYMDHMS"

  (** returns the number of milliseconds since Unix epoch *)
  let now _ = notImplemented "Js.Date" "now"

  (** returns NaN if passed invalid date string *)
  let parseAsFloat _ = notImplemented "Js.Date" "parseAsFloat"

  (** return the day of the month (1-31) *)
  let getDate _ = notImplemented "Js.Date" "getDate"

  (** returns the day of the week (0-6) *)
  let getDay _ = notImplemented "Js.Date" "getDay"

  let getFullYear _ = notImplemented "Js.Date" "getFullYear"
  let getHours _ = notImplemented "Js.Date" "getHours"
  let getMilliseconds _ = notImplemented "Js.Date" "getMilliseconds"
  let getMinutes _ = notImplemented "Js.Date" "getMinutes"

  (** returns the month (0-11) *)
  let getMonth _ = notImplemented "Js.Date" "getMonth"

  let getSeconds _ = notImplemented "Js.Date" "getSeconds"

  (** returns the number of milliseconds since Unix epoch *)
  let getTime _ = notImplemented "Js.Date" "getTime"

  let getTimezoneOffset _ = notImplemented "Js.Date" "getTimezoneOffset"

  (** return the day of the month (1-31) *)
  let getUTCDate _ = notImplemented "Js.Date" "getUTCDate"

  (** returns the day of the week (0-6) *)
  let getUTCDay _ = notImplemented "Js.Date" "getUTCDay"

  let getUTCFullYear _ = notImplemented "Js.Date" "getUTCFullYear"
  let getUTCHours _ = notImplemented "Js.Date" "getUTCHours"
  let getUTCMilliseconds _ = notImplemented "Js.Date" "getUTCMilliseconds"
  let getUTCMinutes _ = notImplemented "Js.Date" "getUTCMinutes"

  (** returns the month (0-11) *)
  let getUTCMonth _ = notImplemented "Js.Date" "getUTCMonth"

  let getUTCSeconds _ = notImplemented "Js.Date" "getUTCSeconds"
  let setDate _ _ = notImplemented "Js.Date" "setDate"
  let setFullYear _ = notImplemented "Js.Date" "setFullYear"
  let setFullYearM ~year:_ ~month:_ = notImplemented "Js.Date" "setFullYearM"

  let setFullYearMD ~year:_ ~month:_ ~date:_ =
    notImplemented "Js.Date" "setFullYearMD"

  let setHours _ = notImplemented "Js.Date" "setHours"
  let setHoursM ~hours:_ ~minutes:_ = notImplemented "Js.Date" "setHoursM"
  let setHoursMS ~hours:_ ~minutes:_ = notImplemented "Js.Date" "setHoursMS"

  let setHoursMSMs ~hours:_ ~minutes:_ ~seconds:_ ~milliseconds:_ _ =
    notImplemented "Js.Date" "setHoursMSMs"

  let setMilliseconds _ = notImplemented "Js.Date" "setMilliseconds"
  let setMinutes _ = notImplemented "Js.Date" "setMinutes"
  let setMinutesS ~minutes:_ = notImplemented "Js.Date" "setMinutesS"
  let setMinutesSMs ~minutes:_ = notImplemented "Js.Date" "setMinutesSMs"
  let setMonth _ = notImplemented "Js.Date" "setMonth"
  let setMonthD ~month:_ ~date:_ _ = notImplemented "Js.Date" "setMonthD"
  let setSeconds _ = notImplemented "Js.Date" "setSeconds"

  let setSecondsMs ~seconds:_ ~milliseconds:_ _ =
    notImplemented "Js.Date" "setSecondsMs"

  let setTime _ = notImplemented "Js.Date" "setTime"
  let setUTCDate _ = notImplemented "Js.Date" "setUTCDate"
  let setUTCFullYear _ = notImplemented "Js.Date" "setUTCFullYear"

  let setUTCFullYearM ~year:_ ~month:_ _ =
    notImplemented "Js.Date" "setUTCFullYearM"

  let setUTCFullYearMD ~year:_ ~month:_ ~date:_ _ =
    notImplemented "Js.Date" "setUTCFullYearMD"

  let setUTCHours _ = notImplemented "Js.Date" "setUTCHours"
  let setUTCHoursM ~hours:_ ~minutes:_ = notImplemented "Js.Date" "setUTCHoursM"

  let setUTCHoursMS ~hours:_ ~minutes:_ =
    notImplemented "Js.Date" "setUTCHoursMS"

  let setUTCHoursMSMs ~hours:_ ~minutes:_ ~seconds:_ ~milliseconds:_ _ =
    notImplemented "Js.Date" "setUTCHoursMSMs"

  let setUTCMilliseconds _ = notImplemented "Js.Date" "setUTCMilliseconds"
  let setUTCMinutes _ = notImplemented "Js.Date" "setUTCMinutes"
  let setUTCMinutesS ~minutes:_ = notImplemented "Js.Date" "setUTCMinutesS"
  let setUTCMinutesSMs ~minutes:_ = notImplemented "Js.Date" "setUTCMinutesSMs"
  let setUTCMonth _ = notImplemented "Js.Date" "setUTCMonth"
  let setUTCMonthD ~month:_ ~date:_ _ = notImplemented "Js.Date" "setUTCMonthD"
  let setUTCSeconds _ = notImplemented "Js.Date" "setUTCSeconds"
  let setUTCSecondsMs ~seconds:_ = notImplemented "Js.Date" "setUTCSecondsMs"
  let setUTCTime _ = notImplemented "Js.Date" "setUTCTime"
  let toDateString string = notImplemented "Js.Date" "toDateString"
  let toISOString string = notImplemented "Js.Date" "toISOString"
  let toJSON string = notImplemented "Js.Date" "toJSON"
  let toJSONUnsafe string = notImplemented "Js.Date" "toJSONUnsafe"
  let toLocaleDateString string = notImplemented "Js.Date" "toLocaleDateString"

  (* TODO: has overloads with somewhat poor browser support *)
  let toLocaleString string = notImplemented "Js.Date" "toLocaleString"

  (* TODO: has overloads with somewhat poor browser support *)
  let toLocaleTimeString string = notImplemented "Js.Date" "toLocaleTimeString"

  (* TODO: has overloads with somewhat poor browser support *)
  let toString string = notImplemented "Js.Date" "toString"
  let toTimeString string = notImplemented "Js.Date" "toTimeString"
  let toUTCString string = notImplemented "Js.Date" "toUTCString"
end

module type Dictionary = sig
  (* Implemented as an associative list *)

  type 'a t
  type key = string

  val get : 'a t -> key -> 'a nullable
  val unsafeGet : 'a t -> key -> 'a
  val set : 'a t -> key -> 'a -> unit
  val keys : 'a t -> key array
  val empty : unit -> 'a t
  val unsafeDeleteKey : key t -> key -> unit
  val entries : 'a t -> (key * 'a) array
  val values : 'a t -> 'a array
  val fromList : (key * 'a) list -> 'a t
  val fromArray : (key * 'a) array -> 'a t
  val map : f:('a -> 'b) -> 'a t -> 'b t
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

  let map ~(f : 'a -> 'b) (dict : 'a t) =
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

module Global : sig
  (** Contains functions available in the global scope
    ([window] in a browser context) *)

  type intervalId
  (** Identify an interval started by {! setInterval} *)

  type timeoutId
  (** Identify timeout started by {! setTimeout} *)

  val clearInterval : intervalId -> unit
  val clearTimeout : timeoutId -> unit
  val setInterval : f:(unit -> unit) -> int -> intervalId
  val setIntervalFloat : f:(unit -> unit) -> float -> intervalId
  val setTimeout : f:(unit -> unit) -> int -> timeoutId
  val setTimeoutFloat : f:(unit -> unit) -> float -> timeoutId
  val encodeURI : string -> string
  val decodeURI : string -> string
  val encodeURIComponent : string -> string
  val decodeURIComponent : string -> string
end = struct
  type intervalId
  type timeoutId

  let clearInterval _intervalId = notImplemented "Js.Global" "clearInterval"
  let clearTimeout _timeoutId = notImplemented "Js.Global" "clearTimeout"
  let setInterval ~f:_ _ = notImplemented "Js.Global" "setInterval"
  let setIntervalFloat ~f:_ _ = notImplemented "Js.Global" "setInterval"
  let setTimeout ~f:_ _ = notImplemented "Js.Global" "setTimeout"
  let setTimeoutFloat ~f:_ _ = notImplemented "Js.Global" "setTimeout"
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

  (** {[
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

  let classify (_x : t) : tagged_t = notImplemented "Js.Json" "classify"
  let test _ : bool = notImplemented "Js.Json" "test"
  let decodeString json = notImplemented "Js.Json" "decodeString"
  let decodeNumber json = notImplemented "Js.Json" "decodeNumber"
  let decodeObject json = notImplemented "Js.Json" "decodeObject"
  let decodeArray json = notImplemented "Js.Json" "decodeArray"
  let decodeBoolean (json : t) = notImplemented "Js.Json" "decodeBoolean"
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
  let serializeExn (_x : t) : string = notImplemented "Js.Json" "serializeExn"

  let deserializeUnsafe (s : string) : 'a =
    notImplemented "Js.Json" "mplemented"
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
  val abs_float : float -> float
  val acos : float -> float
  val acosh : float -> float
  val asin : float -> float
  val asinh : float -> float
  val atan : float -> float
  val atanh : float -> float
  val atan2 : y:float -> x:float -> float
  val cbrt : float -> float
  val unsafe_ceil_int : float -> int
  val ceil_int : float -> int
  val ceil_float : float -> float
  val clz32 : int -> int
  val cos : float -> float
  val cosh : float -> float
  val exp : float -> float
  val expm1 : float -> float
  val unsafe_floor_int : float -> int
  val floor_int : float -> int
  val floor_float : float -> float
  val fround : float -> float
  val hypot : float -> float -> float
  val hypotMany : float array -> float
  val imul : int -> int -> int
  val log : float -> float
  val log1p : float -> float
  val log10 : float -> float
  val log2 : float -> float
  val max_int : int -> int -> int
  val maxMany_int : int array -> int
  val max_float : float -> float -> float
  val maxMany_float : float array -> float
  val min_int : int -> int -> int
  val minMany_int : int array -> int
  val min_float : float -> float -> float
  val minMany_float : float array -> float
  val pow_float : base:float -> exp:float -> float
  val random : unit -> float
  val random_int : int -> int -> int
  val unsafe_round : float -> int
  val round : float -> float
  val sign_int : int -> int
  val sign_float : float -> float
  val sin : float -> float
  val sinh : float -> float
  val sqrt : float -> float
  val tan : float -> float
  val tanh : float -> float
  val unsafe_trunc : float -> int
  val trunc : float -> float
end = struct
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
  let ceil_int _ = notImplemented "Js.Math" "ceil_int"
  let ceil_float _ = notImplemented "Js.Math" "ceil_float"
  let clz32 _ = notImplemented "Js.Math" "clz32"
  let cos = cos
  let cosh _ = notImplemented "Js.Math" "cosh"
  let exp _ = notImplemented "Js.Math" "exp"
  let expm1 _ = notImplemented "Js.Math" "expm1"
  let unsafe_floor_int _ = notImplemented "Js.Math" "unsafe_floor_int"
  let floor_int _f = notImplemented "Js.Math" "floor_int"
  let floor_float _ = notImplemented "Js.Math" "floor_float"
  let fround _ = notImplemented "Js.Math" "fround"
  let hypot _ = notImplemented "Js.Math" "hypot"
  let hypotMany _ = notImplemented "Js.Math" "hypotMany"
  let imul _ = notImplemented "Js.Math" "imul"
  let log _ = notImplemented "Js.Math" "log"
  let log1p _ = notImplemented "Js.Math" "log1p"
  let log10 _ = notImplemented "Js.Math" "log10"
  let log2 _ = notImplemented "Js.Math" "log2"
  let max_int (a : int) (b : int) = Stdlib.max a b
  let maxMany_int _ = notImplemented "Js.Math" "maxMany_int"
  let max_float (a : float) (b : float) = Stdlib.max a b
  let maxMany_float _ = notImplemented "Js.Math" "maxMany_float"
  let min_int (a : int) (b : int) = Stdlib.min a b
  let minMany_int _ = notImplemented "Js.Math" "minMany_int"
  let min_float (a : float) (b : float) = Stdlib.min a b
  let minMany_float _ = notImplemented "Js.Math" "minMany_float"
  let pow_float ~base:_ ~exp:_ = notImplemented "Js.Math" "pow_float"
  let random _ = notImplemented "Js.Math" "random"
  let random_int _min _max = notImplemented "Js.Math" "random_int"
  let unsafe_round _ = notImplemented "Js.Math" "unsafe_round"
  let round _ = notImplemented "Js.Math" "round"
  let sign_int _ = notImplemented "Js.Math" "sign_int"
  let sign_float _ = notImplemented "Js.Math" "sign_float"
  let sin = sin
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

module Float : sig
  (** Provides functions for inspecting and manipulating [float]s *)

  type t = float

  val _NaN : t
  val isNaN : t -> bool
  val isFinite : t -> bool
  val toExponential : ?digits:int -> t -> string
  val toFixed : ?digits:int -> t -> string
  val toPrecision : ?digits:int -> t -> string
  val toString : ?radix:int -> t -> string
  val fromString : string -> t
end = struct
  type t = float

  let _NaN = Stdlib.Float.nan
  let isNaN float = Stdlib.Float.is_nan float
  let isFinite float = Stdlib.Float.is_finite float
  let toExponential ?digits:_ _ = notImplemented "Js.Float" "toExponential"
  let toFixed ?digits:_ _ = notImplemented "Js.Float" "toFixed"
  let toPrecision ?digits:_ _ = notImplemented "Js.Float" "toPrecision"

  let toString ?radix f =
    match radix with
    | None ->
        (* round x rounds x to the nearest integer with ties (fractional values of 0.5) rounded away from zero, regardless of the current rounding direction. If x is an integer, +0., -0., nan, or infinite, x itself is returned.

           On 64-bit mingw-w64, this function may be emulated owing to a bug in the C runtime library (CRT) on this platform. *)
        (* if round(f) == f, print the integer (since string_of_float 1.0 => "1.") *)
        if Stdlib.Float.equal (Stdlib.Float.round f) f then
          f |> int_of_float |> string_of_int
        else Printf.sprintf "%g" f
    | Some _ -> notImplemented "Js.Float" "toString ~radix"

  let fromString = Stdlib.float_of_string
end

module Int : sig
  (** Provides functions for inspecting and manipulating [int]s *)

  type t = int

  val toExponential : ?digits:t -> t -> string
  val toPrecision : ?digits:t -> t -> string
  val toString : ?radix:t -> t -> string
  val toFloat : t -> float
  val equal : t -> t -> bool
  val max : t
  val min : t
end = struct
  type t = int

  let toExponential ?digits:_ _ = notImplemented "Js.Int" "toExponential"
  let toPrecision ?digits:_ _ = notImplemented "Js.Int" "toPrecision"

  let toString ?radix int =
    match radix with
    | None -> Stdlib.string_of_int int
    | Some _ -> notImplemented "Js.Int" "toString ~radix"

  let toFloat int = Stdlib.float_of_int int
  let equal = Stdlib.Int.equal
  let max = 2147483647
  let min = -2147483648
end

module Bigint = struct
  (** Provide utilities for bigint *)
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
  let log _ = ()
  let log2 _ _ = ()
  let log3 _ _ _ = ()
  let log4 _ _ _ _ = ()
  let logMany _arr = ()
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
