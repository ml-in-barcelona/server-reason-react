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
let withOptionalArg = (~name: option(string)=?, ()): Js.Promise.t(string) => {
  let name =
    switch (name) {
    | Some(name) => name
    | None => "Lola"
    };
  Lwt.return(Printf.sprintf("Hello, %s", name));
};

[@react.server.function]
let withOptionalDefaultArg = (~name: string="Lola", ()): Js.Promise.t(string) => {
  Lwt.return(Printf.sprintf("Hello, %s", name));
};

[@react.server.function]
let withUnlabeledArg = (name: string, age: int): Js.Promise.t(string) => {
  Lwt.return(Printf.sprintf("Hello %s, you are %d years old", name, age));
};

[@react.server.function]
let withNoArgs = (): Js.Promise.t(string) => {
  Lwt.return("Hello, world!");
};

[@react.server.function]
let withFormData = (formData: Js.FormData.t): Js.Promise.t(string) => {
  let name =
    Js.FormData.get(formData, "name")
    |> (
      fun
      | `String(name) => name
    );
  let age =
    Js.FormData.get(formData, "age")
    |> (
      fun
      | `String(age) => age
    );
  Lwt.return(Printf.sprintf("Hello %s, you are %s years old", name, age));
};

[@react.server.function]
let withFormDataArgs =
    (country: string, formData: Js.FormData.t): Js.Promise.t(string) => {
  let name =
    Js.FormData.get(formData, "name")
    |> (
      fun
      | `String(name) => name
    );
  let country = country;
  Lwt.return(Printf.sprintf("Hello %s, you are from %s", name, country));
};

[@react.server.function]
let withFormDataLabelledAndUnlabeledArgs =
    (country: string, ~formData: Js.FormData.t): Js.Promise.t(string) => {
  let name =
    Js.FormData.get(formData, "name")
    |> (
      fun
      | `String(name) => name
    );
  let country = country;
  Lwt.return(Printf.sprintf("Hello %s, you are from %s", name, country));
};

[@react.server.function]
let withFormDataLabelledAndLabelledArgs =
    (~country: string, ~formData: Js.FormData.t): Js.Promise.t(string) => {
  let name =
    Js.FormData.get(formData, "name")
    |> (
      fun
      | `String(name) => name
    );
  let country = country;
  Lwt.return(Printf.sprintf("Hello %s, you are from %s", name, country));
};

[@react.server.function]
let withFormDataUnlabelledAndLabelledArgs =
    (~country: string, formData: Js.FormData.t): Js.Promise.t(string) => {
  let name =
    Js.FormData.get(formData, "name")
    |> (
      fun
      | `String(name) => name
    );
  let country = country;
  Lwt.return(Printf.sprintf("Hello %s, you are from %s", name, country));
};

[@react.server.function]
let withFormDataAndArgsDifferentOrder =
    (formData: Js.FormData.t, country: string): Js.Promise.t(string) => {
  let name =
    Js.FormData.get(formData, "name")
    |> (
      fun
      | `String(name) => name
    );
  let country = country;
  Lwt.return(Printf.sprintf("Hello %s, you are from %s", name, country));
};

[@react.server.function]
let withReturnTypeOnSeparateLine =
    (~name: string, ~age: int): Js.Promise.t(string) => {
  Lwt.return(Printf.sprintf("Hello %s, you are %d years old", name, age));
};

[@react.server.function]
let withCharArg = (~letter: char): Js.Promise.t(string) => {
  Js.Promise.resolve(String.make(1, letter));
};

[@react.server.function]
let withResultArg = (~result: result(string, string)): Js.Promise.t(string) => {
  switch (result) {
  | Ok(s) => Js.Promise.resolve(s)
  | Error(e) => Js.Promise.resolve(e)
  };
};

[@react.server.function]
let withTuple2Arg = (~pair: (string, int)): Js.Promise.t(string) => {
  let (name, age) = pair;
  Js.Promise.resolve(Printf.sprintf("Hello %s, you are %d years old", name, age));
};

[@react.server.function]
let withTuple5Arg =
    (~data: (string, int, float, bool, char)): Js.Promise.t(string) => {
  let (name, _age, _score, _active, _letter) = data;
  Js.Promise.resolve(name);
};

[@react.server.function]
let withTuple6Arg =
    (~data: (string, int, float, bool, char, int64)): Js.Promise.t(string) => {
  let (name, _age, _score, _active, _letter, _id) = data;
  Js.Promise.resolve(name);
};

[@react.server.function]
let withBoolArg = (~flag: bool): Js.Promise.t(string) => {
  Js.Promise.resolve(flag ? "yes" : "no");
};

[@react.server.function]
let withFloatArg = (~score: float): Js.Promise.t(string) => {
  Js.Promise.resolve(Js.Float.toString(score));
};

[@react.server.function]
let withInt64Arg = (~big: int64): Js.Promise.t(string) => {
  Js.Promise.resolve(Int64.to_string(big));
};

[@react.server.function]
let withListArg = (~names: list(string)): Js.Promise.t(string) => {
  Js.Promise.resolve(String.concat(", ", names));
};

[@react.server.function]
let withArrayArg = (~ids: array(int)): Js.Promise.t(string) => {
  Js.Promise.resolve(string_of_int(Array.length(ids)));
};

[@react.server.function]
let withOptionIntArg = (~count: option(int)=?, ()): Js.Promise.t(string) => {
  switch (count) {
  | Some(n) => Js.Promise.resolve(string_of_int(n))
  | None => Js.Promise.resolve("none")
  };
};

[@react.server.function]
let withNestedListOptionArg = (~items: list(option(string))): Js.Promise.t(string) => {
  let _ = items;
  Js.Promise.resolve("ok");
};

[@react.server.function]
let withNestedResultListArg = (~data: result(list(int), string)): Js.Promise.t(string) => {
  let _ = data;
  Js.Promise.resolve("ok");
};
