  $ export OCAMLRUNPARAM=
  $ server-reason-react.router-gen --mode handles --source input.ml < input.ml > Router.ml
  $ server-reason-react.router-gen --mode interface --source input.ml < input.ml > Router_compat.mli

  $ server-reason-react.router-gen --mode handles --source catch-all-group.ml < catch-all-group.ml
  File "catch-all-group.ml", line 2, characters 4-102:
  Error: router: group path /assets/:parts<string...> cannot contain a catch-all segment
  [2]

Search parameters belong to the root or to a route. A group cannot declare them.

  $ server-reason-react.router-gen --mode handles --source group-search.ml < group-search.ml
  File "group-search.ml", line 3, characters 45-87:
  Error: router: Router.group cannot declare ~search; declare it on Router.make or on each route
  [2]

  $ server-reason-react.router-gen --mode handles --source catch-all-nonfinal.ml < catch-all-nonfinal.ml
  File "catch-all-nonfinal.ml", line 1, characters 31-96:
  Error: router: invalid route path /:parts<string...>/raw
  [2]

  $ server-reason-react.router-gen --mode registry --source catch-all-ambiguous.ml < catch-all-ambiguous.ml
  File "catch-all-ambiguous.ml", line 4, characters 4-68:
  Error: router: ambiguous route patterns /assets/:a<string...> and /assets/:b<string...>
  [2]

  $ server-reason-react.router-gen --mode registry --source catch-all-crossing.ml < catch-all-crossing.ml
  File "catch-all-crossing.ml", line 4, characters 4-84:
  Error: router: ambiguous route patterns /foo/:left<string...> and /:scope<string>/bar/:right<string...>
  [2]
  $ grep -E 'old-notes|redirect:2' Router_compat.mli
  [1]

