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

module Search = struct
  type options = unit
end

module Link = struct
  type options = unit
end

let pattern path = path
let destinationFromPattern ~pattern:_ ~parameters:_ ~search:_ = ""
let href destination = destination
