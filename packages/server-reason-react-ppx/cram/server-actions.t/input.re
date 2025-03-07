// Simple action
[@react.server.action]
let some_action = (~a: string, ~b: int): Js.Promise.t(string) => {
  Promise.resolve(a ++ string_of_int(b));
};

// Simple action with default value
[@react.server.action]
let some_action_with_default = (~a: string, ~b: int=10): Js.Promise.t(string) => {
  Promise.resolve(a ++ string_of_int(b));
};

// Simple action with renamed argument
[@react.server.action]
let some_action = (~a: string, ~b as c: int): Js.Promise.t(string) => {
  Promise.resolve(a ++ string_of_int(c));
};

// Nested module
module Nested = {
  [@react.server.action]
  let some_action = (~a: string, ~b: int): Js.Promise.t(string) => {
    Promise.resolve(a ++ string_of_int(b));
  };
};

// With wrong return type
[@react.server.action]
let some_action = (~a: string, ~b: int): string => {
  Promise.resolve(a ++ string_of_int(b));
};

// With wrong argument
[@react.server.action]
let some_action = (a: string, ~b: int): Js.Promise.t(string) => {
  Promise.resolve(a ++ string_of_int(b));
};

[@react.server.action]
let some_action = (~a, ~b: int): Js.Promise.t(string) => {
  Promise.resolve(a ++ string_of_int(b));
};
