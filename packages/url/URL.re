[@platform js]
include {
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
            external makeWithArray: array((string, string)) => t =
              "URLSearchParams";

            [@mel.send] external toString: t => string = "toString";

            [@mel.send]
            external appendInPlace: (t, string, string) => unit = "append";
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
            [@mel.send]
            external entries: t => array((string, string)) = "entries";

            [@mel.send]
            external forEach:
              (t, [@mel.uncurry] ((string, string) => unit)) => unit =
              "forEach";

            [@mel.return nullable] [@mel.send]
            external get: (t, string) => option(string) = "get";

            [@mel.send]
            external getAll: (t, string) => array(string) = "getAll";

            [@mel.send] external has: (t, string) => bool = "has";

            [@mel.send] external keys: t => array(string) = "keys";

            [@mel.send]
            external setInPlace: (t, string, string) => unit = "set";
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
            | searchParams => Some(searchParams)
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
          [@mel.set]
          external setHostnameInPlace: (t, string) => unit = "hostname";
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

          [@mel.set]
          external setPasswordInPlace: (t, string) => unit = "password";
          let setPassword = (url, newPassword) => {
            let newUrl = makeExn(toString(url));
            let () = setPasswordInPlace(newUrl, newPassword);
            newUrl;
          };

          [@mel.get] external pathname: t => string = "pathname";
          [@mel.set]
          external setPathnameInPlace: (t, string) => unit = "pathname";
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
          [@mel.set]
          external setProtocolInPlace: (t, string) => unit = "protocol";
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
          let setSearch = (url, newSearch) => {
            let newUrl = makeExn(toString(url));
            let () = setSearchInPlace(newUrl, newSearch);
            newUrl;
          };

          [@mel.get] external getUsername: t => string = "username";
          let username = url => {
            switch (getUsername(url)) {
            | "" => None
            | username => Some(username)
            };
          };
          [@mel.set]
          external setUsernameInPlace: (t, string) => unit = "username";
          let setUsername = (url, newUsername) => {
            let newUrl = makeExn(toString(url));
            let () = setUsernameInPlace(newUrl, newUsername);
            newUrl;
          };

          [@mel.get]
          external searchParams: t => SearchParams.t = "searchParams";
        };

[@platform native]
include {
          module SearchParams = {
            /* value is a list of strings on Uri, but it's represented as string on the browser
               we keep the type as a list, but each method it needs the value we "joinValue" */
            type value = list(string);
            let joinValue = value => String.concat("", value);

            type t = list((string, value));

            let makeExn = str => {
              switch (str) {
              | "" => []
              | _ => Uri.query_of_encoded(str)
              };
            };

            let make = str => {
              Some(makeExn(str));
            };

            /* let makeWithDict = _dict => assert(false); */

            let makeWithArray = (arr): t => {
              arr
              |> Array.map(((key, values)) => (key, [values]))
              |> Array.to_list;
            };

            let append = (t: t, key, value) => {
              List.append(t, [(key, [value])]);
            };

            let delete = (t: t, string) => {
              List.filter(((key, _value)) => key != string, t);
            };

            let set = (t, newKey, newValue) => {
              List.map(
                ((key, value)) =>
                  if (key == newKey) {
                    (key, [newValue]);
                  } else {
                    (key, value);
                  },
                t,
              );
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
                    List.nth_opt(value, 0);
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

            let keys = t =>
              List.map(((key, _value)) => key, t) |> Array.of_list;

            let entries = (t: t) => {
              let values =
                List.map(((key, value)) => (key, joinValue(value)), t);
              switch (values) {
              | [] => [||]
              | values => Array.of_list(values)
              };
            };

            let sort = t => {
              List.sort(
                ((keyA, _), (keyB, _)) => String.compare(keyA, keyB),
                t,
              );
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
              /* TODO: raise(Js.Exn.raiseTypeError) when is implemented in Js.ml */
              raise(
                Invalid_argument("Invalid URL"),
              );
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
            let absolute = Uri.with_uri(~path=Some(str), baseUri);
            Uri.resolve(str, baseUri, absolute);
          };

          let host = url => {
            /* https://url.spec.whatwg.org/#dom-url-host */
            switch (Uri.host(url), Uri.port(url)) {
            | (Some(host), Some(port)) =>
              Some(host ++ ":" ++ string_of_int(port))
            | (Some(host), None) => Some(host)
            /* If url’s host is null, then return the empty string */
            | (None, None)
            | (None, _) => None
            };
          };

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
          let setHostname = (t, string) => {
            Uri.with_host(t, Some(string));
          };
          let href = url => {
            Uri.to_string(url);
          };
          let setHref = (t, _string) => {
            /* TODO: Unsure what to do here. Setting the href should update hostname, port, userinfo, etc. It seems like search params don't update. */
            t;
          };
          let password = url =>
            /* https://url.spec.whatwg.org/#concept-url-password */
            switch (Uri.password(url)) {
            /* Password can be empty, when is parsed with a username, but we normalise it to None */
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
          /* TODO: Return result? or optional Maybe int_of_string fails */
          let setPort = (t, string) => {
            Uri.with_port(t, Some(int_of_string(string)));
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
          let setSearch = (t, string) => {
            Uri.with_query(t, Uri.query_of_encoded(string));
          };
          let searchParams = _url => assert(false);
          let username = url => {
            switch (Uri.user(url)) {
            /* User can be empty, if the Uri has a password is parsed as Some(""),
               which isn't wrong, but we normalise it to option */
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
            /* https://url.spec.whatwg.org/#dom-url-origin */
            switch (protocol(t), host(t)) {
            | (None, _)
            | (_, None) => None
            | (Some(protocol), Some(host)) =>
              Some(protocol ++ "//" ++ host)
            };
          };

          /*
           TODO: When we have a way to represent JSON universally, implement this.
           It could be yojson or a custom json type
           let toJson = url => assert(false); */
          let toString = url => Uri.to_string(url);
        };
