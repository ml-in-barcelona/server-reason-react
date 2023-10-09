module URLSearchParams = {
  type t;

  [@mel.new] external make: string => t = "URLSearchParams";
  /* [@mel.new] external makeWithDict: Js.Dict.t(string) => t = "URLSearchParams"; */
  [@mel.new]
  external makeWithArray: array((string, string)) => t = "URLSearchParams";
  [@mel.send] external append: (t, string, string) => unit = "append";
  [@mel.send] external delete: (t, string) => unit = "delete";
  [@mel.send] external entries: t => array((string, string)) = "entries";
  [@mel.send]
  external forEach: (t, [@mel.uncurry] ((string, string) => unit)) => unit =
    "forEach";
  [@mel.return nullable] [@mel.send]
  external get: (t, string) => option(string) = "get";
  [@mel.send] external getAll: (t, string) => array(string) = "getAll";
  [@mel.send] external has: (t, string) => bool = "has";
  [@mel.send] external keys: t => array(string) = "keys";
  [@mel.send] external set: (t, string, string) => unit = "set";
  [@mel.send] external sort: t => unit = "sort";
  [@mel.send] external toString: t => string = "toString";
  [@mel.send] external values: t => array(string) = "values";
};

type t;

[@mel.new] external make: string => t = "URL";

[@mel.new] external makeWith: (string, ~base: string) => t = "URL";

[@mel.get] external hash: t => string = "hash";
[@mel.set] external setHash: (t, string) => unit = "hash";
[@mel.get] external host: t => string = "host";
[@mel.set] external setHost: (t, string) => unit = "host";
[@mel.get] external hostname: t => string = "hostname";
[@mel.set] external setHostname: (t, string) => unit = "hostname";
[@mel.get] external href: t => string = "href";
[@mel.set] external setHref: (t, string) => unit = "href";
[@mel.get] external origin: t => string = "origin";
[@mel.get] external password: t => string = "password";
[@mel.set] external setPassword: (t, string) => unit = "password";
[@mel.get] external pathname: t => string = "pathname";
[@mel.set] external setPathname: (t, string) => unit = "pathname";
[@mel.get] external port: t => string = "port";
[@mel.set] external setPort: (t, string) => unit = "port";
[@mel.get] external protocol: t => string = "protocol";
[@mel.set] external setProtocol: (t, string) => unit = "protocol";
[@mel.get] external search: t => string = "search";
[@mel.set] external setSearch: (t, string) => unit = "search";
[@mel.get] external searchParams: t => URLSearchParams.t = "searchParams";
[@mel.get] external username: t => string = "username";
[@mel.set] external setUsername: (t, string) => unit = "username";
[@mel.send] external toJson: (t, unit) => string = "toJSON";

/* @val @scope("URL") external createObjectURL: Webapi__File.t => string = "createObjectURL" */
/* @val @scope("URL") external createObjectURLFromBlob: Webapi__Blob.t => string = "createObjectURL" */
/* @val @scope("URL") external revokeObjectURL: string => unit = "revokeObjectURL" */
