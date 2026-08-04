type destination = string

module Status = struct end
module Loader = struct end
module Error = struct end
module Metadata = struct end
module Headers = struct end
module Navigation = struct
  type status = Idle
end
module Search = struct end
module Link = struct end

let destinationFromPattern ~pattern:_ ~parameters:_ ~search:_ = ""
let href destination = destination
