module SearchParams: {
  type t;

  let makeExn: string => t;
  let make: string => option(t);
  /* let makeWithDict: Js.Dict.t(string) => t; */
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

let makeExn: string => t;
let make: string => option(t);
let makeWith: (string, ~base: string) => t;

let hash: t => option(string);
let setHash: (t, string) => t;
let host: t => option(string);
let setHost: (t, string) => t;
let hostname: t => string;
let setHostname: (t, string) => t;
let href: t => string;
let setHref: (t, string) => t;
let origin: t => option(string);
let password: t => option(string);
let setPassword: (t, string) => t;
let pathname: t => string;
let setPathname: (t, string) => t;
let port: t => option(string);
let setPort: (t, string) => t;
let protocol: t => option(string);
let setProtocol: (t, string) => t;
let search: t => option(string);
let setSearch: (t, string) => t;
let searchParams: t => SearchParams.t;
let username: t => option(string);
let setUsername: (t, string) => t;
/*
 TODO: When we have a way to represent JSON universally, implement this
 let toJson: t => string; */
let toString: t => string;