Optional segments: `:name?<type>` and `:name?<string...>`.

  $ server-reason-react.router-gen --mode handles --source optional.ml < optional.ml > OptionalRoutes.ml
  $ server-reason-react.router-gen --mode interface --source optional.ml < optional.ml > OptionalRoutes.mli
  $ tr -s ' \n' ' ' < OptionalRoutes.mli | grep -Eo 'val (destination|href) : ([?a-z]+:[a-z ]+ -> )+unit -> [a-z]+'
  val destination : ?rest:string list -> ?hash:string -> unit -> destination
  val href : ?rest:string list -> ?hash:string -> unit -> string
  val destination : ?lang:string -> ?hash:string -> unit -> destination
  val href : ?lang:string -> ?hash:string -> unit -> string
  val destination : ?lang:string -> topic:int -> ?hash:string -> unit -> destination
  val href : ?lang:string -> topic:int -> ?hash:string -> unit -> string
  $ grep -Eo '(rest|lang|topic): [a-z ]*[a-z]' OptionalRoutes.mli | sort -u
  lang: string option
  rest: string list
  topic: int
  $ server-reason-react.router-gen --mode registry --source optional.ml < optional.ml | tr -d ' \n' | grep -Eo 'id:"[^"]*"~path:"[^"]*"~activeRoutes:\[(\("[A-Za-z]+",\[[^]]*\]\);?)*\]'
  id:"Docs"~path:"/docs/:rest<string...>"~activeRoutes:[("Docs",["rest"])]
  id:"Docs@/docs"~path:"/docs"~activeRoutes:[("Docs",["rest"])]
  id:"Help"~path:"/help/:lang<string>"~activeRoutes:[("Help",["lang"])]
  id:"Help@/help"~path:"/help"~activeRoutes:[("Help",["lang"])]
  id:"HelpTopic"~path:"/help/:lang<string>/topics/:topic<int>"~activeRoutes:[("Help",["lang"]);("HelpTopic",["lang";"topic"])]
  id:"HelpTopic@/help/topics/:topic<int>"~path:"/help/topics/:topic<int>"~activeRoutes:[("Help",["lang"]);("HelpTopic",["lang";"topic"])]

  $ server-reason-react.router-gen --mode registry --source optional-duplicate.ml < optional-duplicate.ml
  File "optional-duplicate.ml", line 3, characters 2-57:
  Error: router: duplicate route path /x (from /:a?<string>/x)
  [2]

  $ server-reason-react.router-gen --mode registry --source optional-catch-all-duplicate.ml < optional-catch-all-duplicate.ml
  File "optional-catch-all-duplicate.ml", line 3, characters 2-62:
  Error: router: duplicate route path /docs (from /docs/:rest?<string...>)
  [2]

  $ server-reason-react.router-gen --mode registry --source optional-catch-all-ambiguous.ml < optional-catch-all-ambiguous.ml
  File "optional-catch-all-ambiguous.ml", line 3, characters 2-65:
  Error: router: ambiguous route patterns /assets/:a<string...> and /assets/:b<string...> (from /assets/:b?<string...>)
  [2]

  $ server-reason-react.router-gen --mode registry --source optional-self-ambiguous.ml < optional-self-ambiguous.ml
  File "optional-self-ambiguous.ml", line 1, characters 28-94:
  Error: router: optional segments in /docs/:a?<string>/:b?<string> make /docs/:a<string> and /docs/:b<string> ambiguous
  [2]

  $ server-reason-react.router-gen --mode registry --source optional-crossing.ml < optional-crossing.ml
  File "optional-crossing.ml", line 3, characters 2-53:
  Error: router: ambiguous route patterns /:a<string>/x (from /:a?<string>/x) and /x/:b<string>
  [2]

  $ server-reason-react.router-gen --mode handles --source optional-group.ml < optional-group.ml
  File "optional-group.ml", line 2, characters 4-89:
  Error: router: group path /:lang?<string> cannot contain an optional segment
  [2]

  $ server-reason-react.router-gen --mode handles --source optional-redirect.ml < optional-redirect.ml
  File "optional-redirect.ml", line 2, characters 4-107:
  Error: router: redirect path /old/:rest?<string...> cannot contain an optional segment
  [2]

  $ server-reason-react.router-gen --mode handles --source optional-nonfinal.ml < optional-nonfinal.ml
  File "optional-nonfinal.ml", line 1, characters 28-92:
  Error: router: invalid route path /docs/:rest?<string...>/raw
  [2]

  $ server-reason-react.router-gen --mode registry --source input.ml < input.ml | grep -Eo 'activeRoutes:\[\]|RouterServer.Execution.redirect|Router.Note.destination' | sort -u
  Router.Note.destination
  RouterServer.Execution.redirect
  activeRoutes:[]
  $ server-reason-react.router-gen --mode registry --source input.ml < input.ml | grep -A2 'id:"Asset"' | tr -d ' ~\n' | grep -Eo 'activeRoutes:\[(\("[A-Za-z]+",\[[^]]*\]\);?)*\]'
  activeRoutes:[("Asset",["parts"])]
  $ ocamlc -c RouterRuntime.ml
  $ ocamlc -c RSC.ml
  $ ocamlc -c Js.ml
  $ ocamlc -c React.ml
  $ ocamlc -c RouterReact.ml
  $ ocamlc -c NoteId.ml
  $ ocamlc -c Router_compat.mli
  $ ocamlc -i Router.ml > Router.interface
  $ grep -E '^type route|^val useRoute' Router.interface
  type route =
  val useRoute : unit -> route option
  $ grep -E 'RouterRuntime\.(Navigation\.|Search\.)|RouterReact' Router.interface
  val useBlocker : bool -> RouterReact.blocker
  val useInvalidate : unit -> RouterReact.invalidation -> unit
        ?attributes:RouterReact.Link.attributes ->
        ?attributes:RouterReact.Link.attributes ->
        ?attributes:RouterReact.Link.attributes ->
  $ grep -o 'enabled:bool' Router.interface | sort -u
  enabled:bool
  $ grep -o 'parts:string list' Router.interface | sort -u
  parts:string list
  $ grep -o '?className:string' Router.interface | sort -u
  ?className:string
  $ grep -o 'children:React.element' Router.interface | sort -u
  children:React.element
  $ grep -E 'old-notes|redirect:2' Router.interface
  [1]
  $ grep 'val pattern' Router.interface
  [1]
  $ ocamlc -c Router.ml
  $ ocamlc -c OptionalRoutes.mli
  $ ocamlc -c OptionalRoutes.ml
  $ grep -o '?hash:string' Router.interface | sort -u
  ?hash:string
  $ ocamlc -c unsafe_destination.ml
  $ ocamlc -c loader_redirect.ml
  $ ocamlc -c bad.ml
  File "bad.ml", line 1, characters 17-36:
  1 | let _ : string = Router.Note.href ()
                       ^^^^^^^^^^^^^^^^^^^
  Error: This expression has type id:NoteId.t -> string
         but an expression was expected of type string
  Hint: This function application is partial, maybe some arguments are missing.
  [2]

  $ server-reason-react.router-gen --mode handles --source unknown-argument.ml < unknown-argument.ml
  File "unknown-argument.ml", lines 1-2, characters 0-67:
  Error: router: unknown router argument ~laoyut
  [2]

  $ server-reason-react.router-gen --mode handles --source make-attachment.ml < make-attachment.ml
  File "make-attachment.ml", line 1, characters 55-64:
  Error: router: ~page takes a component module, for example ~page=Pages.Note
  [2]

  $ server-reason-react.router-gen --mode handles --source loader-attachment.ml < loader-attachment.ml
  File "loader-attachment.ml", line 1, characters 82-97:
  Error: router: ~loader takes a loader module, for example ~loader=Pages.NoteLoader
  [2]

  $ server-reason-react.router-gen --mode handles --source duplicate-manifest.ml < duplicate-manifest.ml
  File "duplicate-manifest.ml", line 1, characters 0-94:
  Error: router: expected exactly one Router.make declaration
  [2]

  $ server-reason-react.router-gen --mode handles --source malformed-path.ml < malformed-path.ml
  File "malformed-path.ml", line 1, characters 28-77:
  Error: router: invalid route path /foo:id<int>
  [2]

  $ server-reason-react.router-gen --mode handles --source duplicate-paths.ml < duplicate-paths.ml
  File "duplicate-paths.ml", line 3, characters 2-47:
  Error: router: duplicate route path /notes
  [2]

  $ server-reason-react.router-gen --mode handles --source duplicate-redirect-path.ml < duplicate-redirect-path.ml
  File "duplicate-redirect-path.ml", line 3, characters 2-79:
  Error: router: duplicate route path /notes
  [2]

  $ server-reason-react.router-gen --mode handles --source missing-redirect-target.ml < missing-redirect-target.ml
  File "missing-redirect-target.ml", line 1, characters 28-62:
  Error: router: redirect requires ~target
  [2]

  $ server-reason-react.router-gen --mode handles --source ambiguous-paths.ml < ambiguous-paths.ml
  File "ambiguous-paths.ml", line 3, characters 2-61:
  Error: router: ambiguous route patterns /notes/:id<string> and /notes/:slug<string>
  [2]

  $ server-reason-react.router-gen --mode interface --source ambiguous-paths.ml < ambiguous-paths.ml
  File "ambiguous-paths.ml", line 3, characters 2-61:
  Error: router: ambiguous route patterns /notes/:id<string> and /notes/:slug<string>
  [2]

  $ server-reason-react.router-gen --mode registry --source ambiguous-paths.ml < ambiguous-paths.ml
  File "ambiguous-paths.ml", line 3, characters 2-61:
  Error: router: ambiguous route patterns /notes/:id<string> and /notes/:slug<string>
  [2]

  $ server-reason-react.router-gen --mode handles --source ambiguous-crossing-paths.ml < ambiguous-crossing-paths.ml
  File "ambiguous-crossing-paths.ml", line 3, characters 2-58:
  Error: router: ambiguous route patterns /foo/:id<string> and /:slug<string>/bar
  [2]

  $ server-reason-react.router-gen --mode handles --source invalid-type-path.ml < invalid-type-path.ml
  File "invalid-type-path.ml", line 1, characters 28-82:
  Error: router: invalid route path /notes/:id<foo.t>
  [2]

  $ server-reason-react.router-gen --mode handles --source prefix-parameter-mismatch.ml < prefix-parameter-mismatch.ml
  File "prefix-parameter-mismatch.ml", line 3, characters 2-74:
  Error: router: route prefix parameters differ between /users/:id<string> and /users/:userId<string>/settings
  [2]

  $ server-reason-react.router-gen --mode handles --source prefix-parameter-type-mismatch.ml < prefix-parameter-type-mismatch.ml
  File "prefix-parameter-type-mismatch.ml", line 3, characters 2-70:
  Error: router: route prefix parameters differ between /users/:id<int> and /users/:id<string>/settings
  [2]

  $ server-reason-react.router-gen --mode registry --source valid-parameter-prefix.ml < valid-parameter-prefix.ml | grep 'activeRoutes:' | tr -d ' ~'
  activeRoutes:[("User",["id"])]
  activeRoutes:[("User",["id"]);("Settings",["id"])]

  $ server-reason-react.router-gen --mode handles --source reserved-label.ml < reserved-label.ml
  File "reserved-label.ml", line 1, characters 28-82:
  Error: router: branch input label history conflicts with a generated router argument
  [2]

  $ server-reason-react.router-gen --mode handles --source options-label.ml < options-label.ml > Router.ml
  $ ocamlc -c Router.ml

  $ server-reason-react.router-gen --mode handles --source stdlib-shadow.ml < stdlib-shadow.ml > Stdlib_shadow.ml
  $ ocamlc -c Stdlib_shadow.ml

