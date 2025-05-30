let stream_server_action = _ => ();

let streamResponse = _ => ();

let server_functions_registry:
  Hashtbl.t(string, ReactServerDOM.server_function) =
  Hashtbl.create(10);

let register = (id, function_) => {
  Hashtbl.add(server_functions_registry, id, ReactServerDOM.Body(function_));
};

let registerForm = (id, function_) => {
  Hashtbl.add(
    server_functions_registry,
    id,
    ReactServerDOM.FormData(function_),
  );
};

let get_function = (id: string) => {
  let action = Hashtbl.find(server_functions_registry, id);
  switch ((action: ReactServerDOM.server_function)) {
  | Body(handler) => handler
  | _ => assert(false)
  };
};

let get_function_form_data = (id: string) => {
  let action = Hashtbl.find(server_functions_registry, id);
  switch ((action: ReactServerDOM.server_function)) {
  | FormData(handler) => handler
  | _ => assert(false)
  };
};
