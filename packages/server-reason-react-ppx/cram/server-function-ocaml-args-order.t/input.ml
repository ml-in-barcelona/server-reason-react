module FunctionReferences = ReactServerDOM.FunctionReferences.Make (struct
  type t = unit

  let default = ()
end)

let join =
 fun (first : string) (second : int) ~(sep : string) : string Js.Promise.t ->
  Lwt.return (first ^ sep ^ string_of_int second)
[@@react.server.function]