Path parameters may use the names of generated helpers. Route names may
use the names of runtime modules.

  $ server-reason-react.router-gen --mode handles --source helper-names.ml < helper-names.ml > HelperNames.ml
  $ ocamlc -c HelperNames.ml
  $ server-reason-react.router-gen --mode registry --source helper-names.ml < helper-names.ml > /dev/null

  $ server-reason-react.router-gen --mode registry --source required-root-error.ml < required-root-error.ml
  File "required-root-error.ml", lines 1-2, characters 0-44:
  Error: router: Router.make with required root search and ~error also requires ~invalidSearch
  [2]

  $ server-reason-react.router-gen --mode registry --source required-root-invalid-search.ml < required-root-invalid-search.ml > /dev/null

  $ server-reason-react.router-gen --mode handles --source reserved-some.ml < reserved-some.ml
  File "reserved-some.ml", line 1, characters 28-70:
  Error: router: generated route name Some is reserved
  [2]

  $ server-reason-react.router-gen --mode handles --source reserved-active-search.ml < reserved-active-search.ml
  File "reserved-active-search.ml", line 1, characters 28-80:
  Error: router: generated route name ActiveSearch is reserved
  [2]

  $ server-reason-react.router-gen --mode handles --source reserved-attributes.ml < reserved-attributes.ml
  File "reserved-attributes.ml", line 1, characters 28-85:
  Error: router: branch input label attributes conflicts with a generated router argument
  [2]

  $ server-reason-react.router-gen --mode handles --source static-query.ml < static-query.ml
  File "static-query.ml", line 1, characters 28-82:
  Error: router: invalid route path /reports?draft
  [2]

  $ server-reason-react.router-gen --mode handles --source static-fragment.ml < static-fragment.ml
  File "static-fragment.ml", line 1, characters 28-82:
  Error: router: invalid route path /reports#draft
  [2]

  $ server-reason-react.router-gen --mode handles --source static-percent-escape.ml < static-percent-escape.ml
  File "static-percent-escape.ml", line 1, characters 28-81:
  Error: router: invalid route path /with%20space
  [2]

  $ server-reason-react.router-gen --mode handles --source static-malformed-percent.ml < static-malformed-percent.ml
  File "static-malformed-percent.ml", line 1, characters 28-81:
  Error: router: invalid route path /with%ZZspace
  [2]

  $ server-reason-react.router-gen --mode handles --source static-invalid-utf8.ml < static-invalid-utf8.ml 2>&1 | grep -o 'invalid route path'
  invalid route path

  $ server-reason-react.router-gen --mode handles --source invalid-base.ml < invalid-base.ml
  File "invalid-base.ml", line 1, characters 0-89:
  Error: router: invalid router base path /app?preview
  [2]

  $ cp ../../runtime/RouterUtf8.ml ../../runtime/shared/RouterUrl.ml .
  $ ocamlc -c RouterUtf8.ml RouterUrl.ml
  $ refmt --parse re --print ml ../../runtime/shared/RouterPattern.re > RouterPattern.ml
  $ ocamlc -w -53 -c RouterPattern.ml
  $ ocamlc -o pattern-test RouterUtf8.cmo RouterUrl.cmo RouterPattern.cmo pattern_test.ml
  $ ./pattern-test
  matchesPath passed
  static path grammar and UTF-8 href rendering passed

  $ server-reason-react.router-gen --mode registry --source unicode-path.ml < unicode-path.ml > unicode-registry.ml
  $ grep 'let basePath' unicode-registry.ml
  let basePath = "/m%C3%BCnchen"
  $ grep -o 'trailingSlash:RouterServer.TrailingSlash.Redirect' unicode-registry.ml
  trailingSlash:RouterServer.TrailingSlash.Redirect

  $ server-reason-react.router-gen --mode registry --source trailing-slash-reject.ml < trailing-slash-reject.ml | grep -o 'trailingSlash:RouterServer.TrailingSlash.Reject'
  trailingSlash:RouterServer.TrailingSlash.Reject

  $ server-reason-react.router-gen --mode registry --source trailing-slash-invalid.ml < trailing-slash-invalid.ml
  File "trailing-slash-invalid.ml", line 1, characters 44-53:
  Error: router: ~trailingSlash must be Redirect or Reject
  [2]

  $ server-reason-react.router-gen --mode registry --source active-order.ml < active-order.ml > active-order-registry.ml
  $ grep 'activeRoutes:' active-order-registry.ml | tr -d ' ~'
  activeRoutes:[("Parent",[]);("Leaf",[])]
  activeRoutes:[("Other",[])]
  activeRoutes:[("Parent",[])]

  $ server-reason-react.router-gen --mode registry --source fingerprint-app.ml < fingerprint-app.ml > fingerprint-app-registry.ml
  $ server-reason-react.router-gen --mode registry --source fingerprint-admin.ml < fingerprint-admin.ml > fingerprint-admin-registry.ml
  $ grep -o 'fingerprint:"[0-9a-f]*"' fingerprint-app-registry.ml > fingerprint-app.txt
  $ grep -o 'fingerprint:"[0-9a-f]*"' fingerprint-admin-registry.ml > fingerprint-admin.txt
  $ cmp -s fingerprint-app.txt fingerprint-admin.txt
  [1]

  $ server-reason-react.router-gen --mode registry --source recover-root-error.ml < recover-root-error.ml > recover-root-error-registry.ml
  $ grep -c 'AppError.make' recover-root-error-registry.ml
  14

