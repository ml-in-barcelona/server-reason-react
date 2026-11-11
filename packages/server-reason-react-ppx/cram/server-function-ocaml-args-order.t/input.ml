module FunctionReferences : ReactServerDOM.FunctionReferences = struct
  type t = (string, ReactServerDOM.server_function) Hashtbl.t

  let registry = Hashtbl.create 10
  let register = Hashtbl.add registry
  let get = Hashtbl.find_opt registry
end

let join =
 fun (first : string) (second : int) ~(sep : string) : string Js.Promise.t ->
  Lwt.return (first ^ sep ^ string_of_int second)
[@@react.server.function]
