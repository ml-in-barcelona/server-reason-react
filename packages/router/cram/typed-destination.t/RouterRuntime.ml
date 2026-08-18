type destination = string
type pattern = string

module Status = struct end

module Loader = struct
  type ('data, 'error) result = Data of 'data | Error of 'error | NotFound | Redirect of destination
end

module Error = struct end
module Metadata = struct end
module Headers = struct end

module Navigation = struct
  type historyAction = Push | Replace | Pop
  type status = Idle

  module Result = struct
    type t = unit
  end
end

module CatchAll = struct
  let parse value = Ok (String.split_on_char '/' value)
  let toString segments = String.concat "/" segments
end

module Search = struct
  type options = unit

  let parseString value = Ok value

  let parseBool value =
    match bool_of_string_opt value with Some value -> Ok value | None -> Error "expected true or false"
end

module Link = struct
  type options = unit
end

let pattern path = path
let destination ~path = path
let destinationFromPattern ~pattern:_ ~parameters:_ ~search:_ = ""
let href destination = destination