Errors name the manifest location, or the file set by a line directive.

  $ server-reason-react.router-gen --mode handles --source duplicate-paths.ml < duplicate-paths.ml
  File "duplicate-paths.ml", line 3, characters 2-47:
  Error: router: duplicate route path /notes
  [2]
  $ server-reason-react.router-gen --mode handles --source manifest.ml < duplicate-directive.ml
  File "app/(marketing)/about/page.mlx", line 1, characters 2-47:
  Error: router: duplicate route path /about
  [2]
  $ server-reason-react.router-gen --mode handles --source syntax-error.ml < syntax-error.ml
  File "syntax-error.ml", line 2, characters 0-0:
  Error: Syntax error: operator expected.
  [2]

A redirect is temporary unless it sets ~permanent:true.

  $ server-reason-react.router-gen --mode registry --source permanent-redirect.ml < permanent-redirect.ml | grep -Eo 'RouterServer.Execution.(permanentRedirect|redirect)'
  RouterServer.Execution.permanentRedirect
  RouterServer.Execution.redirect
  $ server-reason-react.router-gen --mode handles --source invalid-permanent.ml < invalid-permanent.ml
  File "invalid-permanent.ml", line 1, characters 115-120:
  Error: router: ~permanent must be true or false
  [2]

`~prefetch` on a route or group sets the route's prefetch level. Children
inherit it, a route overrides it, and the default is Intent, which emits
nothing.

  $ server-reason-react.router-gen --mode handles --source prefetch.ml < prefetch.ml | tr -d ' \n' | grep -Eo 'module[A-Z][A-Za-z]*=struct|PrefetchLevel.[A-Za-z]+'
  moduleHome=struct
  moduleSettings=struct
  PrefetchLevel.Viewport
  moduleBilling=struct
  PrefetchLevel.Off
  moduleActiveSearch=struct
  $ server-reason-react.router-gen --mode registry --source prefetch.ml < prefetch.ml | tr -d ' \n' | grep -Eo 'id:"[A-Z][A-Za-z]*"|PrefetchLevel.[A-Za-z]+'
  id:"Home"
  id:"Settings"
  PrefetchLevel.Viewport
  id:"Billing"
  PrefetchLevel.Off

