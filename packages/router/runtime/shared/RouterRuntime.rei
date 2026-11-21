type destination;
type pattern;

/** How eagerly the client may prefetch a route, from least to most eager:
    [Off], [Intent], [Viewport], [Idle]. A route declares its level with
    [~prefetch]; the default is [Intent]. */
module PrefetchLevel: {
  type t =
    | Off
    | Intent
    | Viewport
    | Idle;

  /** The lower-case name, as sent in the [Router-Prefetch] header. */
  let toString: t => string;
  let fromString: string => option(t);

  /** Negative when [left] is less eager than [right]. */
  let compare: (t, t) => int;
};

let destination: (~path: string) => destination;
let pattern: string => pattern;
let destinationFromPattern:
  (
    ~pattern: pattern,
    ~parameters: list((string, string)),
    ~search: list((string, list(string)))
  ) =>
  destination;
let href: destination => string;

/** [origin] followed by the href of [destination], for a link that leaves
    the page, such as in an email or a copied URL. [origin] is a scheme and
    host such as ["https://example.com"]; trailing slashes are dropped. A
    destination whose href does not start with [/], such as an absolute
    [unsafeDestination], is returned unchanged. */
let absoluteHref: (~origin: string, destination) => string;

/** Sets the fragment of [destination] to [hash], percent-encoded like a
    search value. An empty [hash] removes the fragment. */
let withHash: (destination, ~hash: string) => destination;

/** The prefetch level of the route [destination] points to. Generated
    destinations carry their route's level; other destinations are [Intent]. */
let prefetchLevel: destination => PrefetchLevel.t;

/** Sets the prefetch level. Generated destinations call it with the level of
    their route. */
let withPrefetch: (destination, PrefetchLevel.t) => destination;

/** Query string without the leading [?]: names sorted, every name and value
    percent-encoded. Destinations and [updateSearch] both use it so one query
    has one spelling. */
let encodeSearch: list((string, list(string))) => string;

module Status: {
  type t =
    | Ok
    | BadRequest
    | Unauthorized
    | Forbidden
    | NotFound
    | Gone
    | TooManyRequests
    | InternalServerError
    | ServiceUnavailable
    | TemporaryRedirect
    | PermanentRedirect;

  let toInt: t => int;
};

