type parameter = {
  name: string,
  typeName: string,
};

type segment =
  | Static(string)
  | Parameter(parameter);

type t;
type error =
  | InvalidPattern(string);

let parse: string => result(t, error);
let toString: t => string;
let segments: t => list(segment);
let parameters: t => list(parameter);
let append: (t, t) => t;
let isPrefix: (~prefix: t, t) => bool;
let render:
  (t, ~parameter: string => option(string), ~encode: string => string) =>
  result(string, error);
