type t = Hashtbl.t(string, ReactServerDOM.server_function);

let registry = Hashtbl.create(10);
let register = Hashtbl.add(registry);
let get = Hashtbl.find_opt(registry);
