module Response = RouterRuntime.NavigationResponse;

type error =
  | MissingResponseKind
  | InvalidResponseKind(string)
  | InvalidContentType(option(string));

type decoded = {
  facts: Response.facts,
  response: Response.t(React.element),
};

type pending = {
  abort: unit => unit,
  response: Js.Promise.t(result(decoded, error)),
};

let decodeNavigation = (kind, value) =>
  switch (kind) {
  | Response.FullResponse =>
    Response.Full(
      Response.full_of_rsc(RSC.Primitives.react_element_of_rsc, value),
    )
  | Response.PatchResponse =>
    Response.Patch(
      Response.patch_of_rsc(RSC.Primitives.react_element_of_rsc, value),
    )
  | Response.RedirectResponse =>
    Response.Redirect(Response.redirect_of_rsc(value))
  | Response.FailedResponse =>
    Response.Failed(Response.failure_of_rsc(value))
  | Response.ReloadRequiredResponse => Response.ReloadRequired
  };

let fetch =
    (
      ~protocolVersion,
      ~registryFingerprint,
      ~requestId,
      ~baseRevision,
      ~from,
      ~target,
    ) => {
  let controller = Fetch.AbortController.make();
  let baseHeaders = [|
    ("Accept", "application/react.component"),
    (
      "Router-Registry",
      string_of_int(protocolVersion) ++ "." ++ registryFingerprint,
    ),
    ("Router-Base-Revision", baseRevision),
  |];
  let headers =
    Fetch.HeadersInit.makeWithArray(
      switch (from) {
      | Some(from) =>
        Array.append(baseHeaders, [|("Router-Navigation-From", from)|])
      | None => baseHeaders
      },
    );
  let request =
    Fetch.fetchWithInit(
      target,
      Fetch.RequestInit.make(
        ~method_=Fetch.Get,
        ~headers,
        ~signal=Fetch.AbortController.signal(controller),
        (),
      ),
    )
    |> Js.Promise.then_(httpResponse => {
         let responseHeaders = Fetch.Response.headers(httpResponse);
         let responseKind =
           Fetch.Headers.get("Router-Response", responseHeaders);
         let contentType = Fetch.Headers.get("Content-Type", responseHeaders);
         let status = Fetch.Response.status(httpResponse);
         switch (responseKind) {
         | None => Js.Promise.resolve(Error(MissingResponseKind))
         | Some(value) =>
           switch (Response.kindOfString(value)) {
           | None => Js.Promise.resolve(Error(InvalidResponseKind(value)))
           | Some(Response.ReloadRequiredResponse as kind) =>
             Js.Promise.resolve(
               Ok({
                 facts: {
                   requestId,
                   baseRevision,
                   status,
                   contentType,
                   kind,
                 },
                 response: Response.ReloadRequired,
               }),
             )
           | Some(kind) =>
             if (!Response.isComponentContentType(contentType)) {
               Js.Promise.resolve(Error(InvalidContentType(contentType)));
             } else {
               Fetch.Response.body(httpResponse)
               |> ReactServerDOMEsbuild.createFromReadableStream
               |> Js.Promise.then_((wire: RSC.t) =>
                    Js.Promise.resolve(
                      Ok({
                        facts: {
                          requestId,
                          baseRevision,
                          status,
                          contentType,
                          kind,
                        },
                        response: decodeNavigation(kind, wire),
                      }),
                    )
                  );
             }
           }
         };
       });
  {
    abort: () => Fetch.AbortController.abort(controller),
    response: request,
  };
};
