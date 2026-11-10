module FunctionReferences: ReactServerDOM.FunctionReferences = {
  type t = Hashtbl.t(string, ReactServerDOM.server_function);

  let registry = Hashtbl.create(10);
  let register = Hashtbl.add(registry);
  let get = Hashtbl.find_opt(registry);
};


[@react.server.function]
let withTwoFormData =
    (country: string, a: Js.FormData.t, b: Js.FormData.t)
    : Js.Promise.t(string) => {
  let _ = (a, b);
  Lwt.return(country);
};
