module URLSearchParams: {
  type t;

  let make: string => t;
  let makeWithDict: Js.Dict.t(string) => t;
  let makeWithArray: array((string, string)) => t;
  let append: (t, string, string) => t;
  let delete: (t, string) => t;
  let entries: t => array((string, string));
  let forEach: (t, (string, string) => unit) => unit; /* Unsure about unit as returnable */
  let get: (t, string) => option(string);
  let getAll: (t, string) => array(string);
  let has: (t, string) => bool;
  let keys: t => array(string);
  let set: (t, string, string) => t;
  let sort: t => t;
  let toString: t => string;
  let values: t => array(string);
};

type t;

let make: string => t;

let makeWith: (string, ~base: string) => t;

let hash: t => string;
let setHash: (t, string) => t;
let host: t => string;
let setHost: (t, string) => t;
let hostname: t => string;
let setHostname: (t, string) => t;
let href: t => string;
let setHref: (t, string) => t;
let origin: t => string;
let password: t => string;
let setPassword: (t, string) => t;
let pathname: t => string;
let setPathname: (t, string) => t;
let port: t => string;
let setPort: (t, string) => t;
let protocol: t => string;
let setProtocol: (t, string) => t;
let search: t => string;
let setSearch: (t, string) => t;
let searchParams: t => URLSearchParams.t;
let username: t => string;
let setUsername: (t, string) => t;
let toJson: t => string;
let toString: t => string;
