include Melange_json.Primitives;

[@react.server.function]
let simpleResponse = (~name: string, ~age: int): Js.Promise.t(string) => {
  Lwt.return(Printf.sprintf("Hello %s, you are %d years old", name, age));
};

[@react.server.function]
let otherServerFunction = (~name: string, ()): Js.Promise.t(string) => {
  Lwt.return(Printf.sprintf("Hello, %s", name));
};

[@react.server.function]
let anotherServerFunction = (): Js.Promise.t(string) => {
  Lwt.return("Hello, world!");
};

let _ = simpleResponseRouteHandler;
let _ = otherServerFunctionRouteHandler;
let _ = anotherServerFunctionRouteHandler;
