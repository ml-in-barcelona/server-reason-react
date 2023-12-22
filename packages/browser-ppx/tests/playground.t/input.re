let%browser_only makeQuery =
                 (~abortController, ~encoding=?, pathname, req, input) => {
  let signal =
    abortController->Option.map(abortController =>
      abortController->Fetch.AbortController.signal
    );
  let query = Js.Dict.empty();
  encoding->Option.forEach(enc =>
    query->Js.Dict.set("mode", "csv-" ++ EncodingT.unwrap(enc))
  );
  let defaultPostHeaders = (
    "Content-Type",
    "application/json; charset=utf-8",
  );
  switch (req.config.allowed_methods) {
  | GET_or_POST =>
    let queryParam = Sensitivity.to_query_param(req.config.sensitivity);
    let inputString = input->(req.writeInput)->Js.Json.stringify;
    let cloudflareLimit =
      /* Cloudflare limit is 16358: https://ahrefs.slack.com/archives/CUPHP0EP8/p1677644203445649?thread_ts=1677599205.939129&cid=CUPHP0EP8
         but we leave some room for headers and other parts of the req */
      15000;
    let inputStringEncoded = inputString->Js.Global.encodeURIComponent;
    String.length(inputStringEncoded) > cloudflareLimit
      ? Fetch.fetchWithInit(
          Url.makeStringWithQueryDict(~pathname, ~query, ()),
          Fetch.RequestInit.make(
            ~method_=Post,
            ~body=inputString->Fetch.BodyInit.make,
            ~credentials=Include,
            ~headers=
              makeHeadersInit(
                ~shouldBeGet=true,
                ~initHeaders=defaultPostHeaders,
                (),
              ),
            ~signal?,
            (),
          ),
        )
      : {
        Js.Dict.set(query, queryParam, inputStringEncoded);
        Fetch.fetchWithInit(
          Url.makeStringWithQueryDict(~pathname, ~query, ~encode=false, ()),
          Fetch.RequestInit.make(
            ~method_=Get,
            ~credentials=Include,
            ~headers=makeHeadersInit(),
            ~signal?,
            (),
          ),
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
