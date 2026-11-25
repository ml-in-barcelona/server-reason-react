module Response = RouterTypes.NavigationResponse;

type error =
  | MissingResponseKind
  | InvalidResponseKind(string)
  | InvalidContentType(option(string))
  | PrefetchRefused(RouterRuntime.PrefetchLevel.t);

type bytes;

type decoded = {
  facts: Response.facts,
  response: Response.t(React.element),
  bytes: option(Js.Promise.t(bytes)),
};

[@mel.send]
external tee: Webapi.ReadableStream.t => array(Webapi.ReadableStream.t) =
  "tee";
[@mel.new]
external responseOfStream: Webapi.ReadableStream.t => Fetch.Response.t =
  "Response";
[@mel.new] external responseOfBytes: bytes => Fetch.Response.t = "Response";
[@mel.send]
external arrayBuffer: Fetch.Response.t => Js.Promise.t(bytes) = "arrayBuffer";
[@mel.get]
external readableBody: Fetch.Response.t => Webapi.ReadableStream.t = "body";

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
  | Response.ReloadRequiredResponse => Response.ReloadRequired
  };

let decodeBytes = (~kind, bytes) =>
  readableBody(responseOfBytes(bytes))
  |> ReactServerDOMEsbuild.createFromReadableStream
  |> Js.Promise.then_((wire: RSC.t) =>
       Js.Promise.resolve(decodeNavigation(kind, wire))
     );

let fetch =
    (
      ~protocolVersion,
      ~registryFingerprint,
      ~requestId,
      ~baseRevision,
      ~from,
      ~prefetch=?,
      ~target,
      (),
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
      Array.concat([
        baseHeaders,
        switch (from) {
        | Some(from) => [|("Router-Navigation-From", from)|]
        | None => [||]
        },
        switch (prefetch) {
        | Some(level) => [|
            ("Router-Prefetch", RouterRuntime.PrefetchLevel.toString(level)),
          |]
        | None => [||]
        },
      ]),
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
         let refused =
           Option.bind(
             Fetch.Headers.get("Router-Prefetch-Refused", responseHeaders),
             RouterRuntime.PrefetchLevel.fromString,
           );
         switch (responseKind) {
         | _ when status == 204 && Option.is_some(refused) =>
           Js.Promise.resolve(
             Error(
               PrefetchRefused(
                 Option.value(
                   refused,
                   ~default=RouterRuntime.PrefetchLevel.Off,
                 ),
               ),
             ),
           )
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
                 bytes: None,
               }),
             )
           | Some(kind) =>
             if (!Response.isComponentContentType(contentType)) {
               Js.Promise.resolve(Error(InvalidContentType(contentType)));
             } else {
               let (decodeStream, bytes) =
                 switch (tee(Fetch.Response.body(httpResponse))) {
                 | [|decodeStream, copyStream|] =>
                   let bytes = arrayBuffer(responseOfStream(copyStream));
                   let _ =
                     bytes
                     |> Js.Promise.then_(_ => Js.Promise.resolve())
                     |> Js.Promise.catch(_ => Js.Promise.resolve());
                   (decodeStream, Some(bytes));
                 | _ => (Fetch.Response.body(httpResponse), None)
                 };
               decodeStream
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
                        bytes,
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