The level does not change the interface: a destination reads it with
RouterRuntime.prefetchLevel.

  $ server-reason-react.router-gen --mode interface --source prefetch.ml < prefetch.ml | tr -s ' \n' ' ' | grep -Eo 'module [A-Z][A-Za-z]* : sig|val destination : [?a-z: >-]*destination'
  module Home : sig
  val destination : ?hash:string -> unit -> destination
  module Settings : sig
  val destination : ?hash:string -> unit -> destination
  module Billing : sig
  val destination : ?hash:string -> unit -> destination
  module ActiveSearch : sig
  $ server-reason-react.router-gen --mode handles --source prefetch-invalid.ml < prefetch-invalid.ml
  File "prefetch-invalid.ml", line 1, characters 84-89:
  Error: router: ~prefetch must be Off, Intent, Viewport or Idle
  [2]
  $ server-reason-react.router-gen --mode handles --source prefetch-redirect.ml < prefetch-redirect.ml
  File "prefetch-redirect.ml", line 1, characters 31-103:
  Error: router: unknown router argument ~prefetch
  [2]

`~interceptLinks`, `~viewTransitions` and `~pageCacheMaxAge` on Router.make
reach the client Provider through Server.make. Without them the generated call
passes none of them.

  $ server-reason-react.router-gen --mode registry --source client-options.ml < client-options.ml | tr -d ' \n' | grep -Eo '~(interceptLinks|viewTransitions|pageCacheMaxAge):[a-z0-9.]+'
  ~interceptLinks:false
  ~viewTransitions:true
  ~pageCacheMaxAge:30.0
  $ server-reason-react.router-gen --mode registry --source prefetch.ml < prefetch.ml | grep -c 'interceptLinks\|viewTransitions\|pageCacheMaxAge'
  0
  [1]
  $ server-reason-react.router-gen --mode registry --source page-cache-max-age-invalid.ml < page-cache-max-age-invalid.ml
  File "page-cache-max-age-invalid.ml", line 1, characters 46-48:
  Error: router: ~pageCacheMaxAge must be a float literal, such as 30.0
  [2]
  $ server-reason-react.router-gen --mode registry --source client-options-invalid.ml < client-options-invalid.ml
  File "client-options-invalid.ml", line 1, characters 46-51:
  Error: router: ~viewTransitions must be true or false
  [2]

`~loaderAs_` and `~to_` were renamed. The old labels name the new ones.

  $ server-reason-react.router-gen --mode handles --source renamed-loader-label.ml < renamed-loader-label.ml
  File "renamed-loader-label.ml", line 1, characters 28-105:
  Error: router: ~loaderAs_ was renamed to ~loaderLabel
  [2]
  $ server-reason-react.router-gen --mode handles --source renamed-redirect-target.ml < renamed-redirect-target.ml
  File "renamed-redirect-target.ml", line 1, characters 28-83:
  Error: router: ~to_ was renamed to ~target
  [2]
  $ server-reason-react.router-gen --mode registry --source loader-label.ml < loader-label.ml | grep -o 'fun note ->'
  fun note ->

