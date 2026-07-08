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
external value_of_element_promise: Js.Promise.t(React.element) => value =
  "%identity";
external value_of_array: array(value) => value = "%identity";
external value_of_dict: Js.Dict.t(value) => value = "%identity";

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
let promise_element =
    (name: string, value: Js.Promise.t(React.element)): prop => (
  name,
  value_of_element_promise(value),
);

/* Value-level constructors, for nesting inside array/object props. */
type model = value;

let model_string = value_of_string;
let model_int = value_of_int;
let model_float = value_of_float;
let model_bool = value_of_bool;
let model_null: model = value_null;
let model_list = (items: list(model)): model =>
  value_of_array(Array.of_list(items));
let model_object = (fields: list((string, model))): model => {
  let dict = Js.Dict.empty();
  List.iter(((name, item)) => Js.Dict.set(dict, name, item), fields);
  value_of_dict(dict);
};

let list = (name: string, items: list(model)): prop => (
  name,
  model_list(items),
);
let object_ = (name: string, fields: list((string, model))): prop => (
  name,
  model_object(fields),
);

/* A server function reference: registerServerReference(fn, id, null) tags
   [fn] with $$id = "<id>" (no export-name suffix when the third argument is
   null), which Flight serializes as an outlined {"id","bound"} row plus a
   "$F<hexid>" reference — no server manifest involved. Created once and
   reused so that cases can exercise React's per-reference dedup
   (writtenServerReferences). */
type server_function;

[@mel.module "react-server-dom-webpack/server"]
external registerServerReference:
  (unit => Js.Promise.t(unit), string, Js.null(string)) => server_function =
  "registerServerReference";

external value_of_server_function: server_function => value = "%identity";

let server_function = (~id: string): server_function =>
  registerServerReference(() => Js.Promise.resolve(), id, Js.null);

let server_function_prop = (name: string, fn: server_function): prop => (
  name,
  value_of_server_function(fn),
);

let model_server_function = (fn: server_function): model =>
  value_of_server_function(fn);

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

[@mel.module "react"]
external createHostElementWithProps:
  (string, Js.Dict.t(value)) => React.element =
  "createElement";

/* A <form> host element with a server function as its [action] prop. Typed
   JSX cannot express this single-source (the native ppx takes a polymorphic
   variant, reason-react a string), so both harnesses build the element
   directly. [children] goes first in the props object: srr's model
   serializer prepends the children prop, and JSX (both runtimes) also puts
   children before the other props. */
let form_with_action =
    (~action: server_function, children: React.element): React.element => {
  let props = Js.Dict.empty();
  Js.Dict.set(props, "children", value_of_element(children));
  Js.Dict.set(props, "action", value_of_server_function(action));
  createHostElementWithProps("form", props);
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
