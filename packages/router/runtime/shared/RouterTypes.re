type destination = {href: string};

let makeDestination: string => destination = href => { href: href };
let destinationHref = destination => destination.href;

module Status = {
  type t =
    | Ok
    | BadRequest
    | Forbidden
    | NotFound
    | InternalServerError
    | TemporaryRedirect
    | PermanentRedirect;

  let toInt = status =>
    switch (status) {
    | Ok => 200
    | BadRequest => 400
    | Forbidden => 403
    | NotFound => 404
    | InternalServerError => 500
    | TemporaryRedirect => 307
    | PermanentRedirect => 308
    };
};

module Loader = {
  type result('data, 'error) =
    | Data('data)
    | Error('error)
    | NotFound
    | Redirect(destination);
};

module Error = {
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

module Metadata = {
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

  let make = (~title=?, ~description=?, ~entries=[], ()) => {
    title,
    description,
    entries,
  };

  let mergeEntries = (parent, child) =>
    List.filter(
      parentEntry =>
        !
          List.exists(
            childEntry => String.equal(parentEntry.key, childEntry.key),
            child,
          ),
      parent,
    )
    @ child;

  let prefer = (preferred, fallback) =>
    switch (preferred) {
    | Some(_) => preferred
    | None => fallback
    };

  let merge = (parent, child) => {
    title: prefer(child.title, parent.title),
    description: prefer(child.description, parent.description),
    entries: mergeEntries(parent.entries, child.entries),
  };
};

module Headers = {
  type t = list((string, string));
  type error =
    | ForbiddenHeader(string)
    | InvalidHeaderName(string)
    | InvalidHeaderValue(string);

  let forbidden = name =>
    switch (String.lowercase_ascii(name)) {
    | "connection"
    | "content-length"
    | "transfer-encoding" => true
    | _ => false
    };

  let tokenCharacter = character => {
    let code = Char.code(character);
    code >= Char.code('a')
    && code <= Char.code('z')
    || code >= Char.code('A')
    && code <= Char.code('Z')
    || code >= Char.code('0')
    && code <= Char.code('9')
    || String.contains("!#$%&'*+-.^_`|~", character);
  };

  let validName = name =>
    String.length(name) > 0
    && name
    |> String.to_seq
    |> Seq.for_all(tokenCharacter);

  let validValue = value =>
    value
    |> String.to_seq
    |> Seq.for_all(character => {
         let code = Char.code(character);
         character == '\t' || code >= 32 && code != 127;
       });

  let make = headers =>
    switch (List.find_opt(((name, _)) => !validName(name), headers)) {
    | Some((name, _)) => Error(InvalidHeaderName(name))
    | None =>
      switch (List.find_opt(((_, value)) => !validValue(value), headers)) {
      | Some((_, value)) => Error(InvalidHeaderValue(value))
      | None =>
        switch (List.find_opt(((name, _)) => forbidden(name), headers)) {
        | Some((name, _)) => Error(ForbiddenHeader(name))
        | None => Ok(headers)
        }
      }
    };

  let varyTokens = headers =>
    headers
    |> List.filter_map(((name, value)) =>
         String.equal(String.lowercase_ascii(name), "vary")
           ? Some(String.split_on_char(',', value)) : None
       )
    |> List.flatten
    |> List.map(String.trim)
    |> List.filter(value => !String.equal(value, ""))
    |> List.fold_left(
         (tokens, token) =>
           List.exists(
             current =>
               String.equal(
                 String.lowercase_ascii(current),
                 String.lowercase_ascii(token),
               ),
             tokens,
           )
             ? tokens : tokens @ [token],
         [],
       );

  let merge = (parent, child) => {
    let merged =
      List.filter(
        ((parentName, _)) =>
          String.equal(String.lowercase_ascii(parentName), "set-cookie")
          || !
               List.exists(
                 ((childName, _)) =>
                   String.equal(
                     String.lowercase_ascii(parentName),
                     String.lowercase_ascii(childName),
                   ),
                 child,
               ),
        parent,
      )
      @ child;
    let vary = varyTokens(parent @ child);
    let merged =
      List.filter(
        ((name, _)) => !String.equal(String.lowercase_ascii(name), "vary"),
        merged,
      );
    switch (vary) {
    | [] => merged
    | vary => merged @ [("Vary", String.concat(", ", vary))]
    };
  };

  let toList = headers => headers;
};

module Navigation = {
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

  type state = {
    committed,
    status,
    nextRequestId: int,
  };

  type commitError =
    | Superseded
    | StaleRevision;

  let make = committed => {
    committed,
    status: Idle,
    nextRequestId: 1,
  };
  let committed = state => state.committed;
  let status = state => state.status;

  let start = (state, ~to_, ~action) => {
    let requestId = state.nextRequestId;
    (
      {
        ...state,
        status:
          Loading({
            requestId,
            fromRevision: state.committed.revision,
            to_,
            action,
          }),
        nextRequestId: requestId + 1,
      },
      requestId,
    );
  };

  let commit = (state, ~requestId, ~baseRevision, ~next) =>
    switch (state.status) {
    | Loading(active) when active.requestId != requestId => Error(Superseded)
    | Loading(active) when active.fromRevision != baseRevision =>
      Error(StaleRevision)
    | Loading(_) =>
      Ok({
        ...state,
        committed: next,
        status: Idle,
      })
    | Idle
    | Failed(_) => Error(Superseded)
    };

  let fail = (state, ~requestId, ~message) =>
    switch (state.status) {
    | Loading(active) when active.requestId == requestId => {
        ...state,
        status:
          Failed({
            requestId,
            message,
          }),
      }
    | _ => state
    };

  let shallow = (state, ~location, ~action as _) => {
    ...state,
    committed: {
      ...state.committed,
      location,
    },
    status: Idle,
  };

  let hashOnly = (state, ~location, ~action as _) => {
    ...state,
    committed: {
      ...state.committed,
      location,
    },
    status: Idle,
  };

  let normalizeParameters =
    List.sort(((left, _), (right, _)) => String.compare(left, right));

  let sameMatch = (left, right) =>
    String.equal(left.routeId, right.routeId)
    && normalizeParameters(left.parameters)
    == normalizeParameters(right.parameters);

  let isActive = (committed, ~routeId, ~parameters, ~includeDescendants) => {
    let expected = {
      routeId,
      parameters,
    };
    if (includeDescendants) {
      List.exists(
        current => sameMatch(current, expected),
        committed.matches,
      );
    } else {
      switch (List.rev(committed.matches)) {
      | [current, ..._] => sameMatch(current, expected)
      | [] => false
      };
    };
  };

  let classifyPopLocation = (committed, target) =>
    if (String.equal(target.pathname, committed.location.pathname)
        && String.equal(target.search, committed.location.search)) {
      HashOnly;
    } else if (String.equal(target.pathname, committed.location.pathname)) {
      Shallow;
    } else {
      Content;
    };

  let classifyPop = (committed, ~target, ~targetRevision) =>
    switch (targetRevision) {
    | Some(revision) when String.equal(revision, committed.revision) =>
      classifyPopLocation(committed, target)
    | Some(_)
    | None => Content
    };

  let classifyPopByContentIdentity =
      (committed, ~target, ~currentIdentity, ~targetIdentity) =>
    switch (targetIdentity) {
    | Some(identity) when String.equal(identity, currentIdentity) =>
      classifyPopLocation(committed, target)
    | Some(_)
    | None => Content
    };

  module Result = {
    type t =
      | Committed(committed)
      | Redirected(string)
      | Canceled
      | Failed(string);
  };

  type historyMutation =
    | PushEntry
    | ReplaceEntry;

  let historyMutation = action =>
    switch (action) {
    | Push => PushEntry
    | Replace
    | Pop => ReplaceEntry
    };
};

module Search = {
  type options = {history: Navigation.historyAction};

  let defaultOptions = { history: Navigation.Replace };

  let parseString = value => Ok(value);
  let parseInt = value =>
    switch (int_of_string_opt(value)) {
    | Some(value) => Ok(value)
    | None => Error("expected an integer")
    };

  let values = (name, search) =>
    switch (List.assoc_opt(name, search)) {
    | Some(values) => values
    | None => []
    };

  let parseOne = (~name, ~parse, value) =>
    switch (parse(value)) {
    | Ok(value) => value
    | Error(message) =>
      invalid_arg("invalid search parameter " ++ name ++ ": " ++ message)
    };

  let required = (~name, ~parse, search) =>
    switch (values(name, search)) {
    | [value, ..._] => parseOne(~name, ~parse, value)
    | [] => invalid_arg("missing required search parameter " ++ name)
    };

  let optional = (~name, ~parse, search) =>
    switch (values(name, search)) {
    | [value, ..._] => Some(parseOne(~name, ~parse, value))
    | [] => None
    };

  let default = (~name, ~parse, ~fallback, search) =>
    switch (values(name, search)) {
    | [value, ..._] => parseOne(~name, ~parse, value)
    | [] => fallback
    };

  let many = (~name, ~parse, search) =>
    values(name, search) |> List.map(value => parseOne(~name, ~parse, value));

  let update = (~owned, ~values, search) =>
    List.filter(((name, _)) => !List.mem(name, owned), search)
    @ values
    |> List.sort(((left, _), (right, _)) => String.compare(left, right));
};

module NavigationResponse = {
  type kind =
    | FullResponse
    | PatchResponse
    | RedirectResponse
    | FailedResponse
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

  [@deriving rsc]
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

  let kindOfString = value =>
    switch (String.lowercase_ascii(String.trim(value))) {
    | "full" => Some(FullResponse)
    | "patch" => Some(PatchResponse)
    | "redirect" => Some(RedirectResponse)
    | "failed" => Some(FailedResponse)
    | "reload-required" => Some(ReloadRequiredResponse)
    | _ => None
    };

  let isComponentContentType = contentType =>
    switch (contentType) {
    | Some(contentType) =>
      let mediaType =
        contentType
        |> String.split_on_char(';')
        |> List.hd
        |> String.trim
        |> String.lowercase_ascii;
      String.equal(mediaType, "application/react.component");
    | None => false
    };

  let validate =
      (
        ~expectedProtocolVersion,
        ~expectedRegistryFingerprint,
        ~activeRequestId,
        ~committedRevision,
        ~canonicalUrlAllowed,
        facts: facts,
        response: t('payload),
      ) => {
    let responseKind =
      switch (response) {
      | Full(_) => FullResponse
      | Patch(_) => PatchResponse
      | Redirect(_) => RedirectResponse
      | Failed(_) => FailedResponse
      | ReloadRequired => ReloadRequiredResponse
      };
    let versionAndFingerprint =
      switch (response) {
      | Full(response) =>
        Some((response.protocolVersion, response.registryFingerprint))
      | Patch(response) =>
        Some((response.protocolVersion, response.registryFingerprint))
      | Redirect(response) =>
        Some((response.protocolVersion, response.registryFingerprint))
      | Failed(response) =>
        Some((response.protocolVersion, response.registryFingerprint))
      | ReloadRequired => None
      };
    let responseStatus =
      switch (response) {
      | Full(response) => Some(response.status)
      | Patch(response) => Some(response.status)
      | Redirect(response) => Some(response.status)
      | Failed(response) => Some(response.status)
      | ReloadRequired => None
      };
    if (facts.requestId != activeRequestId) {
      Error(SupersededResponse);
    } else if (!String.equal(facts.baseRevision, committedRevision)) {
      Error(StaleResponse);
    } else if (facts.status < 200 || facts.status > 599) {
      Error(InvalidHttpStatus(facts.status));
    } else if (facts.kind != responseKind) {
      Error(ResponseKindMismatch);
    } else if (facts.kind != ReloadRequiredResponse
               && !isComponentContentType(facts.contentType)) {
      Error(InvalidContentType(facts.contentType));
    } else {
      switch (responseStatus) {
      | Some(status) when status != facts.status =>
        Error(InvalidHttpStatus(facts.status))
      | _ =>
        switch (versionAndFingerprint) {
        | Some((version, _)) when version != expectedProtocolVersion =>
          Error(ProtocolVersionMismatch)
        | Some((_, fingerprint))
            when !String.equal(fingerprint, expectedRegistryFingerprint) =>
          Error(RegistryFingerprintMismatch)
        | _ =>
          switch (response) {
          | Patch(response)
              when !String.equal(response.baseRevision, committedRevision) =>
            Error(StaleResponse)
          | Full(response) when !canonicalUrlAllowed(response.canonicalUrl) =>
            Error(CanonicalUrlRejected(response.canonicalUrl))
          | Patch(response) when !canonicalUrlAllowed(response.canonicalUrl) =>
            Error(CanonicalUrlRejected(response.canonicalUrl))
          | _ =>
            Ok({
              requestId: facts.requestId,
              baseRevision: facts.baseRevision,
              response,
            })
          }
        }
      };
    };
  };
};

module Link = {
  type options = {
    history: Navigation.historyAction,
    revalidate: bool,
  };

  let defaultOptions = {
    history: Navigation.Push,
    revalidate: false,
  };
};
