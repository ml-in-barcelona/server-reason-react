[@react.server.function]
let simpleResponse = (~name: string, age: int): Js.Promise.t(string) => {
  Lwt.return(Printf.sprintf("Hello %s, you are %d years old", name, age));
};

module ServerFunctions = {
  [@react.server.function]
  let otherServerFunction = (~name: string, ()): Js.Promise.t(string) => {
    Lwt.return("Hello, world!");
  };

  module Nested = {
    [@react.server.function]
    let nestedServerFunction = (): Js.Promise.t(string) => {
      Lwt.return("Hey yah!");
    };
  };
};
