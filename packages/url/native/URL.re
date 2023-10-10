module URLSearchParams = {
  type t;

  let make = _string => assert(false);
  let makeWithDict = _dict => assert(false);
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

let make = str => {
  let uri = Uri.of_string(str);
  uri;
};

let makeWith = (str, ~base: string) => assert(false);

let host = url => {
  /* https://url.spec.whatwg.org/#dom-url-host */
  switch (Uri.host(url), Uri.port(url)) {
  | (Some(host), Some(port)) => host ++ ":" ++ string_of_int(port)
  | (Some(host), None) => host
  /* If url’s host is null, then return the empty string */
  | (None, None)
  /* Only containing the port isn't a valid URI */
  | (None, _) => ""
  };
};

/*
  Property    Result
  ------------------------------------------
  host        www.refulz.com:8082
  hostname    www.refulz.com
  port        8082
  protocol    http:
  pathname    index.php
  href        http://www.refulz.com:8082/index.php#tab2
  hash        #tab2
  search      ?foo=789
 */

let setHost = (url, host) => {
  Uri.with_host(url, Some(host));
};
let hostname = url => {
  /* https://url.spec.whatwg.org/#dom-url-host */
  switch (Uri.host(url)) {
  | Some(host) => host
  /* If url’s host is null, then return the empty string */
  | None => ""
  };
};
let setHostname = (t, string) => assert(false);
let href = url => {
  Uri.to_string(url);
};
let setHref = (t, string) => assert(false);
let origin = t => assert(false);
let password = url =>
  /* https://url.spec.whatwg.org/#concept-url-password */
  switch (Uri.password(url)) {
  | Some(password) => password
  | None => ""
  };
let setPassword = (url, password) => {
  /* If password is empty, is necessary pass None? */
  Uri.with_password(
    url,
    Some(password),
  );
};
let pathname = url => Uri.path(url);
let setPathname = (t, string) => assert(false);
let port = url => {
  switch (Uri.port(url)) {
  | Some(port) => Int.to_string(port)
  | None => ""
  };
};
let setPort = (t, string) => assert(false);
let protocol = url => {
  switch (Uri.scheme(url)) {
  | Some(scheme) => scheme ++ ":"
  | None => ""
  };
};
let setProtocol = (t, string) => assert(false);
let search = url => {
  let scheme = protocol(url);
  let query = Uri.query(url);
  Uri.encoded_of_query(~scheme, query);
};
let setSearch = (t, string) => assert(false);
let searchParams = url => assert(false);
let username = url => {
  switch (Uri.user(url)) {
  | Some(user) => user
  | None => ""
  };
};
let setUsername = (t, string) => assert(false);
let hash = url => {
  switch (Uri.fragment(url)) {
  | Some(fragment) => "#" ++ fragment
  | None => ""
  };
};
let setHash = (t, string) => assert(false);

let toJson = url => assert(false);
let toString = url => Uri.to_string(url);