`~loaderParallel=true` starts a loader with the ancestor loaders. It receives
no ancestor loader result, and its result is read after theirs.

  $ server-reason-react.router-gen --mode registry --source loader-parallel.ml < loader-parallel.ml | tr -s ' \n' ' ' | grep -Eo 'Execution\.(start|await|loadWithBoundary)|[A-Za-z]+Loader\.load [^)]*\)'
  Execution.start
  NoteLoader.load ~workspaceId ~id ()
  Execution.loadWithBoundary
  WorkspaceLoader.load ~workspaceId ()
  Execution.loadWithBoundary
  Execution.await
  $ server-reason-react.router-gen --mode handles --source loader-parallel-required.ml < loader-parallel-required.ml
  File "loader-parallel-required.ml", line 1, characters 87-91:
  Error: router: ~loaderParallel requires ~loader
  [2]
  $ server-reason-react.router-gen --mode handles --source loader-parallel-literal.ml < loader-parallel-literal.ml
  File "loader-parallel-literal.ml", line 1, characters 106-109:
  Error: router: ~loaderParallel takes a bool literal, for example ~loaderParallel=true
  [2]

The root `~error` is a boundary component, like `~error` on a group or a
route. `~errorStatus` maps an application error to a status. Without it,
an application error answers 500.

  $ server-reason-react.router-gen --mode registry --source error-status.ml < error-status.ml | grep -q 'AppBoundary.make' && echo boundary
  boundary
  $ server-reason-react.router-gen --mode registry --source error-status.ml < error-status.ml | grep 'let applicationStatus'
  let applicationStatus = AppError.status
  $ server-reason-react.router-gen --mode registry --source error-boundary-only.ml < error-boundary-only.ml | grep 'let applicationStatus'
  let applicationStatus _ = RouterRuntime.Status.InternalServerError
  $ server-reason-react.router-gen --mode registry --source error-boundary-only.ml < error-boundary-only.ml | grep -c 'status AppBoundary\|AppBoundary.status'
  0
  [1]

Search parameters reach the generated API as one record, so their names never
meet a generated argument. A path parameter may share a name with a search
parameter.

  $ server-reason-react.router-gen --mode handles --source search-names.ml < search-names.ml > SearchNames.ml
  $ server-reason-react.router-gen --mode interface --source search-names.ml < search-names.ml > SearchNames.mli
  $ ocamlc -c SearchNames.mli
  $ ocamlc -c SearchNames.ml
  $ tr -s ' \n' ' ' < SearchNames.mli | grep -Eo 'val (search|destination) :( [?a-zA-Z]+:[a-zA-Z ]+ ->)* unit -> [a-z]+'
  val search : ?revalidate:string -> ?updateSearch:string -> ?id:string -> unit -> search
  val destination : id:int -> ?search:search -> ?hash:string -> unit -> destination
  val search : ?revalidate:string -> ?updateSearch:string -> target:string -> ?error:string -> ?input:string -> ?hash:string list -> ?value:int -> ?pattern:string -> unit -> search
  val destination : search:search -> ?hash:string -> unit -> destination
  $ tr -s ' \n' ' ' < SearchNames.mli | grep -Eo 'type (nonrec )?search = [^}]*}'
  type search = { revalidate: string option ; updateSearch: string option }
  type search = { revalidate: string option ; updateSearch: string option ; id: string option }
  type search = { revalidate: string option ; updateSearch: string option ; target: string ; error: string option ; input: string ; hash: string list ; value: int ; pattern: string option }
  $ ocamlc -c search_names_use.ml
  $ grep -c 'val search_to_rsc : search -> RSC.t' SearchNames.mli
  3
  $ grep -c 'val search_of_rsc : RSC.t -> search' SearchNames.mli
  3
  $ server-reason-react.router-gen --mode registry --source search-names.ml < search-names.ml | grep -Eo 'type redirect_[0-9_]+_search|Router\.[A-Za-z]+\.search\)|~search:routeSearch|~search:search' | sort -u
  Router.Inspector.search)
  Router.Note.search)
  type redirect_2_search
  ~search:routeSearch
  ~search:search

