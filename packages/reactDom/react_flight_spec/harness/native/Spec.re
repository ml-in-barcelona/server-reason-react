/* Native implementation of the universal Spec seam.

   The same interface is implemented for melange in ../js/Spec.re; case files
   under cases/shared compile against both. Keep the two signatures in sync. */

type prop = (string, React.model_value);

let string = (name: string, value: string): prop => (
  name,
  React.Model.Json(`String(value)),
);
let int = (name: string, value: int): prop => (
  name,
  React.Model.Json(`Int(value)),
);
let float = (name: string, value: float): prop => (
  name,
  React.Model.Json(`Float(value)),
);
let bool = (name: string, value: bool): prop => (
  name,
  React.Model.Json(`Bool(value)),
);
let json_null = (name: string): prop => (name, React.Model.Json(`Null));
let element = (name: string, value: React.element): prop => (
  name,
  React.Model.Element(value),
);

let promise_string = (name: string, value: Js.Promise.t(string)): prop => (
  name,
  React.Model.Promise(
    value,
    resolved => React.Model.Json(`String(resolved)),
  ),
);

let promise_element =
    (name: string, value: Js.Promise.t(React.element)): prop => (
  name,
  React.Model.Promise(value, resolved => React.Model.Element(resolved)),
);

/* Value-level constructors, for nesting inside array/object props. */
type model = React.model_value;

let model_string = (value: string): model =>
  React.Model.Json(`String(value));
let model_int = (value: int): model => React.Model.Json(`Int(value));
let model_float = (value: float): model => React.Model.Json(`Float(value));
let model_bool = (value: bool): model => React.Model.Json(`Bool(value));
let model_null: model = React.Model.Json(`Null);
let model_list = (items: list(model)): model => React.Model.List(items);
let model_object = (fields: list((string, model))): model =>
  React.Model.Assoc(fields);

let list = (name: string, items: list(model)): prop => (
  name,
  model_list(items),
);
let object_ = (name: string, fields: list((string, model))): prop => (
  name,
  model_object(fields),
);

/* A server function reference. Created once and reused so that cases can
   exercise React's per-reference dedup (writtenServerReferences). */
type server_function = Runtime.server_function(unit => Js.Promise.t(unit));

let server_function = (~id: string): server_function => {
  Runtime.id,
  call: () => Js.Promise.resolve(),
};

let server_function_prop = (name: string, fn: server_function): prop => (
  name,
  React.Model.Function(fn),
);

let model_server_function = (fn: server_function): model =>
  React.Model.Function(fn);

/* A <form> host element with a server function as its [action] prop. Typed
   JSX cannot express this single-source (the native ppx takes a polymorphic
   variant, reason-react a string), so both harnesses build the element
   directly. */
let form_with_action =
    (~action: server_function, children: React.element): React.element =>
  React.Lower_case_element({
    key: None,
    tag: "form",
    attributes: [React.JSX.Action(("action", "action", action))],
    children: [children],
  });

/* [client] is the SSR fallback, unused when rendering the model. */
let client_component =
    (~importModule: string, ~importName: string, ~props: list(prop)=[], ())
    : React.element =>
  React.Client_component({
    key: None,
    import_module: importModule,
    import_name: importName,
    props,
    client: React.null,
  });

let async_component =
    (~name: string, fn: unit => Js.Promise.t(React.element)): React.element =>
  React.Async_component(name, fn);

let delay = (~ms: int): Js.Promise.t(unit) =>
  Lwt_unix.sleep(Stdlib.float_of_int(ms) /. 1000.0);
