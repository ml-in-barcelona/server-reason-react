module SearchParams = {
  type t;
  [@mel.new] external makeExn: string => t = "URLSearchParams";

  let make = str => {
    switch (makeExn(str)) {
    | searchParams => Some(searchParams)
    | exception _ => None
    };
  };

  /* [@mel.new]
     external makeWithDict: Js.Dict.t(string) => t = "URLSearchParams"; */

  [@mel.new]
  external makeWithArray: array((string, string)) => t = "URLSearchParams";

  [@mel.send] external toString: t => string = "toString";

  [@mel.send] external appendInPlace: (t, string, string) => unit = "append";
  let append = (searchParams, key, value) => {
    let newSearchParams = makeExn(toString(searchParams));
    let _ = appendInPlace(searchParams, key, value);
    newSearchParams;
  };

  [@mel.send] external deleteInPlace: (t, string) => unit = "delete";
  let delete = (searchParams, key) => {
    let newSearchParams = makeExn(toString(searchParams));
    let _ = deleteInPlace(searchParams, key);
    newSearchParams;
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
    let newSearchParams = makeExn(toString(searchParams));
    let _ = setInPlace(searchParams, key, value);
    newSearchParams;
  };

  [@mel.send] external sortInPlace: t => unit = "sort";
  let sort = searchParams => {
    let newSearchParams = makeExn(toString(searchParams));
    let () = sortInPlace(newSearchParams);
    newSearchParams;
  };

  [@mel.send] external values: t => array(string) = "values";
};

type t;

[@mel.new] external makeExn: string => t = "URL";
[@mel.new] external makeWith: (string, ~base: string) => t = "URL";

let make = str => {
  switch (makeExn(str)) {
  | url => Some(url)
  | exception _ => None
  };
};

/*
 TODO: When we have a way to represent JSON universally, implement this. This should be "toJSON"
 [@mel.send] external toJson: t => string = "toJSON"; */
[@mel.send] external toString: t => string = "toString";

[@mel.get] external getOrigin: t => string = "origin";
let origin = url => {
  switch (getOrigin(url)) {
  | "" => None
  | origin => Some(origin)
  };
};

[@mel.get] external getHash: t => string = "hash";
let hash = url => {
  switch (getHash(url)) {
  | "" => None
  | hash => Some(hash)
  };
};

[@mel.set] external setHashInPlace: (t, string) => unit = "hash";
let setHash = (url, newHash) => {
  let newUrl = makeExn(toString(url));
  let () = setHashInPlace(newUrl, newHash);
  newUrl;
};

[@mel.get] external getHost: t => string = "host";
let host = url => {
  switch (getHost(url)) {
  | "" => None
  | host => Some(host)
  };
};

[@mel.set] external setHostInPlace: (t, string) => unit = "host";
let setHost = (url, newHost) => {
  let newUrl = makeExn(toString(url));
  let () = setHostInPlace(newUrl, newHost);
  newUrl;
};

[@mel.get] external hostname: t => string = "hostname";
[@mel.set] external setHostnameInPlace: (t, string) => unit = "hostname";
let setHostname = (url, newHostname) => {
  let newUrl = makeExn(toString(url));
  let () = setHostnameInPlace(newUrl, newHostname);
  newUrl;
};

[@mel.get] external href: t => string = "href";
[@mel.set] external setHrefInPlace: (t, string) => unit = "href";
let setHref = (url, newHref) => {
  let newUrl = makeExn(toString(url));
  let () = setHrefInPlace(newUrl, newHref);
  newUrl;
};

[@mel.get] external getPassword: t => string = "password";
let password = url => {
  switch (getPassword(url)) {
  | "" => None
  | password => Some(password)
  };
};

[@mel.set] external setPasswordInPlace: (t, string) => unit = "password";
let setPassword = (url, newPassword) => {
  let newUrl = makeExn(toString(url));
  let () = setPasswordInPlace(newUrl, newPassword);
  newUrl;
};

[@mel.get] external pathname: t => string = "pathname";
[@mel.set] external setPathnameInPlace: (t, string) => unit = "pathname";
let setPathname = (url, newPathname) => {
  let newUrl = makeExn(toString(url));
  let () = setPathnameInPlace(newUrl, newPathname);
  newUrl;
};

[@mel.get] external getPort: t => string = "port";
let port = url => {
  switch (getPort(url)) {
  | "" => None
  | port => Some(port)
  };
};
[@mel.set] external setPortInPlace: (t, string) => unit = "port";
let setPort = (url, newPort) => {
  let newUrl = makeExn(toString(url));
  let () = setPortInPlace(newUrl, newPort);
  newUrl;
};

[@mel.get] external getProtocol: t => string = "protocol";
let protocol = url => {
  switch (getProtocol(url)) {
  | "" => None
  | protocol => Some(protocol)
  };
};
[@mel.set] external setProtocolInPlace: (t, string) => unit = "protocol";
let setProtocol = (url, newProtocol) => {
  let newUrl = makeExn(toString(url));
  let () = setProtocolInPlace(newUrl, newProtocol);
  newUrl;
};

[@mel.get] external getSearch: t => string = "search";
let search = url => {
  switch (getSearch(url)) {
  | "" => None
  | search => Some(search)
  };
};
[@mel.set] external setSearchInPlace: (t, string) => unit = "search";
let setSearchAsString = (url, searchString) => {
  let newUrl = makeExn(toString(url));
  let () = setSearchInPlace(newUrl, searchString);
  newUrl;
};
let setSearch = (url, searchParams) => {
  let queryString = SearchParams.toString(searchParams);
  setSearchAsString(url, queryString);
};

[@mel.get] external getUsername: t => string = "username";
let username = url => {
  switch (getUsername(url)) {
  | "" => None
  | username => Some(username)
  };
};
[@mel.set] external setUsernameInPlace: (t, string) => unit = "username";
let setUsername = (url, newUsername) => {
  let newUrl = makeExn(toString(url));
  let () = setUsernameInPlace(newUrl, newUsername);
  newUrl;
};

[@mel.get] external searchParams: t => SearchParams.t = "searchParams";
