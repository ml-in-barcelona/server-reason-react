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

module SomeModule = {
  module Nested = {
    [@react.server.function]
    let nestedServerFunction = (): Js.Promise.t(string) => {
      Lwt.return("Hey yah!");
    };
  };
};
