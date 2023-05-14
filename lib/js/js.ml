type 'a t = < .. > as 'a
type 'a null = 'a option
type 'a undefined = 'a option
type 'a nullable = 'a option

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

module Nullable = struct
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
  let log a = print_endline (Obj.magic a)

  let log2 a b =
    print_endline (Printf.sprintf "%s %s" (Obj.magic a) (Obj.magic b))

  let log3 a b c =
    print_endline
      (Printf.sprintf "%s %s %s" (Obj.magic a) (Obj.magic b) (Obj.magic c))

  let log4 a b c d =
    print_endline
      (Printf.sprintf "%s %s %s %s" (Obj.magic a) (Obj.magic b) (Obj.magic c)
         (Obj.magic d))

  let logMany arr = Array.iter log arr
  let info = log
  let info2 = log2
  let info3 = log3
  let info4 = log4
  let infoMany = logMany
  let error = log
  let error2 = log2
  let error3 = log3
  let error4 = log4
  let errorMany = logMany
  let warn = log
  let warn2 = log2
  let warn3 = log3
  let warn4 = log4
  let warnMany = logMany

  (* external trace : unit -> unit = "trace" [@@bs.val] [@@bs.scope "console"] *)
  (* external timeStart : string -> unit = "time" [@@bs.val] [@@bs.scope "console"] *)
  (* external timeEnd : string -> unit = "timeEnd" [@@bs.val] [@@bs.scope "console"] *)
  let trace () = ()
  let timeStart _ = ()
  let timeEnd _ = ()
end
