type parameter = {
  name: string,
  typeName: string,
};

type segment =
  | Static(string)
  | Parameter(parameter)
  | CatchAll({name: string});

type t;
type error =
  | InvalidPattern(string);
type relationship =
  | Distinct
  | Duplicate
  | Ambiguous
  | CompatiblePrefix
  | IncompatiblePrefix;

let parse: string => result(t, error);
let toString: t => string;
let segments: t => list(segment);
let parameters: t => list(parameter);
let append: (t, t) => t;
let encodeStaticSegment: string => string;
let isPrefix: (~prefix: t, t) => bool;
let specificity: t => int;
let relationship: (t, t) => relationship;
let render:
  (
    t,
    ~parameter: string => option(string),
    ~encodeStatic: string => string,
    ~encodeParameter: string => string
  ) =>
  result(string, error);
