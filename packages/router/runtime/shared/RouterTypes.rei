type destination;

let makeDestination: string => destination;
let destinationHref: destination => string;

module Status: {
  type t =
    | Ok
    | BadRequest
    | Forbidden
    | NotFound
    | InternalServerError
    | TemporaryRedirect
    | PermanentRedirect;

  let toInt: t => int;
};

module Loader: {
  type result('data, 'error) =
    | Data('data)
    | Error('error)
    | NotFound
    | Redirect(destination);
};

module Error: {
  type notFoundReason =
    | NoMatchingRoute
    | LoaderNotFound;

  type t('applicationError) =
    | NotFound({reason: notFoundReason})
    | Application('applicationError)
    | InvalidPathParameter({name: string})
    | InvalidSearchParameter({name: string})
    | Internal({diagnosticId: string});
};

module Metadata: {
  type entry = {
    key: string,
    name: string,
    content: string,
  };

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

  type matched = {
    routeId: string,
    parameters: list((string, string)),
  };

  type layout = {
    id: string,
    instanceKey: string,
  };

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
  let fail: (state, ~requestId: int, ~message: string) => state;
  let shallow: (state, ~location: location, ~action: historyAction) => state;
  let hashOnly: (state, ~location: location, ~action: historyAction) => state;
  let isActive:
    (
      committed,
      ~routeId: string,
      ~parameters: list((string, string)),
      ~includeDescendants: bool
    ) =>
    bool;
  let classifyPop:
    (committed, ~target: location, ~targetRevision: option(string)) => kind;

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

module Search: {
  type options = {history: Navigation.historyAction};

  let defaultOptions: options;
  let parseString: string => result(string, string);
  let parseInt: string => result(int, string);
  let required:
    (
      ~name: string,
      ~parse: string => result('value, string),
      list((string, list(string)))
    ) =>
    'value;
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
    | FailedResponse
    | ReloadRequiredResponse;

  type full('payload) = {
    protocolVersion: int,
    registryFingerprint: string,
    canonicalUrl: string,
    status: int,
    matches: list(Navigation.matched),
    layouts: list(Navigation.layout),
    targetRevision: string,
    payload: 'payload,
  };

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
    payload: 'payload,
  };

  type redirect = {
    protocolVersion: int,
    registryFingerprint: string,
    location: string,
    status: int,
  };

  type failure = {
    protocolVersion: int,
    registryFingerprint: string,
    message: string,
    status: int,
  };

  type t('payload) =
    | Full(full('payload))
    | Patch(patch('payload))
    | Redirect(redirect)
    | Failed(failure)
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
    className: option(string),
    target: option(string),
    download: option(string),
    ariaCurrent: option(string),
    history: Navigation.historyAction,
    revalidate: bool,
  };

  let defaultOptions: options;
};
