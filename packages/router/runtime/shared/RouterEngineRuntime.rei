/** Internals that generated code and the router libraries share on both platforms. Applications use
    {!RouterRuntime}; {!RouterEngine} includes this module. */

type pattern;
let pattern: string => pattern;
let destinationFromPattern:
  (
    ~pattern: pattern,
    ~parameters: list((string, string)),
    ~search: list((string, list(string)))
  ) =>
  RouterRuntime.destination;

/** The URL keys of the search parameters declared [~shallow=true] on the
    route [destination] points to. A [navigate] to the committed path that
    changes only these keys updates the URL without a request, like
    [updateSearch]. Other destinations have none. */
let shallowSearch: RouterRuntime.destination => list(string);

/** Sets the shallow search keys. Generated destinations call it with the
    keys of their route. */
let withShallowSearch:
  (RouterRuntime.destination, list(string)) => RouterRuntime.destination;

/** Query string without the leading [?]: names sorted, every name and value
    percent-encoded. Destinations and [updateSearch] both use it so one query
    has one spelling. Raises [Invalid_argument] for text
    [encodeURIComponent] cannot encode: invalid UTF-8 on native, a lone
    surrogate in the browser. */
let encodeSearch: list((string, list(string))) => string;

module Navigation: {
  open RouterRuntime.Navigation;

  type kind = RouterTypes.Navigation.kind = | Content | Shallow | HashOnly;

  type state = RouterTypes.Navigation.state;

  type commitError =
    RouterTypes.Navigation.commitError = | Superseded | StaleRevision;

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

  type historyMutation =
    RouterTypes.Navigation.historyMutation = | PushEntry | ReplaceEntry;

  let historyMutation: historyAction => historyMutation;
};

module CatchAll: {
  let parse: string => result(list(string), string);

  /** Joins decoded segments with a slash. Raises [Invalid_argument] on an
      empty list and on empty, dot, or slash-containing segments. */
  let toString: list(string) => string;
};

module SearchValues: {
  type options =
    RouterTypes.Search.options = {
      history: RouterRuntime.Navigation.historyAction,
    };

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
    RouterTypes.NavigationResponse.kind =
      | FullResponse
      | PatchResponse
      | RedirectResponse
      | ReloadRequiredResponse;

  [@deriving rsc]
  type full('payload) =
    RouterTypes.NavigationResponse.full('payload) = {
      protocolVersion: int,
      registryFingerprint: string,
      canonicalUrl: string,
      status: int,
      matches: list(RouterRuntime.Navigation.matched),
      layouts: list(RouterRuntime.Navigation.layout),
      targetRevision: string,
      metadata: 'payload,
      payload: 'payload,
    };

  [@deriving rsc]
  type patch('payload) =
    RouterTypes.NavigationResponse.patch('payload) = {
      protocolVersion: int,
      registryFingerprint: string,
      baseRevision: string,
      targetRevision: string,
      replaceFrom: string,
      canonicalUrl: string,
      status: int,
      matches: list(RouterRuntime.Navigation.matched),
      layouts: list(RouterRuntime.Navigation.layout),
      metadata: 'payload,
      payload: 'payload,
    };

  [@deriving rsc]
  type redirect =
    RouterTypes.NavigationResponse.redirect = {
      protocolVersion: int,
      registryFingerprint: string,
      location: string,
      status: int,
    };

  type t('payload) =
    RouterTypes.NavigationResponse.t('payload) =
      | Full(full('payload))
      | Patch(patch('payload))
      | Redirect(redirect)
      | ReloadRequired;

  type facts =
    RouterTypes.NavigationResponse.facts = {
      requestId: int,
      baseRevision: string,
      status: int,
      contentType: option(string),
      kind,
    };

  type validated('payload) =
    RouterTypes.NavigationResponse.validated('payload) = {
      requestId: int,
      baseRevision: string,
      response: t('payload),
    };

  type validationError =
    RouterTypes.NavigationResponse.validationError =
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
