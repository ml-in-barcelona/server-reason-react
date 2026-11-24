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

/** Parses a concrete pattern. Rejects optional segments. */
let parse: string => result(t, error);

/** Parses a route declaration path. Accepts optional segments
    ([:name?<type>] and a final [:name?<string...>]). */
let parseTemplate: string => result(t, error);
let toString: t => string;
let segments: t => list(segment);
let parameters: t => list(parameter);

/** Names of the optional segments. */
let optional: t => list(string);

/** Every concrete pattern a template matches: each optional segment present
    or absent. The first shape has every optional segment present. */
let shapes: t => list(t);
let append: (t, t) => t;

/** Whether [pathname], a percent-encoded URL path without search or hash,
    has the shape of [pattern]. Static segments compare after decoding. A
    parameter matches one non-empty segment without parsing its type. A
    catch-all matches one or more remaining segments. A template matches when
    any of its {!shapes} does. A segment matches only if the server would
    accept it: no empty segment, [.], [..], encoded slash, control
    character or invalid UTF-8.

    [basePath] is the router's percent-encoded base path (default ["/"]). The
    leading segments of [pathname] must equal its segments after decoding,
    and [pattern] matches the rest. */
let matchesPath: (~basePath: string=?, t, string) => bool;
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
