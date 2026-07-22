(** Provide bindings to Js regex expression *)

type t = Quickjs.RegExp.t

(* The result of executing a RegExp on a string. *)
type result = Quickjs.RegExp.match_result

(* Maps with nullable since Melange does too: https://melange.re/v3.0.0/api/re/melange/Js/Re/index.html#val-captures *)
let captures : result -> string Js_internal.nullable array = fun result -> result.Quickjs.RegExp.captures
let index : result -> int = fun result -> result.Quickjs.RegExp.index
let input : result -> string = fun result -> result.Quickjs.RegExp.input
let source : t -> string = Quickjs.RegExp.source

let fromString : string -> t =
 fun str ->
  match Quickjs.RegExp.compile str ~flags:"" with
  | Ok regex -> regex
  | Error err -> raise (Invalid_argument (Quickjs.RegExp.compile_error_to_string err))

let fromStringWithFlags : string -> flags:string -> t =
 fun str ~flags ->
  match Quickjs.RegExp.compile str ~flags with
  | Ok regex -> regex
  | Error err -> raise (Invalid_argument (Quickjs.RegExp.compile_error_to_string err))

let flags : t -> string = Quickjs.RegExp.flags
let global : t -> bool = Quickjs.RegExp.global
let ignoreCase : t -> bool = Quickjs.RegExp.ignorecase
let multiline : t -> bool = Quickjs.RegExp.multiline
let sticky : t -> bool = Quickjs.RegExp.sticky
let unicode : t -> bool = Quickjs.RegExp.unicode
let dotAll : t -> bool = Quickjs.RegExp.dotall
let lastIndex : t -> int = Quickjs.RegExp.last_index
let setLastIndex : t -> int -> unit = Quickjs.RegExp.set_last_index

(* [exec]/[test] stay eta-expanded to erase Quickjs's [?timeout_ms] optional argument *)
let exec : str:string -> t -> result option = fun ~str rex -> Quickjs.RegExp.exec rex str
let test : str:string -> t -> bool = fun ~str regex -> Quickjs.RegExp.test regex str

module Prepared = struct
  type input = Quickjs.RegExp.prepared_input
  type match_ = Quickjs.RegExp.prepared_match

  let make = Quickjs.RegExp.prepare_input
  let exec input regexp = Quickjs.RegExp.exec_prepared regexp input
  let captures match_ = match_.Quickjs.RegExp.result.captures
  let range match_ = match_.Quickjs.RegExp.range.utf16
  let byte_range = Quickjs.RegExp.prepared_byte_range
  let substring = Quickjs.RegExp.prepared_substring
  let advance_index = Quickjs.RegExp.prepared_advance_index
end

(* Named capture groups *)
let groups : result -> (string * string option) list = fun result -> result.Quickjs.RegExp.groups
let group : string -> result -> string option = Quickjs.RegExp.group
