type 'a null = 'a option
type 'a undefined = 'a option

external toOption : 'a null -> 'a option = "%identity"
external nullToOption : 'a null -> 'a option = "%identity"
external undefinedToOption : 'a null -> 'a option = "%identity"
external fromOpt : 'a option -> 'a undefined = "%identity"

let undefined = None
let null = None
let empty = None

module Undefined = struct
  type 'a t = 'a undefined

  external return : 'a -> 'a t = "%identity"

  let empty = None

  external toOption : 'a t -> 'a option = "%identity"
  external fromOpt : 'a option -> 'a t = "%identity"
end

module Null = struct
  type 'a t = 'a null

  external toOption : 'a t -> 'a option = "%identity"
  external fromOpt : 'a option -> 'a t = "%identity"

  let return a = fromOpt (Some a)
  let getUnsafe a = match toOption a with None -> assert false | Some a -> a
end

module Exn = struct
  type error

  external makeError : string -> error = "Error" [@@bs.new]

  let raiseError str = raise (Obj.magic (makeError str : error) : exn)
end

module Console = struct
  let error = print_endline
  let log = print_endline
  let warn = print_endline
end
