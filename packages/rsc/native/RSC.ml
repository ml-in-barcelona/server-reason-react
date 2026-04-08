module Model = React.Model

type t = React.element Model.t
type of_rsc_error = Rsc_error of string | Unexpected_variant of string

exception Of_rsc_error of of_rsc_error

let of_rsc_error_to_string = function Rsc_error msg -> msg | Unexpected_variant msg -> "unexpected variant: " ^ msg

let describe_model : t -> string = function
  | Model.Json `Null -> "null"
  | Model.Json (`Bool _) -> "bool"
  | Model.Json (`Int _) -> "int"
  | Model.Json (`Float _) -> "float"
  | Model.Json (`String _) -> "string"
  | Model.Json (`Assoc _) -> "json object"
  | Model.Json (`List _) -> "json array"
  | Model.Element _ -> "React.element"
  | Model.Promise _ -> "Promise"
  | Model.Function _ -> "server function"
  | Model.Assoc _ -> "object"
  | Model.List _ -> "array"
  | Model.Error _ -> "error"

let of_rsc_msg_error msg = raise (Of_rsc_error (Rsc_error msg))
let of_rsc_msg_unexpected_variant msg = raise (Of_rsc_error (Unexpected_variant msg))
let of_rsc_error ?depth:_ ?width:_ ~rsc msg = of_rsc_msg_error (msg ^ "; received " ^ describe_model rsc)

let of_rsc_unexpected_variant ?depth:_ ?width:_ ~rsc msg =
  of_rsc_msg_unexpected_variant (msg ^ "; received " ^ describe_model rsc)

let of_model model = model
let to_model model = model
let map_json_list decode values = List.map (fun value -> decode (of_model (Model.Json value))) values

module Primitives = struct
  let list_values_to_rsc values = of_model (Model.List (List.map to_model values))
  let assoc_to_rsc values = of_model (Model.Assoc (List.map (fun (key, value) -> (key, to_model value)) values))
  let string_to_rsc value = of_model (Model.Json (`String value))
  let bool_to_rsc value = of_model (Model.Json (`Bool value))
  let float_to_rsc value = of_model (Model.Json (`Float value))
  let int_to_rsc value = of_model (Model.Json (`Int value))
  let int64_to_rsc value = of_model (Model.Json (`String (Int64.to_string value)))
  let char_to_rsc value = string_to_rsc (String.make 1 value)
  let unit_to_rsc () = of_model (Model.Json `Null)
  let option_to_rsc to_rsc = function None -> unit_to_rsc () | Some value -> to_rsc value

  let result_to_rsc ok_to_rsc error_to_rsc = function
    | Ok value -> list_values_to_rsc [ string_to_rsc "Ok"; ok_to_rsc value ]
    | Error value -> list_values_to_rsc [ string_to_rsc "Error"; error_to_rsc value ]

  let list_to_rsc to_rsc values = list_values_to_rsc (List.map to_rsc values)
  let array_to_rsc to_rsc values = values |> Array.to_list |> List.map to_rsc |> list_values_to_rsc
  let tuple2_to_rsc a_to_rsc b_to_rsc (a, b) = list_values_to_rsc [ a_to_rsc a; b_to_rsc b ]
  let tuple3_to_rsc a_to_rsc b_to_rsc c_to_rsc (a, b, c) = list_values_to_rsc [ a_to_rsc a; b_to_rsc b; c_to_rsc c ]

  let tuple4_to_rsc a_to_rsc b_to_rsc c_to_rsc d_to_rsc (a, b, c, d) =
    list_values_to_rsc [ a_to_rsc a; b_to_rsc b; c_to_rsc c; d_to_rsc d ]

  let react_element_to_rsc element = of_model (Model.Element element)
  let promise_to_rsc to_rsc promise = of_model (Model.Promise (promise, fun value -> to_model (to_rsc value)))
  let server_function_to_rsc action = of_model (Model.Function action)

  let string_of_rsc rsc =
    match to_model rsc with Model.Json (`String value) -> value | model -> of_rsc_error ~rsc:model "expected a string"

  let bool_of_rsc rsc =
    match to_model rsc with Model.Json (`Bool value) -> value | model -> of_rsc_error ~rsc:model "expected a bool"

  let int_of_rsc rsc =
    match to_model rsc with Model.Json (`Int value) -> value | model -> of_rsc_error ~rsc:model "expected an int"

  let int64_of_rsc rsc =
    match to_model rsc with
    | Model.Json (`String value) -> (
        match Int64.of_string_opt value with
        | Some value -> value
        | None -> of_rsc_error ~rsc:(to_model rsc) "expected int64 as string")
    | model -> of_rsc_error ~rsc:model "expected int64 as string"

  let float_of_rsc rsc =
    match to_model rsc with
    | Model.Json (`Float value) -> value
    | Model.Json (`Int value) -> float_of_int value
    | model -> of_rsc_error ~rsc:model "expected a float"

  let char_of_rsc rsc =
    let value = string_of_rsc rsc in
    if String.length value = 1 then String.get value 0
    else of_rsc_error ~rsc:(to_model rsc) "expected a single-character string"

  let unit_of_rsc rsc =
    match to_model rsc with Model.Json `Null -> () | model -> of_rsc_error ~rsc:model "expected null"

  let option_of_rsc of_rsc rsc = match to_model rsc with Model.Json `Null -> None | _ -> Some (of_rsc rsc)

  let list_of_rsc of_rsc rsc =
    match to_model rsc with
    | Model.List values -> List.map of_rsc (List.map of_model values)
    | Model.Json (`List values) -> map_json_list of_rsc values
    | model -> of_rsc_error ~rsc:model "expected an array"

  let array_of_rsc of_rsc rsc = list_of_rsc of_rsc rsc |> Array.of_list

  let tuple2_of_rsc a_of_rsc b_of_rsc rsc =
    match list_of_rsc (fun value -> value) rsc with
    | [ a; b ] -> (a_of_rsc a, b_of_rsc b)
    | _ -> of_rsc_error ~rsc:(to_model rsc) "expected a tuple of length 2"

  let tuple3_of_rsc a_of_rsc b_of_rsc c_of_rsc rsc =
    match list_of_rsc (fun value -> value) rsc with
    | [ a; b; c ] -> (a_of_rsc a, b_of_rsc b, c_of_rsc c)
    | _ -> of_rsc_error ~rsc:(to_model rsc) "expected a tuple of length 3"

  let tuple4_of_rsc a_of_rsc b_of_rsc c_of_rsc d_of_rsc rsc =
    match list_of_rsc (fun value -> value) rsc with
    | [ a; b; c; d ] -> (a_of_rsc a, b_of_rsc b, c_of_rsc c, d_of_rsc d)
    | _ -> of_rsc_error ~rsc:(to_model rsc) "expected a tuple of length 4"

  let result_of_rsc ok_of_rsc error_of_rsc rsc =
    match list_of_rsc (fun value -> value) rsc with
    | [ tag; value ] ->
        let tag = string_of_rsc tag in
        if tag = "Ok" then Ok (ok_of_rsc value)
        else if tag = "Error" then Error (error_of_rsc value)
        else of_rsc_unexpected_variant ~rsc:(to_model rsc) {|expected ["Ok"; _] or ["Error"; _]|}
    | _ -> of_rsc_error ~rsc:(to_model rsc) {|expected ["Ok"; _] or ["Error"; _]|}

  let react_element_of_rsc rsc =
    match to_model rsc with
    | Model.Element element -> element
    | model -> of_rsc_error ~rsc:model "expected a React.element"

  let promise_of_rsc of_rsc rsc =
    match to_model rsc with
    | Model.Promise (promise, to_rsc) ->
        Js.Promise.then_ (fun value -> Js.Promise.resolve (of_rsc (of_model (to_rsc value)))) promise
    | model -> of_rsc_error ~rsc:model "expected a promise"

  let server_function_of_rsc rsc =
    match to_model rsc with
    | Model.Function _ ->
        of_rsc_msg_error "decoding Runtime.server_function from native RSC values is only supported on the client"
    | model -> of_rsc_error ~rsc:model "expected a server function"
end
