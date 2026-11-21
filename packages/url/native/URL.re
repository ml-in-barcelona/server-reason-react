module SearchParams = {
  type value = list(string);
  let joinValue = value => String.concat(",", value);

  type t = list((string, value));

  let stripLeadingQuestionMark = str =>
    if (String.length(str) > 0 && str.[0] == '?') {
      String.sub(str, 1, String.length(str) - 1);
    } else {
      str;
    };

  let makeExn = str => {
    switch (stripLeadingQuestionMark(str)) {
    | "" => []
    | str => Uri.query_of_encoded(str)
    };
  };

  let make = str => {
    Some(makeExn(str));
  };

  let makeWithArray = (arr): t => {
    arr |> Array.map(((key, values)) => (key, [values])) |> Array.to_list;
  };

  let append = (t: t, key, value) => {
    List.append(t, [(key, [value])]);
  };

  let delete = (t: t, string) => {
    List.filter(((key, _value)) => key != string, t);
  };

  let rec set = (t, newKey, newValue) =>
    switch (t) {
    | [] => [(newKey, [newValue])]
    | [(key, _), ...rest] when key == newKey => [
        (key, [newValue]),
        ...delete(rest, newKey),
      ]
    | [pair, ...rest] => [pair, ...set(rest, newKey, newValue)]
    };

  let forEach = (t, fn) => {
    List.iter(
      ((key, value)) => {
        let value = joinValue(value);
        fn(value, key);
      },
      t,
    );
  };

  let get = (t, string) => {
    List.find_map(
      ((key, value)) =>
        if (key == string) {
          Some(joinValue(value));
        } else {
          None;
        },
      t,
    );
  };

  let getAll = (t: t, string) => {
    let values =
      List.find_map(
        ((key, value)) =>
          if (key == string) {
            Some(value);
          } else {
            None;
          },
        t,
      );

    switch (values) {
    | Some(values) => Array.of_list(values)
    | None => [||]
    };
  };

  let has = (t, string) => get(t, string) != None;

  let keys = t => List.map(((key, _value)) => key, t) |> Array.of_list;

  let entries = (t: t) => {
    let values = List.map(((key, value)) => (key, joinValue(value)), t);
    switch (values) {
    | [] => [||]
    | values => Array.of_list(values)
    };
  };

  let sort = t => {
    List.sort(((keyA, _), (keyB, _)) => String.compare(keyA, keyB), t);
  };

  let values = (t: t) => {
    let values: list(string) =
      List.map(((_key: string, value)) => value, t) |> List.concat;
    switch (values) {
    | [] => [||]
    | values => Array.of_list(values)
    };
  };

  let toString = t => {
    Uri.encoded_of_query(t);
  };
};

type t = Uri.t;

let makeExn = str => {
  let uri = Uri.of_string(str);
  if (Uri.empty == uri) {
    raise(Invalid_argument("Invalid URL"));
  } else {
    uri;
  };
};

let make = str => {
  switch (makeExn(str)) {
  | url => Some(url)
  | exception (Invalid_argument(_)) => None
  };
};

let makeWith = (str, ~base: string) => {
  let baseUri = Uri.of_string(base);
  Uri.resolve("", baseUri, Uri.of_string(str));
};

let host = url => {
  switch (Uri.host(url), Uri.port(url)) {
  | (Some(host), Some(port)) => Some(host ++ ":" ++ Int.to_string(port))
  | (Some(host), None) => Some(host)
  | (None, None)
  | (None, _) => None
  };
};

let setHost = (url, host) => {
  Uri.with_host(url, Some(host));
};
let hostname = url => {
  switch (Uri.host(url)) {
  | Some(host) => host
  | None => ""
  };
};
let setHostname = (t, string) => {
  Uri.with_host(t, Some(string));
};
let href = url => {
  Uri.to_string(url);
};
let setHref = (t, _string) => {
  t;
};
let password = url =>
  switch (Uri.password(url)) {
  | Some("") => None
  | None => None
  | Some(password) => Some(password)
  };
let setPassword = (url, password) => {
  Uri.with_password(url, Some(password));
};
let pathname = url => Uri.path(url);
let setPathname = (t, string) => {
  Uri.with_path(t, string);
};
let port = url => {
  switch (Uri.port(url)) {
  | Some(port) => Some(Int.to_string(port))
  | None => None
  };
};
let setPort = (t, string) => {
  switch (int_of_string_opt(string)) {
  | Some(port) => Uri.with_port(t, Some(port))
  | None => t
  };
};
let protocol = url => {
  switch (Uri.scheme(url)) {
  | Some(scheme) => Some(scheme ++ ":")
  | None => None
  };
};
let setProtocol = (t, string) => {
  Uri.with_scheme(t, Some(string));
};
let search = url => {
  let scheme = Option.value(~default="", protocol(url));
  let query = Uri.query(url);
  switch (query) {
  | [] => None
  | _ => Some("?" ++ Uri.encoded_of_query(~scheme, query))
  };
};
let setSearchAsString = (t, searchString) => {
  Uri.with_query(
    t,
    Uri.query_of_encoded(
      SearchParams.stripLeadingQuestionMark(searchString),
    ),
  );
};
let setSearch = Uri.with_query;

let searchParams = (url): SearchParams.t => {
  let query = Uri.query(url);
  query;
};
let username = url => {
  switch (Uri.user(url)) {
  | None => None
  | Some(user) when user == "" => None
  | Some(user) => Some(user)
  };
};
let setUsername = (t, string) => {
  Uri.with_userinfo(t, Some(string));
};
let hash = url => {
  switch (Uri.fragment(url)) {
  | Some(fragment) => Some("#" ++ fragment)
  | None => None
  };
};
let setHash = (t, string) => {
  Uri.with_fragment(t, Some(string));
};

let origin = t => {
  switch (protocol(t), host(t)) {
  | (None, _)
  | (_, None) => None
  | (Some(protocol), Some(host)) => Some(protocol ++ "//" ++ host)
  };
};

let toString = url => Uri.to_string(url);
