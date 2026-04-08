type t = Js.Json.t
type of_rsc_error = Rsc_error of string | Unexpected_variant of string

exception Of_rsc_error of of_rsc_error

let of_rsc_error_to_string = function Rsc_error msg -> msg | Unexpected_variant msg -> "unexpected variant: " ^ msg
let is_null value = (Obj.magic value : 'a Js.null) == Js.null
let is_undefined value = Js.typeof value = "undefined"
let is_nullish value = is_null value || is_undefined value
let describe value = if is_null value then "null" else if Js.Array.isArray value then "array" else Js.typeof value
let of_rsc_msg_error msg = raise (Of_rsc_error (Rsc_error msg))
let of_rsc_msg_unexpected_variant msg = raise (Of_rsc_error (Unexpected_variant msg))
let of_rsc_error ?depth:_ ?width:_ ~rsc msg = of_rsc_msg_error (msg ^ "; received " ^ describe (Obj.magic rsc))

let of_rsc_unexpected_variant ?depth:_ ?width:_ ~rsc msg =
  of_rsc_msg_unexpected_variant (msg ^ "; received " ^ describe (Obj.magic rsc))

let promise_cache_key = "__server_reason_react_rsc_promise"

let cached_promise decode promise =
  let cache = (Obj.magic promise : 'a Js.Promise.t Js.Dict.t) in
  match Js.Dict.get cache promise_cache_key with
  | Some promise -> promise
  | None ->
      let decoded =
        (Obj.magic (Js.Promise.resolve promise) : t Js.Promise.t)
        |> Js.Promise.then_ (fun value -> Js.Promise.resolve (decode value))
      in
      Js.Dict.set cache promise_cache_key decoded;
      decoded

module Primitives = struct
  let string_to_rsc value = Obj.magic value
  let bool_to_rsc value = Obj.magic value
  let float_to_rsc value = Obj.magic value
  let int_to_rsc value = Obj.magic value
  let int64_to_rsc value = Obj.magic (Int64.to_string value)
  let char_to_rsc value = Obj.magic (String.make 1 value)
  let unit_to_rsc () = Obj.magic Js.null
  let option_to_rsc to_rsc = function None -> unit_to_rsc () | Some value -> to_rsc value
  let list_values_to_rsc values = Obj.magic (Array.of_list values)

  let assoc_to_rsc values =
    let dict = Js.Dict.empty () in
    List.iter (fun (key, value) -> Js.Dict.set dict key value) values;
    Obj.magic dict

  let result_to_rsc ok_to_rsc error_to_rsc = function
    | Ok value -> list_values_to_rsc [ string_to_rsc "Ok"; ok_to_rsc value ]
    | Error value -> list_values_to_rsc [ string_to_rsc "Error"; error_to_rsc value ]

  let list_to_rsc to_rsc values = list_values_to_rsc (List.map to_rsc values)
  let array_to_rsc to_rsc values = values |> Array.to_list |> List.map to_rsc |> list_values_to_rsc
  let tuple2_to_rsc a_to_rsc b_to_rsc (a, b) = list_values_to_rsc [ a_to_rsc a; b_to_rsc b ]
  let tuple3_to_rsc a_to_rsc b_to_rsc c_to_rsc (a, b, c) = list_values_to_rsc [ a_to_rsc a; b_to_rsc b; c_to_rsc c ]

  let tuple4_to_rsc a_to_rsc b_to_rsc c_to_rsc d_to_rsc (a, b, c, d) =
    list_values_to_rsc [ a_to_rsc a; b_to_rsc b; c_to_rsc c; d_to_rsc d ]

  let react_element_to_rsc element = Obj.magic element

  let promise_to_rsc to_rsc promise =
    Obj.magic (Js.Promise.then_ (fun value -> Js.Promise.resolve (to_rsc value)) promise)

  let server_function_to_rsc action = Obj.magic action
  let string_of_rsc rsc = if Js.typeof rsc = "string" then Obj.magic rsc else of_rsc_error ~rsc "expected a string"
  let bool_of_rsc rsc = if Js.typeof rsc = "boolean" then Obj.magic rsc else of_rsc_error ~rsc "expected a bool"

  let int_of_rsc rsc =
    if Js.typeof rsc = "number" then
      let value = (Obj.magic rsc : float) in
      if Js.Math.floor_float value == value then Obj.magic value else of_rsc_error ~rsc "expected an int"
    else of_rsc_error ~rsc "expected an int"

  let int64_of_rsc rsc =
    if Js.typeof rsc = "string" then
      match Int64.of_string_opt (Obj.magic rsc : string) with
      | Some value -> value
      | None -> of_rsc_error ~rsc "expected int64 as string"
    else of_rsc_error ~rsc "expected int64 as string"

  let float_of_rsc rsc = if Js.typeof rsc = "number" then Obj.magic rsc else of_rsc_error ~rsc "expected a float"

  let char_of_rsc rsc =
    let value = string_of_rsc rsc in
    if String.length value = 1 then String.get value 0 else of_rsc_error ~rsc "expected a single-character string"

  let unit_of_rsc rsc = if is_nullish (Obj.magic rsc) then () else of_rsc_error ~rsc "expected null"
  let option_of_rsc of_rsc rsc = if is_nullish (Obj.magic rsc) then None else Some (of_rsc rsc)

  let array_of_rsc of_rsc rsc =
    if Js.Array.isArray rsc then Array.map of_rsc (Obj.magic rsc : t array) else of_rsc_error ~rsc "expected an array"

  let list_of_rsc of_rsc rsc = array_of_rsc of_rsc rsc |> Array.to_list

  let tuple2_of_rsc a_of_rsc b_of_rsc rsc =
    match list_of_rsc (fun value -> value) rsc with
    | [ a; b ] -> (a_of_rsc a, b_of_rsc b)
    | _ -> of_rsc_error ~rsc "expected a tuple of length 2"

  let tuple3_of_rsc a_of_rsc b_of_rsc c_of_rsc rsc =
    match list_of_rsc (fun value -> value) rsc with
    | [ a; b; c ] -> (a_of_rsc a, b_of_rsc b, c_of_rsc c)
    | _ -> of_rsc_error ~rsc "expected a tuple of length 3"

  let tuple4_of_rsc a_of_rsc b_of_rsc c_of_rsc d_of_rsc rsc =
    match list_of_rsc (fun value -> value) rsc with
    | [ a; b; c; d ] -> (a_of_rsc a, b_of_rsc b, c_of_rsc c, d_of_rsc d)
    | _ -> of_rsc_error ~rsc "expected a tuple of length 4"

  let result_of_rsc ok_of_rsc error_of_rsc rsc =
    match list_of_rsc (fun value -> value) rsc with
    | [ tag; value ] ->
        let tag = string_of_rsc tag in
        if tag = "Ok" then Ok (ok_of_rsc value)
        else if tag = "Error" then Error (error_of_rsc value)
        else of_rsc_unexpected_variant ~rsc {|expected ["Ok"; _] or ["Error"; _]|}
    | _ -> of_rsc_error ~rsc {|expected ["Ok"; _] or ["Error"; _]|}

  let react_element_of_rsc rsc = Obj.magic rsc
  let promise_of_rsc of_rsc rsc = cached_promise of_rsc (Obj.magic rsc)
  let server_function_of_rsc rsc = Obj.magic rsc
end
