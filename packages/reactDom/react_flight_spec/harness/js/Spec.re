/* Melange implementation of the universal Spec seam.

   The same interface is implemented natively in ../native/Spec.re; case files
   under cases/shared compile against both. Keep the two signatures in sync.

   This module is bindings-level glue: the props of a client component are a
   heterogeneous JS object, so we build a Js.Dict of an abstract [value] type
   with zero-cost casts. This is the only place in the spec where such glue is
   allowed. */

type value;

external value_of_string: string => value = "%identity";
external value_of_int: int => value = "%identity";
external value_of_float: float => value = "%identity";
external value_of_bool: bool => value = "%identity";
external value_of_element: React.element => value = "%identity";
external value_of_promise: Js.Promise.t(string) => value = "%identity";

let value_null: value = [%mel.raw "null"];

type prop = (string, value);

let string = (name: string, value: string): prop => (
  name,
  value_of_string(value),
);
let int = (name: string, value: int): prop => (name, value_of_int(value));
let float = (name: string, value: float): prop => (
  name,
  value_of_float(value),
);
let bool = (name: string, value: bool): prop => (
  name,
  value_of_bool(value),
);
let json_null = (name: string): prop => (name, value_null);
let element = (name: string, value: React.element): prop => (
  name,
  value_of_element(value),
);
let promise_string = (name: string, value: Js.Promise.t(string)): prop => (
  name,
  value_of_promise(value),
);

/* An opaque component type: either a registered client reference or an async
   function component. Only ever handed back to React.createElement. */
type component;

[@mel.module "react-server-dom-webpack/server"]
external registerClientReference: (unit => unit, string, string) => component =
  "registerClientReference";

[@mel.module "react"]
external createElementWithProps:
  (component, Js.Dict.t(value)) => React.element =
  "createElement";

let props_to_dict = (props: list(prop)): Js.Dict.t(value) => {
  let dict = Js.Dict.empty();
  List.iter(((name, value)) => Js.Dict.set(dict, name, value), props);
  dict;
};

/* registerClientReference(impl, id, name) tags [impl] with
   $$id = "<id>#<name>", which the echoing client manifest in generate.mjs
   resolves back to {id, chunks: [], name}. */
let client_component =
    (~importModule: string, ~importName: string, ~props: list(prop)=[], ())
    : React.element => {
  let reference = registerClientReference(() => (), importModule, importName);
  createElementWithProps(reference, props_to_dict(props));
};

let with_name: (string, unit => Js.Promise.t(React.element)) => component = [%mel.raw
  {|
  (name, fn) => Object.defineProperty((_props) => fn(), "name", { value: name })
|}
];

/* A promise-returning function component: Flight treats the returned thenable
   exactly like an async function component. */
let async_component =
    (~name: string, fn: unit => Js.Promise.t(React.element)): React.element =>
  createElementWithProps(with_name(name, fn), Js.Dict.empty());

let delay_ms: int => Js.Promise.t(unit) = [%mel.raw
  {|
  (ms) => new Promise((resolve) => setTimeout(resolve, ms))
|}
];

let delay = (~ms: int): Js.Promise.t(unit) => delay_ms(ms);
