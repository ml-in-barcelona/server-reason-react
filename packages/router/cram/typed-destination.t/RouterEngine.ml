type pattern = string

let pattern path = path
let destinationFromPattern ~pattern:_ ~parameters:_ ~search:_ = ""
let withShallowSearch destination _ = destination

module CatchAll = struct
  let parse value = Ok (String.split_on_char '/' value)
  let toString segments = String.concat "/" segments
end

module SearchValues = struct
  type options = unit

  let parseString value = Ok value

  let parseInt value =
    match int_of_string_opt value with Some value -> Ok value | None -> Error "expected an integer"

  let parseBool value =
    match bool_of_string_opt value with Some value -> Ok value | None -> Error "expected true or false"

  let required ~name:_ ~parse:_ _ = None
  let optional ~name:_ ~parse:_ _ = None
  let default ~name:_ ~parse:_ ~fallback _ = fallback
  let many ~name:_ ~parse:_ _ = []
end

