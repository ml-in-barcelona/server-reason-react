type error

external makeError : string -> error = "Error" [@@bs.new]

let raiseError str = raise (Obj.magic (makeError str : error) : exn)
