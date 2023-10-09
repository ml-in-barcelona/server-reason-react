module URLSearchParams = {
  type t;

  let make = _string => assert(false);
  /* let makeWithDict = Js.Dict.t(string) => t; */
  let makeWithArray = _array => assert(false);
  let append = (_url, _string, _string) => assert(false);
  let delete = (t, string) => assert(false);
  let entries = url => assert(false);

  let forEach = (_t, _fn) => assert(false);
  let get = (t, string) => assert(false);
  let getAll = (t, string) => assert(false);
  let has = (t, string) => assert(false);
  let keys = t => assert(false);
  let set = (t, string, string) => assert(false);
  let sort = t => assert(false);
  let toString = t => assert(false);
  let values = t => assert(false);
};

type t = Uri.t;

let hash = t => assert(false);
let setHash = (t, string) => assert(false);
let make = str => {
  let uri = Uri.of_string(str);
  uri;
};

let makeWith = str => assert(false);

let host = url => {
  /* https://url.spec.whatwg.org/#dom-url-host */
  switch (Uri.host(url)) {
  | Some(host) => host
  /* If url’s host is null, then return the empty string */
  | None => ""
  };
};

let setHost = (t, string) => assert(false);
let hostname = t => assert(false);
let setHostname = (t, string) => assert(false);
let href = t => assert(false);
let setHref = (t, string) => assert(false);
let origin = t => assert(false);
let password = t => assert(false);
let setPassword = (t, string) => assert(false);
let pathname = t => assert(false);
let setPathname = (t, string) => assert(false);
let port = t => assert(false);
let setPort = (t, string) => assert(false);
let protocol = t => assert(false);
let setProtocol = (t, string) => assert(false);
let search = t => assert(false);
let setSearch = (t, string) => assert(false);
let searchParams = t => assert(false);
let username = t => assert(false);
let setUsername = (t, string) => assert(false);
let toJson = (t, unit) => assert(false);
