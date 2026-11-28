type props =
  | Scalars of int * string * bool * Code.t
  | Optional of int option * string option
  | Rest of string list
  | OptRest of int * string list

let rendered : props option ref = ref None

module Scalars = struct
  let[@react.component] make ~(i : int) ~(s : string) ~(b : bool) ~(c : Code.t) () =
    rendered := Some (Scalars (i, s, b, c));
    React.null
end

module Optional = struct
  let[@react.component] make ~(i : int option) ~(s : string option) () =
    rendered := Some (Optional (i, s));
    React.null
end

module Rest = struct
  let[@react.component] make ~(parts : string list) () =
    rendered := Some (Rest parts);
    React.null
end

module OptRest = struct
  let[@react.component] make ~(lead : int) ~(rest : string list) () =
    rendered := Some (OptRest (lead, rest));
    React.null
end

module L = struct
  let load () : (string, string) RouterRuntime.Loader.result Lwt.t = Lwt.return (RouterRuntime.Loader.Data "")
end

module Loaded = struct
  let[@react.component] make ~(data : string) () = React.string data
end