A route that adds search parameters to the root ones gets its own
`useSearch`. It decodes the root fields and its own, and its update owns both.
A route without its own parameters shares the root record and hook.

  $ server-reason-react.router-gen --mode handles --source route-search.ml < route-search.ml > RouteSearch.ml
  $ server-reason-react.router-gen --mode interface --source route-search.ml < route-search.ml > RouteSearch.mli
  $ ocamlc -c RouteSearch.mli
  $ ocamlc -c RouteSearch.ml
  $ tr -s ' \n' ' ' < RouteSearch.mli | grep -Eo 'module [A-Za-z]+ : sig|type (nonrec )?search = [^}]*}|val useSearch : unit -> \(search'
  type search = { q: string option }
  val useSearch : unit -> (search
  module Home : sig
  type nonrec search = search = { q: string option }
  module Results : sig
  type search = { q: string option ; page: int }
  val useSearch : unit -> (search
  module ActiveSearch : sig
  $ grep -Eo '~owned:\[[^]]*\]' RouteSearch.ml
  ~owned:["q"]
  ~owned:["q"]
  ~owned:["q"; "page"]
  ~owned:["q"; "page"]
  $ ocamlc -c route_search_use.ml

  $ server-reason-react.router-gen --mode registry --source duplicate-search.ml < duplicate-search.ml
  File "duplicate-search.ml", line 2, characters 4-93:
  Error: router: duplicate search parameter page
  [2]

`~context` on Router.make declares the type of the request context. Every
loader, `~metadata` and `~headers` receives it as `~context`. Executions take
it as their argument, the fallback takes `~context`, and the registry builds
the server with `Server.makeWithContext`, so `RouterServer.runWithContext
~context` reaches them. A redirect ignores it.

  $ server-reason-react.router-gen --mode registry --source context.ml < context.ml | tr -s ' \n' ' ' | grep -Eo '(fun |~context:)\([_a-z]+ : [A-Za-z.]+\)|[A-Za-z]+\.[a-z]+ ~context|RouterServer.Server.make[A-Za-z]*' | sort | uniq -c | sed "s/^ *//"
  2 NoteHeaders.make ~context
  1 NoteLoader.load ~context
  6 RootMetadata.make ~context
  1 RouterServer.Server.makeWithContext
  1 fun (_ : Session.t)
  2 fun (context : Session.t)
  1 ~context:(context : Session.t)

Without `~context`, executions take `()`, nothing mentions a context, and the
registry uses `Server.make`, so `RouterServer.run` runs it.

  $ server-reason-react.router-gen --mode registry --source loader-label.ml < loader-label.ml | tr -s ' \n' ' ' | grep -Eo '~execution:\(fun [^-]*->|context|RouterServer.Server.make[A-Za-z]*' | sort | uniq -c | sed "s/^ *//"
  1 RouterServer.Server.make
  1 ~execution:(fun () ->

`~context` belongs to Router.make only. Loaders, metadata and headers
receive it as the label `context`, so a path parameter or loader label
named `context` conflicts with it.

  $ server-reason-react.router-gen --mode handles --source context-group.ml < context-group.ml
  File "context-group.ml", line 2, characters 41-50:
  Error: router: Router.group cannot declare ~context; declare it on Router.make
  [2]
  $ server-reason-react.router-gen --mode handles --source context-label.ml < context-label.ml
  File "context-label.ml", line 2, characters 72-82:
  Error: router: branch input label context conflicts with a generated router argument
  [2]

`~key` gives a search parameter a URL key other than its field name. The
record field and the constructor argument keep the label; the query string,
the decoders, the `useSearch` update and the registry use the key. Labels and
keys are separate names, so a key can be an OCaml keyword, contain a dash, or
equal another field's label.

  $ server-reason-react.router-gen --mode handles --source search-key-alias.ml < search-key-alias.ml > SearchKeyAlias.ml
  $ server-reason-react.router-gen --mode interface --source search-key-alias.ml < search-key-alias.ml > SearchKeyAlias.mli
  $ ocamlc -c SearchKeyAlias.mli
  $ ocamlc -c SearchKeyAlias.ml
  $ ocamlc -c search_key_alias_use.ml
  $ tr -s ' \n' ' ' < SearchKeyAlias.mli | grep -Eo 'type (nonrec )?search = [^}]*}|val search :( [?a-zA-Z]+:[a-zA-Z ]+ ->)* unit -> search'
  type search = { infoPage: string option }
  type search = { infoPage: string option ; siteTarget: string option ; target: string ; kind: string ; tags: int list }
  val search : ?infoPage:string -> ?siteTarget:string -> ?target:string -> kind:string -> ?tags:int list -> unit -> search
  $ tr -s ' \n' ' ' < SearchKeyAlias.ml | grep -Eo '~name:"[^"]*"|\("[^"]*", *\[|~owned:\[[^]]*\]' | sort | uniq -c | sed "s/^ *//"
  4 ("info-page", [
  1 ("site", [
  1 ("target", [
  1 ("type", [
  7 ~name:"info-page"
  4 ~name:"site"
  4 ~name:"tag"
  4 ~name:"target"
  4 ~name:"type"
  2 ~owned:["info-page"; "target"; "site"; "type"; "tag"]
  2 ~owned:["info-page"]
  $ server-reason-react.router-gen --mode registry --source search-key-alias.ml < search-key-alias.ml | tr -s ' \n' ' ' | grep -Eo 'search(Required|Optional|Default|Many) ~input ~name:"[^"]*"|[a-zA-Z.]+ = search_[0-9]+' | sort | uniq -c | sed "s/^ *//"
  1 Router.Inspector.kind = search_2
  1 Router.Inspector.siteTarget = search_0
  1 Router.Inspector.tags = search_3
  1 Router.Inspector.target = search_1
  3 Router.infoPage = search_0
  1 oldTarget = search_0
  1 searchDefault ~input ~name:"site"
  1 searchMany ~input ~name:"tag"
  3 searchOptional ~input ~name:"info-page"
  2 searchOptional ~input ~name:"target"
  1 searchRequired ~input ~name:"type"

A key changes the registry fingerprint.

  $ server-reason-react.router-gen --mode registry --source search-key-alias-plain.ml < search-key-alias-plain.ml | grep -o 'fingerprint:"[0-9a-f]*"' > plain.txt
  $ server-reason-react.router-gen --mode registry --source search-key-alias-keyed.ml < search-key-alias-keyed.ml | grep -o 'fingerprint:"[0-9a-f]*"' > keyed.txt
  $ cmp -s plain.txt keyed.txt
  [1]
  $ wc -l < plain.txt | tr -d " "
  1

Two parameters of one branch cannot share a URL key, whether it comes from a
label or from `~key`, and whether the root or the route declares it.

  $ server-reason-react.router-gen --mode handles --source duplicate-search-key.ml < duplicate-search-key.ml
  File "duplicate-search-key.ml", line 4, characters 74-80:
  Error: router: duplicate search key "target", used by siteTarget and target
  [2]
  $ server-reason-react.router-gen --mode handles --source duplicate-root-search-key.ml < duplicate-root-search-key.ml
  File "duplicate-root-search-key.ml", line 2, characters 58-62:
  Error: router: duplicate search key "info-page", used by infoPage and page
  [2]

A key is a non-empty, valid UTF-8 string literal. The constructors take no
other labelled argument.

  $ server-reason-react.router-gen --mode handles --source empty-search-key.ml < empty-search-key.ml
  File "empty-search-key.ml", line 1, characters 114-116:
  Error: router: search key must not be empty
  [2]
  $ server-reason-react.router-gen --mode handles --source invalid-search-key.ml < invalid-search-key.ml
  File "invalid-search-key.ml", line 2, characters 90-96:
  Error: router: search key "\255" is not valid UTF-8
  [2]
  $ server-reason-react.router-gen --mode handles --source search-key-expression.ml < search-key-expression.ml
  File "search-key-expression.ml", line 4, characters 110-113:
  Error: router: ~key takes a string literal, for example ~key:"info-page"
  [2]
  $ server-reason-react.router-gen --mode handles --source unknown-search-argument.ml < unknown-search-argument.ml
  File "unknown-search-argument.ml", line 2, characters 62-104:
  Error: router: unknown router argument ~kye
  [2]

`~shallow:true` marks a search parameter whose changes need no server
response. Generated destinations list the URL keys of their route's shallow
parameters, root parameters included, with `RouterRuntime.withShallowSearch`.
The flag is part of the registry fingerprint. It takes a boolean literal.

  $ server-reason-react.router-gen --mode handles --source shallow-search.ml < shallow-search.ml | tr -s ' \n' ' ' | grep -Eo 'withShallowSearch|~hash\) \["[^]]*\]'
  withShallowSearch
  ~hash) ["tab"; "p"]
  withShallowSearch
  ~hash) ["tab"]
  $ server-reason-react.router-gen --mode handles --source shallow-search-invalid.ml < shallow-search-invalid.ml
  File "shallow-search-invalid.ml", line 4, characters 110-117:
  Error: router: ~shallow takes true or false, for example ~shallow:true
  [2]

Without `~key`, a keyword is not a field name, so a query key such as `type`
needs `~key:"type"` on another label, as in `search-key-alias.ml`.

  $ server-reason-react.router-gen --mode handles --source keyword-search-key.ml < keyword-search-key.ml 2>&1 | head -2
  File "keyword-search-key.ml", line 1, characters 82-86:
  Error: Syntax error

User names do not collide with names in the generated code: path
parameters named like generated helpers, routes named like modules the
generated code uses, and free names in spliced expressions. A wildcard or
keyword label is rejected.

  $ for name in search-values try-destination fun stdlib router-runtime react codec; do
  >   server-reason-react.router-gen --mode handles --source collision-$name.ml < collision-$name.ml > Collision.ml
  >   ocamlc -c Collision.ml || echo "$name failed"
  > done
  $ server-reason-react.router-gen --mode handles --source collision-underscore.ml < collision-underscore.ml
  File "collision-underscore.ml", line 1, characters 28-79:
  Error: router: branch input label _ is a keyword or a wildcard; rename it
  [2]
  $ server-reason-react.router-gen --mode handles --source collision-capture.ml < collision-capture.ml > Collision.ml
  $ ocamlc -c Collision.ml
  $ server-reason-react.router-gen --mode registry --source collision-capture.ml < collision-capture.ml | tr -s ' \n' ' ' | grep -Eo 'fun max_int[_0-9]* ->|fallback:max_int[_0-9]*'
  fun max_int_1 ->
  fallback:max_int
