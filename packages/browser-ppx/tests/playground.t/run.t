  $ refmt --print ml ./input.re > input.ml

  $ ../standalone.exe -impl input.ml -js | refmt --parse ml --print re --print-width 120
  let makeQuery = (~abortController, ~encoding=?, pathname, req, input) => {
    let signal = abortController->Option.map(abortController => abortController->Fetch.AbortController.signal);
    let query = Js.Dict.empty();
    encoding->Option.forEach(enc => query->Js.Dict.set("mode", "csv-" ++ EncodingT.unwrap(enc)));
    let defaultPostHeaders = ("Content-Type", "application/json; charset=utf-8");
    switch (req.config.allowed_methods) {
    | GET_or_POST =>
      let queryParam = Sensitivity.to_query_param(req.config.sensitivity);
      let inputString = input->(req.writeInput)->Js.Json.stringify;
      let cloudflareLimit = 15000;
      let inputStringEncoded = inputString->Js.Global.encodeURIComponent;
      String.length(inputStringEncoded) > cloudflareLimit
        ? Fetch.fetchWithInit(
            Url.makeStringWithQueryDict(~pathname, ~query, ()),
            Fetch.RequestInit.make(
              ~method_=Post,
              ~body=inputString->Fetch.BodyInit.make,
              ~credentials=Include,
              ~headers=makeHeadersInit(~shouldBeGet=true, ~initHeaders=defaultPostHeaders, ()),
              ~signal?,
              (),
            ),
          )
        : {
          Js.Dict.set(query, queryParam, inputStringEncoded);
          Fetch.fetchWithInit(
            Url.makeStringWithQueryDict(~pathname, ~query, ~encode=false, ()),
            Fetch.RequestInit.make(~method_=Get, ~credentials=Include, ~headers=makeHeadersInit(), ~signal?, ()),
          );
        };
    | POST_only =>
      Fetch.fetchWithInit(
        Url.makeStringWithQueryDict(~pathname, ~query, ()),
        Fetch.RequestInit.make(
          ~method_=Post,
          ~body=input->(req.writeInput)->Js.Json.stringify->Fetch.BodyInit.make,
          ~credentials=Include,
          ~headers=makeHeadersInit(~initHeaders=defaultPostHeaders, ()),
          ~signal?,
          (),
        ),
      )
    };
  };

  $ ../standalone.exe -impl input.ml | refmt --parse ml --print re --print-width 120
  [@warning "-27-32"]
  let [@alert
        browser_only(
          "This expression is marked to only run on the browser where JavaScript can run. You can only use it inside a let%browser_only function.",
        )
      ]
      makeQuery =
    [@alert "-browser_only"]
    (
      (~abortController) =>
        [@ppxlib.migration.stop_taking]
        (
          (~encoding=?) =>
            [@ppxlib.migration.stop_taking]
            (
              pathname =>
                [@ppxlib.migration.stop_taking]
                (req => [@ppxlib.migration.stop_taking] (input => Runtime.fail_impossible_action_in_ssr("makeQuery")))
            )
        )
    );
