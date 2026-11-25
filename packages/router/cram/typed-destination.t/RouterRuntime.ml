type destination = string

module Status = struct end

module Loader = struct
  type ('data, 'error) result = Data of 'data | Error of 'error | NotFound | Redirect of destination
end

module Error = struct end
module Metadata = struct end
module Headers = struct end

module Navigation = struct
  type location = { pathname : string; search : string; hash : string; key : string }
  type matched = { routeId : string; parameters : (string * string) list }
  type historyAction = Push | Replace | Pop
  type status = Idle

  module Result = struct
    type t = unit
  end
end

module Link = struct
  type options = unit
end

let destination ~path = path
let href destination = destination
let withHash destination ~hash:_ = destination
