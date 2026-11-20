type arg;
type callServer = (string, list(arg)) => Js.Promise.t(React.element);

type options = {callServer};

[@mel.module "./ReactServerDOMEsbuild.js"]
external createFromReadableStreamImpl:
  (Webapi.ReadableStream.t, ~options: options=?, unit) => Js.Promise.t('a) =
  "createFromReadableStream";

[@mel.module "./ReactServerDOMEsbuild.js"]
external createFromFetchImpl:
  (Js.Promise.t(Fetch.response), ~options: options=?, unit) =>
  Js.Promise.t('a) =
  "createFromFetch";

[@mel.module "./ReactServerDOMEsbuild.js"]
external createServerReferenceImpl:
  (
    string, // ServerReferenceId
    callServer,
    // EncodeFormActionCallback (optional) (We're not using this right now)
    option('encodeFormActionCallback),
    // FindSourceMapURLCallback (optional, DEV-only) (We're not using this right now)
    option('findSourceMapURLCallback),
    // functionName (optional)
    option(string)
  ) =>
  // actionCallback is a function that takes N arguments and returns a promise
  // As we don't have control over the number of arguments, we need to pass it as 'actionCallback
  'action =
  "createServerReference";

[@mel.module "./ReactServerDOMEsbuild.js"]
external encodeReply: list('arg) => Js.Promise.t(string) = "encodeReply";

let serverCallListeners: ref(list(unit => unit)) = ref([]);

/** Calls [listener] after each server function call that succeeds. Returns a
    function that removes it. */
let onServerCallSuccess = listener => {
  serverCallListeners := [listener, ...serverCallListeners^];
  () =>
    serverCallListeners :=
      List.filter(other => other !== listener, serverCallListeners^);
};

let notified: ref(option((callServer, callServer))) = ref(None);

let notifying = callServer =>
  switch (notified^) {
  | Some((original, wrapped))
      when original === callServer || wrapped === callServer => wrapped
  | Some(_)
  | None =>
    let wrapped = (path, args) =>
      callServer(path, args)
      |> Js.Promise.then_(result => {
           List.iter(listener => listener(), serverCallListeners^);
           Js.Promise.resolve(result);
         });
    notified := Some((callServer, wrapped));
    wrapped;
  };

let callServerRef: ref(option(callServer)) = ref(None);
let setCallServer = callServer => {
  callServerRef := Some(notifying(callServer));
};
let getCallServer = () => {
  callServerRef^;
};

let resolveCallServer = callServer =>
  switch (callServer) {
  | Some(callServer) =>
    setCallServer(callServer);
    getCallServer();
  | None => getCallServer()
  };

/* The returned promise is a real Promise (chainable with Js.Promise.then_)
   that also carries live status/value/reason getters delegating to
   react-client's root chunk, so React.use keeps its synchronous unwrap
   during hydration. See chainableRoot in ReactServerDOMEsbuild.js. */
let createFromReadableStream = (~callServer=?, stream): Js.Promise.t('a) => {
  switch (resolveCallServer(callServer)) {
  | Some(callServer) =>
    createFromReadableStreamImpl(
      stream,
      ~options={ callServer: callServer },
      (),
    )
  | None => createFromReadableStreamImpl(stream, ())
  };
};

let createFromFetch = (~callServer=?, promise) => {
  switch (resolveCallServer(callServer)) {
  | Some(callServer) =>
    createFromFetchImpl(promise, ~options={ callServer: callServer }, ())
  | None => createFromFetchImpl(promise, ())
  };
};

let createServerReference = serverReferenceId => {
  let callServer =
    switch (getCallServer()) {
    | Some(callServer) => callServer
    | None =>
      raise(
        Invalid_argument(
          "No callServer has been set, you are trying to create a server function without passing callServer to createFromFetch or createFromReadableStream",
        ),
      )
    };
  createServerReferenceImpl(serverReferenceId, callServer, None, None, None);
};

let serverCallRedirectListeners: ref(list(string => unit)) = ref([]);

/** Calls [listener] with the href of the [Router-Redirect] header when a
    server function called through {!fetchCallServer} ends with a redirect.
    Returns a function that removes it. */
let onServerCallRedirect = listener => {
  serverCallRedirectListeners := [listener, ...serverCallRedirectListeners^];
  () =>
    serverCallRedirectListeners :=
      List.filter(other => other !== listener, serverCallRedirectListeners^);
};

/** A [callServer] that posts each call to [url] with the [ACTION_ID] header,
    decodes the Flight result, and reports a [Router-Redirect] header to the
    {!onServerCallRedirect} listeners. A non-2xx response rejects with
    [Failure("fetchCallServer: <status> <body>")]. */
let fetchCallServer = (~url="/", ()): callServer =>
  (path, args) =>
    encodeReply(args)
    |> Js.Promise.then_(body =>
         Fetch.fetchWithInit(
           url,
           Fetch.RequestInit.make(
             ~method_=Fetch.Post,
             ~headers=
               Fetch.HeadersInit.makeWithArray([|
                 ("Accept", "application/react.action"),
                 ("ACTION_ID", path),
               |]),
             ~body=Fetch.BodyInit.make(body),
             (),
           ),
         )
       )
    |> Js.Promise.then_(response =>
         if (!Fetch.Response.ok(response)) {
           Fetch.Response.text(response)
           |> Js.Promise.then_(body =>
                Js.Promise.reject(
                  Failure(
                    "fetchCallServer: "
                    ++ string_of_int(Fetch.Response.status(response))
                    ++ " "
                    ++ body,
                  ),
                )
              );
         } else {
           let redirect =
             Fetch.Headers.get(
               "Router-Redirect",
               Fetch.Response.headers(response),
             );
           createFromReadableStream(Fetch.Response.body(response))
           |> Js.Promise.then_(result => {
                Option.iter(
                  href =>
                    List.iter(
                      listener => listener(href),
                      serverCallRedirectListeners^,
                    ),
                  redirect,
                );
                Js.Promise.resolve(result);
              });
         }
       );
