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

let fetch =
    (
      ~callServer,
      ~decodeNavigation,
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
      "SRR-Registry",
      string_of_int(protocolVersion) ++ "." ++ registryFingerprint,
    ),
    ("SRR-Base-Revision", baseRevision),
  |];
  let headers =
    Fetch.HeadersInit.makeWithArray(
      switch (from) {
      | Some(from) =>
        Array.append(baseHeaders, [|("SRR-Navigation-From", from)|])
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
           Fetch.Headers.get("SRR-Response", responseHeaders);
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
               |> FlightProvider.decode(~callServer)
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
