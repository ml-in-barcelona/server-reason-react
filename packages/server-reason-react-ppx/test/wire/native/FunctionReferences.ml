let registry : (string, ReactServerDOM.server_function) Hashtbl.t = Hashtbl.create 32
let register id handler = Hashtbl.add registry id handler
let get id = Hashtbl.find_opt registry id
