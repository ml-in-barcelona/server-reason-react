module URLSearchParams: {
  type t;

  let make: string => t;
  /* [@mel.new] let makeWithDict: Js.Dict.t(string) => t; */
  let makeWithArray: array((string, string)) => t;
  let append: (t, string, string) => unit;
  let delete: (t, string) => unit;
  let entries: t => array((string, string));
  let forEach: (t, (string, string) => unit) => unit;
  let get: (t, string) => option(string);
  let getAll: (t, string) => array(string);
  let has: (t, string) => bool;
  let keys: t => array(string);
  let set: (t, string, string) => unit;
  let sort: t => unit;
  let toString: t => string;
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
