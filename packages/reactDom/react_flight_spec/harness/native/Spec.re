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
