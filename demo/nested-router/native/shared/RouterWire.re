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
type full = {
  protocolVersion: int,
  registryFingerprint: string,
  canonicalUrl: string,
  status: int,
  matches: list(matched),
  layouts: list(layout),
  targetRevision: string,
  payload: React.element,
};

[@deriving rsc]
type patch = {
  protocolVersion: int,
  registryFingerprint: string,
  baseRevision: string,
  targetRevision: string,
  replaceFrom: string,
  canonicalUrl: string,
  status: int,
  matches: list(matched),
  layouts: list(layout),
  payload: React.element,
};

[@deriving rsc]
type redirect = {
  protocolVersion: int,
  registryFingerprint: string,
  location: string,
  status: int,
};

let matchedToRuntime = (matched: matched) =>
  RouterRuntime.Navigation.{
    routeId: matched.routeId,
    parameters: matched.parameters,
  };

let layoutToRuntime = (layout: layout) =>
  RouterRuntime.Navigation.{
    id: layout.id,
    instanceKey: layout.instanceKey,
  };

let fullToRuntime = (full: full) =>
  RouterRuntime.NavigationResponse.Full({
    protocolVersion: full.protocolVersion,
    registryFingerprint: full.registryFingerprint,
    canonicalUrl: full.canonicalUrl,
    status: full.status,
    matches: List.map(matchedToRuntime, full.matches),
    layouts: List.map(layoutToRuntime, full.layouts),
    targetRevision: full.targetRevision,
    payload: full.payload,
  });

let patchToRuntime = (patch: patch) =>
  RouterRuntime.NavigationResponse.Patch({
    protocolVersion: patch.protocolVersion,
    registryFingerprint: patch.registryFingerprint,
    baseRevision: patch.baseRevision,
    targetRevision: patch.targetRevision,
    replaceFrom: patch.replaceFrom,
    canonicalUrl: patch.canonicalUrl,
    status: patch.status,
    matches: List.map(matchedToRuntime, patch.matches),
    layouts: List.map(layoutToRuntime, patch.layouts),
    payload: patch.payload,
  });

let redirectToRuntime = (redirect: redirect) =>
  RouterRuntime.NavigationResponse.Redirect({
    protocolVersion: redirect.protocolVersion,
    registryFingerprint: redirect.registryFingerprint,
    location: redirect.location,
    status: redirect.status,
  });

let responseOfRsc = (kind, value) =>
  switch (kind) {
  | RouterRuntime.NavigationResponse.PatchResponse =>
    value |> patch_of_rsc |> patchToRuntime
  | RouterRuntime.NavigationResponse.FullResponse =>
    value |> full_of_rsc |> fullToRuntime
  | RouterRuntime.NavigationResponse.RedirectResponse =>
    value |> redirect_of_rsc |> redirectToRuntime
  | RouterRuntime.NavigationResponse.FailedResponse
  | RouterRuntime.NavigationResponse.ReloadRequiredResponse =>
    RSC.of_rsc_error(~rsc=value, "unexpected navigation response body")
  };
