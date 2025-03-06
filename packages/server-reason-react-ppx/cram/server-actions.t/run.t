  $ ../ppx.sh --output re -melange input.re
  let some_action = (~a: string, ~b: int) => {
    let location = Webapi.Dom.window |> Webapi.Dom.Window.location;
    let encodeArgs =
      "{"
      ++ String.concat(
           ",",
           List.map(
             ((key, value)) => key ++ ":" ++ value,
             [
               (
                 "a",
                 Ppx_deriving_json_runtime.to_string([%to_json: string](a)),
               ),
               ("b", Ppx_deriving_json_runtime.to_string([%to_json: int](b))),
             ],
           ),
         )
      ++ "}";
    let body = Fetch.BodyInit.make(encodeArgs);
    let basePath =
      switch (SRRServer.baseRoute) {
      | Some(baseRoute) => baseRoute
      | None => ""
      };
    Fetch.fetchWithInit(
      Webapi.Dom.Location.origin(location) ++ basePath ++ "623496469",
      Fetch.RequestInit.make(~method_=Post, ~credentials=Include, ~body, ()),
    )
    |> Js.Promise.then_(result =>
         try(Fetch.Response.json(result)) {
         | exn => Js.Promise.reject(exn)
         }
       )
    |> Js.Promise.then_(json => Js.Promise.resolve([%of_json: string](json)));
  };
  let some_action_with_default = (~a: string, ~b: int=?) => {
    let location = Webapi.Dom.window |> Webapi.Dom.Window.location;
    let encodeArgs =
      "{"
      ++ String.concat(
           ",",
           List.map(
             ((key, value)) => key ++ ":" ++ value,
             [
               (
                 "a",
                 Ppx_deriving_json_runtime.to_string([%to_json: string](a)),
               ),
               ("b", Ppx_deriving_json_runtime.to_string([%to_json: int](b))),
             ],
           ),
         )
      ++ "}";
    let body = Fetch.BodyInit.make(encodeArgs);
    let basePath =
      switch (SRRServer.baseRoute) {
      | Some(baseRoute) => baseRoute
      | None => ""
      };
    Fetch.fetchWithInit(
      Webapi.Dom.Location.origin(location) ++ basePath ++ "756355748",
      Fetch.RequestInit.make(~method_=Post, ~credentials=Include, ~body, ()),
    )
    |> Js.Promise.then_(result =>
         try(Fetch.Response.json(result)) {
         | exn => Js.Promise.reject(exn)
         }
       )
    |> Js.Promise.then_(json => Js.Promise.resolve([%of_json: string](json)));
  };
  let some_action = (~a: string, ~b as c: int) => {
    let location = Webapi.Dom.window |> Webapi.Dom.Window.location;
    let encodeArgs =
      "{"
      ++ String.concat(
           ",",
           List.map(
             ((key, value)) => key ++ ":" ++ value,
             [
               (
                 "a",
                 Ppx_deriving_json_runtime.to_string([%to_json: string](a)),
               ),
               ("c", Ppx_deriving_json_runtime.to_string([%to_json: int](c))),
             ],
           ),
         )
      ++ "}";
    let body = Fetch.BodyInit.make(encodeArgs);
    let basePath =
      switch (SRRServer.baseRoute) {
      | Some(baseRoute) => baseRoute
      | None => ""
      };
    Fetch.fetchWithInit(
      Webapi.Dom.Location.origin(location) ++ basePath ++ "675402916",
      Fetch.RequestInit.make(~method_=Post, ~credentials=Include, ~body, ()),
    )
    |> Js.Promise.then_(result =>
         try(Fetch.Response.json(result)) {
         | exn => Js.Promise.reject(exn)
         }
       )
    |> Js.Promise.then_(json => Js.Promise.resolve([%of_json: string](json)));
  };
  module Nested = {
    let some_action = (~a: string, ~b: int) => {
      let location = Webapi.Dom.window |> Webapi.Dom.Window.location;
      let encodeArgs =
        "{"
        ++ String.concat(
             ",",
             List.map(
               ((key, value)) => key ++ ":" ++ value,
               [
                 (
                   "a",
                   Ppx_deriving_json_runtime.to_string([%to_json: string](a)),
                 ),
                 (
                   "b",
                   Ppx_deriving_json_runtime.to_string([%to_json: int](b)),
                 ),
               ],
             ),
           )
        ++ "}";
      let body = Fetch.BodyInit.make(encodeArgs);
      let basePath =
        switch (SRRServer.baseRoute) {
        | Some(baseRoute) => baseRoute
        | None => ""
        };
      Fetch.fetchWithInit(
        Webapi.Dom.Location.origin(location) ++ basePath ++ "1009279222",
        Fetch.RequestInit.make(~method_=Post, ~credentials=Include, ~body, ()),
      )
      |> Js.Promise.then_(result =>
           try(Fetch.Response.json(result)) {
           | exn => Js.Promise.reject(exn)
           }
         )
      |> Js.Promise.then_(json => Js.Promise.resolve([%of_json: string](json)));
    };
  };
  let some_action = [%ocaml.error
    "server_action: expected a function that returns a Js.Promise.t"
  ];
  let some_action = [%ocaml.error
    "server-reason-react: action args need to be labelled arguments"
  ];
  let some_action = [%ocaml.error
    "server-reason-react: action args need to be type annotated labelled arguments"
  ];
 

  $ ../ppx.sh --output re input.re
  [@react.server.action]
  let some_action = (~a: string, ~b: int): Js.Promise.t(string) =>
    Promise.resolve(a ++ string_of_int(b));
  SRRServer.register_action(
    ~route={
      let basePath =
        switch (SRRServer.baseRoute) {
        | Some(baseRoute) => baseRoute
        | None => ""
        };
      basePath ++ "623496469";
    },
    ~handler=body => {
      let args = Yojson.Basic.from_string(body);
      let%lwt result =
        some_action(
          ~a=[%of_json: string](Yojson.Basic.Util.member("a", args)),
          ~b=[%of_json: int](Yojson.Basic.Util.member("b", args)),
        );
      Js.Promise.resolve(
        Ppx_deriving_json_runtime.to_string([%to_json: string](result)),
      );
    },
  );
  [@react.server.action]
  let some_action_with_default = (~a: string, ~b: int=10): Js.Promise.t(string) =>
    Promise.resolve(a ++ string_of_int(b));
  SRRServer.register_action(
    ~route={
      let basePath =
        switch (SRRServer.baseRoute) {
        | Some(baseRoute) => baseRoute
        | None => ""
        };
      basePath ++ "756355748";
    },
    ~handler=body => {
      let args = Yojson.Basic.from_string(body);
      let%lwt result =
        some_action_with_default(
          ~a=[%of_json: string](Yojson.Basic.Util.member("a", args)),
          ~b=[%of_json: option(int)](Yojson.Basic.Util.member("b", args)),
        );
      Js.Promise.resolve(
        Ppx_deriving_json_runtime.to_string([%to_json: string](result)),
      );
    },
  );
  [@react.server.action]
  let some_action = (~a: string, ~b as c: int): Js.Promise.t(string) =>
    Promise.resolve(a ++ string_of_int(c));
  SRRServer.register_action(
    ~route={
      let basePath =
        switch (SRRServer.baseRoute) {
        | Some(baseRoute) => baseRoute
        | None => ""
        };
      basePath ++ "675402916";
    },
    ~handler=body => {
      let args = Yojson.Basic.from_string(body);
      let%lwt result =
        some_action(
          ~a=[%of_json: string](Yojson.Basic.Util.member("a", args)),
          ~b=[%of_json: int](Yojson.Basic.Util.member("c", args)),
        );
      Js.Promise.resolve(
        Ppx_deriving_json_runtime.to_string([%to_json: string](result)),
      );
    },
  );
  module Nested = {
    [@react.server.action]
    let some_action = (~a: string, ~b: int): Js.Promise.t(string) =>
      Promise.resolve(a ++ string_of_int(b));
    SRRServer.register_action(
      ~route={
        let basePath =
          switch (SRRServer.baseRoute) {
          | Some(baseRoute) => baseRoute
          | None => ""
          };
        basePath ++ "1009279222";
      },
      ~handler=body => {
        let args = Yojson.Basic.from_string(body);
        let%lwt result =
          some_action(
            ~a=[%of_json: string](Yojson.Basic.Util.member("a", args)),
            ~b=[%of_json: int](Yojson.Basic.Util.member("b", args)),
          );
        Js.Promise.resolve(
          Ppx_deriving_json_runtime.to_string([%to_json: string](result)),
        );
      },
    );
  };
  [@react.server.action]
  let some_action = (~a: string, ~b: int): string =>
    Promise.resolve(a ++ string_of_int(b));
  [%ocaml.error
    "server_action: expected a function that returns a Js.Promise.t"
  ];
  [@react.server.action]
  let some_action = (a: string, ~b: int): Js.Promise.t(string) =>
    Promise.resolve(a ++ string_of_int(b));
  [%ocaml.error
    "server-reason-react: action args need to be labelled arguments"
  ];
  [@react.server.action]
  let some_action = (~a, ~b: int): Js.Promise.t(string) =>
    Promise.resolve(a ++ string_of_int(b));
  [%ocaml.error
    "server-reason-react: action args need to be type annotated labelled arguments"
  ];