module Loader: {
  type result('data, 'error) =
    | Data('data)
    | Error('error)
    | NotFound
    | Redirect(destination)
    | PermanentRedirect(destination);
};

module Error: {
  type notFoundReason =
    | NoMatchingRoute
    | LoaderNotFound
    | RenderNotFound;

  type t('applicationError) =
    | NotFound({reason: notFoundReason})
    | Application('applicationError)
    | InvalidPathParameter({name: string})
    | InvalidSearchParameter({name: string})
    | Internal({diagnosticId: string});
};

module Metadata: {
  type metaAttribute =
    | Name
    | Property;

  type entry =
    | Meta({
        key: string,
        attr: metaAttribute,
        name: string,
        content: string,
      })
    | Link({
        key: string,
        rel: string,
        href: string,
        attrs: list((string, string)),
      });

  let entryKey: entry => string;

  /** `<meta name=... content=...>`. The default key is `"meta:" ++ name`. */
  let meta: (~key: string=?, ~name: string, string) => entry;

  /** `<meta property=... content=...>`. The default key is `"property:" ++ property`. */
  let property: (~key: string=?, ~property: string, string) => entry;

  /** `<link rel=... href=... attrs>`. The default key is `"link:" ++ rel`. Pass an explicit key for a repeated rel
      such as several `alternate` links. `attrs` named `rel` or `href` are ignored when rendering. */
  let link:
    (
      ~key: string=?,
      ~rel: string,
      ~attrs: list((string, string))=?,
      string
    ) =>
    entry;

  type t = {
    title: option(string),
    description: option(string),
    entries: list(entry),
  };

  let make:
    (
      ~title: string=?,
      ~description: string=?,
      ~entries: list(entry)=?,
      unit
    ) =>
    t;
  let merge: (t, t) => t;
};

module Headers: {
  type t;

  type error =
    | ForbiddenHeader(string)
    | InvalidHeaderName(string)
    | InvalidHeaderValue(string);

  let make: list((string, string)) => result(t, error);
  let merge: (t, t) => t;
  let toList: t => list((string, string));
};

module Navigation: {
  [@deriving rsc]
  type location = {
    pathname: string,
    search: string,
    hash: string,
    key: string,
  };

  type historyAction =
    | Push
    | Replace
    | Pop;

  type kind =
    | Content
    | Shallow
    | HashOnly;

  [@deriving rsc]
  type matched = {
    routeId: string,
    parameters: list((string, string)),
  };

  [@deriving rsc]
  type layout = {
    id: string,
    instanceKey: string,
  };

  [@deriving rsc]
  type committed = {
    location,
    matches: list(matched),
    layouts: list(layout),
    revision: string,
  };

  type failure = {
    requestId: int,
    message: string,
  };

  type status =
    | Idle
    | Loading({
        requestId: int,
        fromRevision: string,
        to_: location,
        action: historyAction,
      })
    | Failed(failure);

  type state;

  type commitError =
    | Superseded
    | StaleRevision;

  let make: committed => state;
  let committed: state => committed;
  let status: state => status;
  let start: (state, ~to_: location, ~action: historyAction) => (state, int);
  let commit:
    (state, ~requestId: int, ~baseRevision: string, ~next: committed) =>
    result(state, commitError);
  let isActive: (state, ~requestId: int) => bool;
  let fail: (state, ~requestId: int, ~message: string) => state;
  let shallow: (state, ~location: location, ~action: historyAction) => state;
  let hashOnly: (state, ~location: location, ~action: historyAction) => state;
  let classifyPopByContentIdentity:
    (
      committed,
      ~target: location,
      ~currentIdentity: string,
      ~targetIdentity: option(string)
    ) =>
    kind;

  module Result: {
    type t =
      | Committed(committed)
      | Redirected(string)
      | Canceled
      | Failed(string);
  };

  type historyMutation =
    | PushEntry
    | ReplaceEntry;

  let historyMutation: historyAction => historyMutation;
};

module CatchAll: {
  let parse: string => result(list(string), string);

  /** Joins decoded segments with a slash. Raises [Invalid_argument] on an
      empty list and on empty, dot, or slash-containing segments. */
  let toString: list(string) => string;
};

module Search: {
  type options = {history: Navigation.historyAction};

  let defaultOptions: options;
  let parseString: string => result(string, string);
  let parseInt: string => result(int, string);
  let parseBool: string => result(bool, string);
  /** The first value of [name], parsed. [None] when the name is missing or
      its first value does not parse. */
  let required:
    (
      ~name: string,
      ~parse: string => result('value, string),
      list((string, list(string)))
    ) =>
    option('value);
  let optional:
    (
      ~name: string,
      ~parse: string => result('value, string),
      list((string, list(string)))
    ) =>
    option('value);
  let default:
    (
      ~name: string,
      ~parse: string => result('value, string),
      ~fallback: 'value,
      list((string, list(string)))
    ) =>
    'value;
  let many:
    (
      ~name: string,
      ~parse: string => result('value, string),
      list((string, list(string)))
    ) =>
    list('value);
  let update:
    (
      ~owned: list(string),
      ~values: list((string, list(string))),
      list((string, list(string)))
    ) =>
    list((string, list(string)));
};

module NavigationResponse: {
  type kind =
    | FullResponse
    | PatchResponse
    | RedirectResponse
    | ReloadRequiredResponse;

  [@deriving rsc]
  type full('payload) = {
    protocolVersion: int,
    registryFingerprint: string,
    canonicalUrl: string,
    status: int,
    matches: list(Navigation.matched),
    layouts: list(Navigation.layout),
    targetRevision: string,
    metadata: 'payload,
    payload: 'payload,
  };

  [@deriving rsc]
  type patch('payload) = {
    protocolVersion: int,
    registryFingerprint: string,
    baseRevision: string,
    targetRevision: string,
    replaceFrom: string,
    canonicalUrl: string,
    status: int,
    matches: list(Navigation.matched),
    layouts: list(Navigation.layout),
    metadata: 'payload,
    payload: 'payload,
  };

  [@deriving rsc]
  type redirect = {
    protocolVersion: int,
    registryFingerprint: string,
    location: string,
    status: int,
  };

  type t('payload) =
    | Full(full('payload))
    | Patch(patch('payload))
    | Redirect(redirect)
    | ReloadRequired;

  type facts = {
    requestId: int,
    baseRevision: string,
    status: int,
    contentType: option(string),
    kind,
  };

  type validated('payload) = {
    requestId: int,
    baseRevision: string,
    response: t('payload),
  };

  type validationError =
    | SupersededResponse
    | StaleResponse
    | InvalidHttpStatus(int)
    | InvalidContentType(option(string))
    | ResponseKindMismatch
    | ProtocolVersionMismatch
    | RegistryFingerprintMismatch
    | CanonicalUrlRejected(string);

  let kindOfString: string => option(kind);
  let isComponentContentType: option(string) => bool;
  let validate:
    (
      ~expectedProtocolVersion: int,
      ~expectedRegistryFingerprint: string,
      ~activeRequestId: int,
      ~committedRevision: string,
      ~canonicalUrlAllowed: string => bool,
      facts,
      t('payload)
    ) =>
    result(validated('payload), validationError);
};

module Link: {
  type options = {
    history: Navigation.historyAction,
    revalidate: bool,
  };

  let defaultOptions: options;
};
