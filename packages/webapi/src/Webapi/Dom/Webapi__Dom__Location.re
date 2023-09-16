type t = Dom.location;

/* a more ergonomic API would perhaps accept a Window.t directly instead of Location.t */
[@mel.get] external href: t => string = "href";
[@mel.set] external setHref: (t, string) => unit = "href";
[@mel.get] external protocol: t => string = "protocol";
[@mel.set] external setProtocol: (t, string) => unit = "protocol";
[@mel.get] external host: t => string = "host";
[@mel.set] external setHost: (t, string) => unit = "host";
[@mel.get] external hostname: t => string = "hostname";
[@mel.set] external setHostname: (t, string) => unit = "hostname";
[@mel.get] external port: t => string = "port";
[@mel.set] external setPort: (t, string) => unit = "port";
[@mel.get] external pathname: t => string = "pathname";
[@mel.set] external setPathname: (t, string) => unit = "pathname";
[@mel.get] external search: t => string = "search";
[@mel.set] external setSearch: (t, string) => unit = "search";
[@mel.get] external hash: t => string = "hash";
[@mel.set] external setHash: (t, string) => unit = "hash";
[@mel.get] external username: t => string = "username";
[@mel.set] external setUsername: (t, string) => unit = "username";
[@mel.get] external password: t => string = "password";
[@mel.set] external setPassword: (t, string) => unit = "password";
[@mel.get] external origin: t => string = "origin";

[@mel.send.pipe: t] external assign: string => unit = "assign";
[@mel.send.pipe: t] external reload: unit = "reload";
[@mel.send.pipe: t]
external reloadWithForce: ([@mel.as {json|true|json}] _) => unit = "reload";
[@mel.send.pipe: t] external replace: string => unit = "replace";
[@mel.send.pipe: t] external toString: string = "toString";
