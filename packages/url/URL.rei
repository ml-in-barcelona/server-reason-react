module URLSearchParams: {
  type t;

  [@mel.new]
  let make: string => t;
  /* [@mel.new] let makeWithDict: Js.Dict.t(string) => t; */
  [@mel.new]
  let makeWithArray: array((string, string)) => t;
  [@mel.send]
  let append: (t, string, string) => unit;
  [@mel.send]
  let delete: (t, string) => unit;
  [@mel.send]
  let entries: t => array((string, string));
  [@mel.send]
  let forEach: (t, [@mel.uncurry] ((string, string) => unit)) => unit;
  [@mel.return nullable]
  [@mel.send]
  let get: (t, string) => option(string);
  [@mel.send]
  let getAll: (t, string) => array(string);
  [@mel.send]
  let has: (t, string) => bool;
  [@mel.send]
  let keys: t => array(string);
  [@mel.send]
  let set: (t, string, string) => unit;
  [@mel.send]
  let sort: t => unit;
  [@mel.send]
  let toString: t => string;
  [@mel.send]
  let values: t => array(string);
};

type t;

let make: string => t;

let makeWith: (string, ~base: string) => t;

let hash: t => string;
let setHash: (t, string) => unit;
let host: t => string;
let setHost: (t, string) => unit;
let hostname: t => string;
let setHostname: (t, string) => unit;
let href: t => string;
let setHref: (t, string) => unit;
let origin: t => string;
let password: t => string;
let setPassword: (t, string) => unit;
let pathname: t => string;
let setPathname: (t, string) => unit;
let port: t => string;
let setPort: (t, string) => unit;
let protocol: t => string;
let setProtocol: (t, string) => unit;
let search: t => string;
let setSearch: (t, string) => unit;
let searchParams: t => URLSearchParams.t;
let username: t => string;
let setUsername: (t, string) => unit;
let toJson: (t, unit) => string;
