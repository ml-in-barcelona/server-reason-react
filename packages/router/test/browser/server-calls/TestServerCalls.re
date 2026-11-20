let expect = (message, condition) =>
  if (!condition) {
    failwith(message);
  };

let serverCalls = ref(0);
let stopListening =
  ReactServerDOMEsbuild.onServerCallSuccess(() => incr(serverCalls));
let failNextCall = ref(false);
let appCallServer: ReactServerDOMEsbuild.callServer = (_path, _args) =>
  failNextCall^
    ? Js.Promise.reject(Failure("action failed"))
    : Js.Promise.resolve(React.null);
ReactServerDOMEsbuild.setCallServer(appCallServer);
let registered = () =>
  switch (ReactServerDOMEsbuild.getCallServer()) {
  | Some(callServer) => callServer
  | None => failwith("no callServer was registered")
  };
let wrappedCallServer = registered();
ReactServerDOMEsbuild.setCallServer(appCallServer);
expect(
  "setting the same callServer again wrapped it twice",
  registered() === wrappedCallServer,
);
ReactServerDOMEsbuild.setCallServer(wrappedCallServer);
expect(
  "setting the wrapped callServer wrapped it again",
  registered() === wrappedCallServer,
);
let _ =
  wrappedCallServer("action", [])
  |> Js.Promise.then_(_ => {
       expect("a successful server call did not notify", serverCalls^ == 1);
       failNextCall := true;
       wrappedCallServer("action", [])
       |> Js.Promise.then_(_ => Js.Promise.resolve(false))
       |> Js.Promise.catch(_ => Js.Promise.resolve(true));
     })
  |> Js.Promise.then_(failed => {
       expect("a failing server call resolved", failed);
       expect("a failing server call notified", serverCalls^ == 1);
       stopListening();
       failNextCall := false;
       wrappedCallServer("action", []);
     })
  |> Js.Promise.then_(_ => {
       expect("a removed listener was notified", serverCalls^ == 1);
       Js.Promise.resolve();
     });

let installFetch: (string => unit, Js.Nullable.t(string)) => unit = [%mel.raw
  {|(record, redirect) => {
  globalThis.fetch = (url, init) => {
    const headers = new Headers(init.headers);
    record(JSON.stringify([url, init.method, headers.get("ACTION_ID"), headers.get("Accept")]));
    const responseHeaders = redirect === null ? {} : { "Router-Redirect": redirect };
    return Promise.resolve(new Response("0:null\n", { headers: responseHeaders }));
  };
}|}
];
let installFailingFetch: (int, string) => unit = [%mel.raw
  {|(status, body) => {
  globalThis.fetch = () => Promise.resolve(new Response(body, { status }));
}|}
];
let requests = ref([]);
let redirects = ref([]);
let stopRedirects =
  ReactServerDOMEsbuild.onServerCallRedirect(href =>
    redirects := redirects^ @ [href]
  );
let callServer = ReactServerDOMEsbuild.fetchCallServer(~url="/actions", ());
installFetch(
  request => requests := requests^ @ [request],
  Js.Nullable.return("/app/next?from=action"),
);
let _ =
  callServer("save", [])
  |> Js.Promise.then_(_ => {
       expect(
         "a redirect header was not reported",
         redirects^ == ["/app/next?from=action"],
       );
       expect(
         "the call was not posted with its action id",
         requests^
         == [{|["/actions","POST","save","application/react.action"]|}],
       );
       installFetch(
         request => requests := requests^ @ [request],
         Js.Nullable.null,
       );
       callServer("save", []);
     })
  |> Js.Promise.then_(_ => {
       expect(
         "a call without a redirect reported one",
         List.length(redirects^) == 1,
       );
       stopRedirects();
       installFetch(_ => (), Js.Nullable.return("/elsewhere"));
       callServer("save", []);
     })
  |> Js.Promise.then_(_ => {
       expect(
         "a removed redirect listener was called",
         List.length(redirects^) == 1,
       );
       installFailingFetch(500, "database unavailable");
       callServer("save", [])
       |> Js.Promise.then_(_ => Js.Promise.resolve(None))
       |> Js.Promise.catch(error =>
            Js.Promise.resolve(Some(Js.Exn.anyToExnInternal(error)))
          );
     })
  |> Js.Promise.then_(error => {
       switch (error) {
       | Some(Failure(message))
           when message == "fetchCallServer: 500 database unavailable" =>
         ()
       | Some(_) => failwith("a failed response rejected with another error")
       | None => failwith("a failed response resolved")
       };
       Js.Promise.resolve();
     });
