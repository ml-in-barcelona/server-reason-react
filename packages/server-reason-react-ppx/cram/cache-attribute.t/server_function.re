module FunctionReferences: ReactServerDOM.FunctionReferences = {
  type t = Hashtbl.t(string, ReactServerDOM.server_function);

  let registry = Hashtbl.create(10);
  let register = Hashtbl.add(registry);
  let get = Hashtbl.find_opt(registry);
};

let calls = ref(0);

[@react.server.function]
[@cache {ttl: 30., tags: [`User(id)]}]
let viewer = (~id: int): Js.Promise.t(string) => {
  incr(calls);
  Lwt.return("viewer-" ++ string_of_int(id));
};

let call_from_client = id =>
  switch (FunctionReferences.get(viewer.id)) {
  | Some(Body(handler)) => handler([|`Int(id)|])
  | _ => failwith("viewer is not registered")
  };

let () =
  Lwt_main.run({
    let%lwt _ = viewer.call(~id=1);
    let%lwt _ = call_from_client(1);
    let%lwt _ = call_from_client(2);
    React.Cache.expire(~tag=`User(1));
    let%lwt _ = call_from_client(1);
    print_endline("server function calls: " ++ string_of_int(calls^));
    Lwt.return();
  });
