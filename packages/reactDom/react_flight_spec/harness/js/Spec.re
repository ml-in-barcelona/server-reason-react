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

type model = value;

let model_string = value_of_string;
let model_int = value_of_int;
let model_float = value_of_float;
let model_bool = value_of_bool;
let model_null: model = value_null;
let model_list = (items: list(model)): model =>
  value_of_array(Array.of_list(items));
let dict_of_pairs = (pairs: list((string, value))): Js.Dict.t(value) => {
  let dict = Js.Dict.empty();
  List.iter(((name, item)) => Js.Dict.set(dict, name, item), pairs);
  dict;
};

let model_object = (fields: list((string, model))): model =>
  value_of_dict(dict_of_pairs(fields));

let list = (name: string, items: list(model)): prop => (
  name,
  model_list(items),
);
let object_ = (name: string, fields: list((string, model))): prop => (
  name,
  model_object(fields),
);

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

type component;

[@mel.module "react-server-dom-webpack/server"]
external registerClientReference: (unit => unit, string, string) => component =
  "registerClientReference";

[@mel.module "react"]
external createElementWithProps:
  (component, Js.Dict.t(value)) => React.element =
  "createElement";

let client_component =
    (~importModule: string, ~importName: string, ~props: list(prop)=[], ())
    : React.element => {
  let reference = registerClientReference(() => (), importModule, importName);
  createElementWithProps(reference, dict_of_pairs(props));
};

[@mel.module "react"]
external createHostElementWithProps:
  (string, Js.Dict.t(value)) => React.element =
  "createElement";

let form_with_action =
    (~action: server_function, children: React.element): React.element =>
  createHostElementWithProps(
    "form",
    dict_of_pairs([
      ("children", value_of_element(children)),
      ("action", value_of_server_function(action)),
    ]),
  );

let with_name: (string, unit => Js.Promise.t(React.element)) => component = [%mel.raw
  {|
  (name, fn) => Object.defineProperty((_props) => fn(), "name", { value: name })
|}
];

let async_component =
    (~name: string, fn: unit => Js.Promise.t(React.element)): React.element =>
  createElementWithProps(with_name(name, fn), Js.Dict.empty());

let delay_ms: int => Js.Promise.t(unit) = [%mel.raw
  {|
  (ms) => new Promise((resolve) => setTimeout(resolve, ms))
|}
];

let delay = (~ms: int): Js.Promise.t(unit) => delay_ms(ms);

[@mel.module "react-dom"]
external react_dom_preload: (string, Js.Dict.t(string)) => unit = "preload";

let preload = (~href: string, ~as_: string, ()) => {
  let options = Js.Dict.empty();
  Js.Dict.set(options, "as", as_);
  react_dom_preload(href, options);
};

[@mel.module "react-dom"]
external react_dom_preconnect: string => unit = "preconnect";

let preconnect = (~href: string) => react_dom_preconnect(href);

[@mel.module "react-dom"]
external react_dom_prefetch_dns: string => unit = "prefetchDNS";

let prefetch_dns = (~href: string) => react_dom_prefetch_dns(href);

[@mel.module "react-dom"]
external react_dom_preinit: (string, Js.Dict.t(string)) => unit = "preinit";

let preinit_script = (~href: string) => {
  let options = Js.Dict.empty();
  Js.Dict.set(options, "as", "script");
  react_dom_preinit(href, options);
};
