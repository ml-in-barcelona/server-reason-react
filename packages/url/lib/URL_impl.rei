/**
 [URL] module is universal and has 2 implementations with the same API:

  - [url_js] library is a wrapper around the [URL] API in the browser binded with Melange.
  - [url_native] library is a native implementation with {{:https://github.com/mirage/ocaml-uri}ocaml-uri} (RFC3986 URI parsing library for OCaml).

  {1 Setup with dune}

  Depending on you setup, you would need to add the following dependencies to your `dune` stanzas:

  {[
  (library
    (name ...)
    (modes melange)
    (libraries (server-reason-react.url_js))

  (library
    (name ...)
    (modes native)
    (libraries (server-reason-react.url_native))
  ]}

  {1 Usage}

  {[
      let url = URL.make("https://example.com:8080/path?query=1#hash");
      URL.protocol(url); (* => Some("https:") *)
      URL.hostname(url); (* => "example.com" *)
      URL.port(url); (* => Some("8080") *)
      URL.pathname(url); (* => "/path" *)
      URL.search(url); (* => Some("?query=1") *)
      URL.hash(url); (* => Some("#hash") *)
  ]}

  {1 URL.SearchParams}
*/;

module SearchParams: {
  type t;

  let makeExn: string => t;
  let make: string => option(t);
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

/**
  {1 URL}
*/;

type t;

let makeExn: string => t;
let make: string => option(t);
/* https://developer.mozilla.org/en-US/docs/Web/API/URL/canParse_static */
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
let setSearchAsString: (t, string) => t;
let setSearch: (t, SearchParams.t) => t;
let searchParams: t => SearchParams.t;
let username: t => option(string);
let setUsername: (t, string) => t;
let toString: t => string;
/*
 TODO: When we have a way to represent JSON universally, implement this
 let toJson: t => string; */
