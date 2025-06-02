include Melange_json.Primitives;

module FunctionReferences: ReactServerDOM.FunctionReferences = {
  type t = Hashtbl.t(string, ReactServerDOM.server_function);

  let registry = Hashtbl.create(10);
  let register = Hashtbl.add(registry);
  let get = Hashtbl.find_opt(registry);
};

[@react.server.function]
let withLabelledArg = (~name: string, ~age: int): Js.Promise.t(string) => {
  Lwt.return(Printf.sprintf("Hello %s, you are %d years old", name, age));
};

[@react.server.function]
let withLabelledArgAndUnlabeledArg =
    (~name: string="Lola", age: int): Js.Promise.t(string) => {
  Lwt.return(Printf.sprintf("Hello %s, you are %d years old", name, age));
};

[@react.server.function]
let withOptionalArg = (~name: string="Lola", ()): Js.Promise.t(string) => {
  Lwt.return(Printf.sprintf("Hello, %s", name));
};

[@react.server.function]
let withNoArgs = (): Js.Promise.t(string) => {
  Lwt.return("Hello, world!");
};
