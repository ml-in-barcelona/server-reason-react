module URLSearchParams = {
  type t;

  [@mel.new] external make: string => t = "URLSearchParams";
  [@mel.new]
  external makeWithDict: Js.Dict.t(string) => t = "URLSearchParams";
  [@mel.new]
  external makeWithArray: array((string, string)) => t = "URLSearchParams";
  [@mel.send] external toString: t => string = "toString";
  [@mel.send] external appendInPlace: (t, string, string) => unit = "append";
  let append = (searchParams, key, value) => {
    assert(false);
  };
  [@mel.send] external deleteInPlace: (t, string) => unit = "delete";
  let delete = (searchParams, key) => {
    assert(false);
  };
  [@mel.send] external entries: t => array((string, string)) = "entries";
  [@mel.send]
  external forEach: (t, [@mel.uncurry] ((string, string) => unit)) => unit =
    "forEach";
  [@mel.return nullable] [@mel.send]
  external get: (t, string) => option(string) = "get";
  [@mel.send] external getAll: (t, string) => array(string) = "getAll";
  [@mel.send] external has: (t, string) => bool = "has";
  [@mel.send] external keys: t => array(string) = "keys";
  [@mel.send] external setInPlace: (t, string, string) => unit = "set";
  let set = (searchParams, key, value) => {
    assert(false);
  };
  [@mel.send] external sortInPlace: t => unit = "sort";
  let sort = searchParams => {
    let newSearchParams = make(toString(searchParams));
    let () = sortInPlace(newSearchParams);
    newSearchParams;
  };
  [@mel.send] external values: t => array(string) = "values";
};

type t;

[@mel.new] external make: string => t = "URL";
[@mel.new] external makeWith: (string, ~base: string) => t = "URL";

[@mel.send] external toJson: t => string = "toJSON";
[@mel.send] external toString: t => string = "toString";

[@mel.get] external origin: t => string = "origin";

[@mel.get] external hash: t => string = "hash";
[@mel.set] external setHashInPlace: (t, string) => unit = "hash";
let setHash = (url, newHash) => {
  let newUrl = make(toString(url));
  let () = setHashInPlace(newUrl, newHash);
  newUrl;
};

[@mel.get] external host: t => string = "host";
[@mel.set] external setHostInPlace: (t, string) => unit = "host";
let setHost = (url, newHost) => {
  let newUrl = make(toString(url));
  let () = setHostInPlace(newUrl, newHost);
  newUrl;
};

[@mel.get] external hostname: t => string = "hostname";
[@mel.set] external setHostnameInPlace: (t, string) => unit = "hostname";
let setHostname = (url, newHostname) => {
  let newUrl = make(toString(url));
  let () = setHostnameInPlace(newUrl, newHostname);
  newUrl;
};

[@mel.get] external href: t => string = "href";
[@mel.set] external setHrefInPlace: (t, string) => unit = "href";
let setHref = (url, newHref) => {
  let newUrl = make(toString(url));
  let () = setHrefInPlace(newUrl, newHref);
  newUrl;
};

[@mel.get] external password: t => string = "password";
[@mel.set] external setPasswordInPlace: (t, string) => unit = "password";
let setPassword = (url, newPassword) => {
  let newUrl = make(toString(url));
  let () = setPasswordInPlace(newUrl, newPassword);
  newUrl;
};

[@mel.get] external pathname: t => string = "pathname";
[@mel.set] external setPathnameInPlace: (t, string) => unit = "pathname";
let setPathname = (url, newPathname) => {
  let newUrl = make(toString(url));
  let () = setPathnameInPlace(newUrl, newPathname);
  newUrl;
};

[@mel.get] external port: t => string = "port";
[@mel.set] external setPortInPlace: (t, string) => unit = "port";
let setPort = (url, newPort) => {
  let newUrl = make(toString(url));
  let () = setPortInPlace(newUrl, newPort);
  newUrl;
};

[@mel.get] external protocol: t => string = "protocol";
[@mel.set] external setProtocolInPlace: (t, string) => unit = "protocol";
let setProtocol = (url, newProtocol) => {
  let newUrl = make(toString(url));
  let () = setProtocolInPlace(newUrl, newProtocol);
  newUrl;
};

[@mel.get] external search: t => string = "search";
[@mel.set] external setSearchInPlace: (t, string) => unit = "search";
let setSearch = (url, newSearch) => {
  let newUrl = make(toString(url));
  let () = setSearchInPlace(newUrl, newSearch);
  newUrl;
};

[@mel.get] external username: t => string = "username";
[@mel.set] external setUsernameInPlace: (t, string) => unit = "username";
let setUsername = (url, newUsername) => {
  let newUrl = make(toString(url));
  let () = setUsernameInPlace(newUrl, newUsername);
  newUrl;
};

[@mel.get] external searchParams: t => URLSearchParams.t = "searchParams";
