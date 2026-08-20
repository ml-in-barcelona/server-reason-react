  $ export OCAMLRUNPARAM=
  $ server-reason-react.router-gen --mode handles --source input.ml < input.ml > Router.ml
  $ server-reason-react.router-gen --mode interface --source input.ml < input.ml > Router.mli
  $ grep -E '^type route|^val useRoute|useIsActive' Router.mli
  type route =
  val useRoute : unit -> route option
  $ grep -E 'RouterRuntime\.(Navigation\.|Search\.)|RouterReact' Router.mli
  [1]
  $ grep -o 'enabled:bool' Router.mli | sort -u
  enabled:bool
  $ grep -o 'parts:string list' Router.mli | sort -u
  parts:string list

  $ server-reason-react.router-gen --mode handles --source catch-all-group.ml < catch-all-group.ml
  Fatal error: exception router: group path /assets/:parts<string...> cannot contain a catch-all segment
  [2]

  $ server-reason-react.router-gen --mode handles --source catch-all-nonfinal.ml < catch-all-nonfinal.ml
  Fatal error: exception router: invalid route path /:parts<string...>/raw
  [2]

  $ server-reason-react.router-gen --mode registry --source catch-all-ambiguous.ml < catch-all-ambiguous.ml
  Fatal error: exception router: ambiguous route patterns /assets/:a<string...> and /assets/:b<string...>
  [2]

  $ server-reason-react.router-gen --mode registry --source catch-all-crossing.ml < catch-all-crossing.ml
  Fatal error: exception router: ambiguous route patterns /foo/:left<string...> and /:scope<string>/bar/:right<string...>
  [2]
  $ grep -E 'old-notes|redirect:2' Router.mli
  [1]
  $ server-reason-react.router-gen --mode registry --source input.ml < input.ml | grep -Eo 'activeRoutes:\[\]|RouterServer.Execution.redirect|Router.Note.destination' | sort -u
  Router.Note.destination
  RouterServer.Execution.redirect
  activeRoutes:[]
  $ ocamlc -c RouterRuntime.ml
  $ ocamlc -c Js.ml
  $ ocamlc -c React.ml
  $ ocamlc -c RouterReact.ml
  $ ocamlc -c NoteId.ml
  $ ocamlc -c Router.mli
  $ ocamlc -c Router.ml
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
  Fatal error: exception router: unknown router argument ~laoyut
  [2]

  $ server-reason-react.router-gen --mode handles --source make-attachment.ml < make-attachment.ml
  Fatal error: exception router: ~page takes a component module, for example ~page=Pages.Note
  [2]

  $ server-reason-react.router-gen --mode handles --source loader-attachment.ml < loader-attachment.ml
  Fatal error: exception router: ~loader takes a loader module, for example ~loader=Pages.NoteLoader
  [2]

  $ server-reason-react.router-gen --mode handles --source duplicate-manifest.ml < duplicate-manifest.ml
  Fatal error: exception router: expected exactly one Router.make declaration
  [2]

  $ server-reason-react.router-gen --mode handles --source malformed-path.ml < malformed-path.ml
  Fatal error: exception router: invalid route path /foo:id<int>
  [2]

  $ server-reason-react.router-gen --mode handles --source duplicate-paths.ml < duplicate-paths.ml
  Fatal error: exception router: duplicate route path /notes
  [2]

  $ server-reason-react.router-gen --mode handles --source duplicate-redirect-path.ml < duplicate-redirect-path.ml
  Fatal error: exception router: duplicate route path /notes
  [2]

  $ server-reason-react.router-gen --mode handles --source missing-redirect-target.ml < missing-redirect-target.ml
  Fatal error: exception router: redirect requires ~to_
  [2]

  $ server-reason-react.router-gen --mode handles --source ambiguous-paths.ml < ambiguous-paths.ml
  Fatal error: exception router: ambiguous route patterns /notes/:id<string> and /notes/:slug<string>
  [2]

  $ server-reason-react.router-gen --mode interface --source ambiguous-paths.ml < ambiguous-paths.ml
  Fatal error: exception router: ambiguous route patterns /notes/:id<string> and /notes/:slug<string>
  [2]

  $ server-reason-react.router-gen --mode registry --source ambiguous-paths.ml < ambiguous-paths.ml
  Fatal error: exception router: ambiguous route patterns /notes/:id<string> and /notes/:slug<string>
  [2]

  $ server-reason-react.router-gen --mode handles --source ambiguous-crossing-paths.ml < ambiguous-crossing-paths.ml
  Fatal error: exception router: ambiguous route patterns /foo/:id<string> and /:slug<string>/bar
  [2]

  $ server-reason-react.router-gen --mode handles --source invalid-type-path.ml < invalid-type-path.ml
  Fatal error: exception router: invalid route path /notes/:id<foo.t>
  [2]

  $ server-reason-react.router-gen --mode handles --source prefix-parameter-mismatch.ml < prefix-parameter-mismatch.ml
  Fatal error: exception router: route prefix parameters differ between /users/:id<string> and /users/:userId<string>/settings
  [2]

  $ server-reason-react.router-gen --mode handles --source prefix-parameter-type-mismatch.ml < prefix-parameter-type-mismatch.ml
  Fatal error: exception router: route prefix parameters differ between /users/:id<int> and /users/:id<string>/settings
  [2]

  $ server-reason-react.router-gen --mode registry --source valid-parameter-prefix.ml < valid-parameter-prefix.ml | grep 'activeRoutes:' | tr -d ' ~'
  activeRoutes:[("User",["id"])]
  activeRoutes:[("User",["id"]);("Settings",["id"])]

  $ server-reason-react.router-gen --mode handles --source reserved-label.ml < reserved-label.ml
  Fatal error: exception router: branch input label options conflicts with a generated router argument
  [2]

  $ server-reason-react.router-gen --mode handles --source reserved-pattern.ml < reserved-pattern.ml
  Fatal error: exception router: branch input label pattern conflicts with a generated router argument
  [2]

  $ server-reason-react.router-gen --mode registry --source reserved-input.ml < reserved-input.ml
  Fatal error: exception router: branch input label input conflicts with a generated router argument
  [2]

  $ server-reason-react.router-gen --mode handles --source reserved-destination.ml < reserved-destination.ml
  Fatal error: exception router: branch input label destination conflicts with a generated router argument
  [2]

  $ server-reason-react.router-gen --mode handles --source reserved-update-search.ml < reserved-update-search.ml
  Fatal error: exception router: branch input label updateSearch conflicts with a generated router argument
  [2]

  $ server-reason-react.router-gen --mode registry --source required-root-error.ml < required-root-error.ml
  Fatal error: exception router: Router.make with required root search and ~error also requires ~invalidSearch
  [2]

  $ server-reason-react.router-gen --mode registry --source required-root-invalid-search.ml < required-root-invalid-search.ml > /dev/null

  $ server-reason-react.router-gen --mode handles --source reserved-link.ml < reserved-link.ml
  Fatal error: exception router: generated route name Link is reserved
  [2]

  $ server-reason-react.router-gen --mode handles --source static-query.ml < static-query.ml
  Fatal error: exception router: invalid route path /reports?draft
  [2]

  $ server-reason-react.router-gen --mode handles --source static-fragment.ml < static-fragment.ml
  Fatal error: exception router: invalid route path /reports#draft
  [2]

  $ server-reason-react.router-gen --mode handles --source static-percent-escape.ml < static-percent-escape.ml
  Fatal error: exception router: invalid route path /with%20space
  [2]

  $ server-reason-react.router-gen --mode handles --source static-malformed-percent.ml < static-malformed-percent.ml
  Fatal error: exception router: invalid route path /with%ZZspace
  [2]

  $ server-reason-react.router-gen --mode handles --source static-invalid-utf8.ml < static-invalid-utf8.ml 2>&1 | grep -o 'invalid route path'
  invalid route path

  $ server-reason-react.router-gen --mode handles --source invalid-base.ml < invalid-base.ml
  Fatal error: exception router: invalid router base path /app?preview
  [2]

  $ refmt --parse re --print ml ../../runtime/shared/RouterPattern.re > RouterPattern.ml
  $ ocamlc -w -53 -c RouterPattern.ml
  $ ocamlc -o pattern-test RouterPattern.cmo pattern_test.ml
  $ ./pattern-test
  static path grammar and UTF-8 href rendering passed

  $ server-reason-react.router-gen --mode registry --source unicode-path.ml < unicode-path.ml > unicode-registry.ml
  $ grep 'let basePath' unicode-registry.ml
  let basePath = "/m%C3%BCnchen"
  $ grep -o 'trailingSlash:RouterServer.TrailingSlash.Redirect' unicode-registry.ml
  trailingSlash:RouterServer.TrailingSlash.Redirect

  $ server-reason-react.router-gen --mode registry --source trailing-slash-reject.ml < trailing-slash-reject.ml | grep -o 'trailingSlash:RouterServer.TrailingSlash.Reject'
  trailingSlash:RouterServer.TrailingSlash.Reject

  $ server-reason-react.router-gen --mode registry --source trailing-slash-invalid.ml < trailing-slash-invalid.ml
  Fatal error: exception router: ~trailingSlash must be Redirect or Reject
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
  4
