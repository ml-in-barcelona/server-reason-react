  $ cat > input.re << EOF
  >  [@react.component]
  >  let make = () => {
  >    let (state, dispatch) = React.useReducer(reducer, initialState);
  > 
  >    React.useEffect0(() => {
  >      dispatch @@ UsersRequestStarted;
  >      None;
  >    });
  > 
  >    <div />;
  >  };
  > EOF

  $ refmt --parse re --print ml input.re > input.ml

With -js flag everything keeps as it is

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let state, dispatch = React.useReducer reducer initialState in
    React.useEffect0 (fun () ->
        dispatch @@ UsersRequestStarted;
        None);
    div ~children:[] () [@JSX]
  [@@react.component]

Without -js flag, we add the browser_only transformation and browser_only applies the transformation to fail_impossible_action_in_ssr

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let state, dispatch = React.useReducer reducer initialState in
    React.useEffect0 (fun () ->
        Runtime.fail_impossible_action_in_ssr "<unkwnown>");
    div ~children:[] () [@JSX]
  [@@react.component]

  $ cat > input.re << EOF
  >  [@react.component]
  >  let make = () => {
  >  React.useEffect2(
  >    () => {
  >      if (uiState == Submitted) {
  >        dispatch @@
  >        CurrentPasswordUpdated(
  >          switch (currentPassword) {
  >          | WithValue(value) when value == "" => Empty
  >          | _ => currentPassword
  >          },
  >        );
  > 
  >        switch (currentPassword, newPassword) {
  >        | (WithValue(currentPassword), Valid(newPassword)) when currentPassword != "" =>
  >          passwordReset({oldPassword: currentPassword, newPassword}, dispatch, onConfirmed)
  >        | _ => dispatch @@ SubmitTriggered(Idle)
  >        };
  >      };
  >      None;
  >    },
  >    (uiState, newPassword),
  >  );
  > 
  >    <div />;
  >  };
  > EOF

  $ refmt --parse re --print ml input.re > input.ml

Without -js flag, we add the browser_only transformation and browser_only applies the transformation to fail_impossible_action_in_ssr

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    React.useEffect2 (fun () ->
        Runtime.fail_impossible_action_in_ssr "<unkwnown>");
    div ~children:[] () [@JSX]
  [@@react.component]

  $ cat > input.re << EOF
  >  [@react.component]
  >  let make = () => {
  >    let (state, dispatch) = React.useReducer(reducer, initialState);
  > 
  >   React.useEffect2(
  >     [%browser_only
  >       () => {
  >            let handler = Js.Global.setTimeout(~f=_ => setDebouncedValue(focusedEntryText), delayInMs);
  >         Some(_ => Js.Global.clearTimeout(handler));
  >       }
  >     ],
  >     (focusedEntryText, delayInMs),
  >   );
  > 
  >    <div />;
  >  };
  > EOF

  $ refmt --parse re --print ml input.re > input.ml

With -js flag everything keeps as it is

  $ ./standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let state, dispatch = React.useReducer reducer initialState in
    React.useEffect2
      (fun () ->
        let handler =
          Js.Global.setTimeout
            ~f:(fun _ -> setDebouncedValue focusedEntryText)
            delayInMs
        in
        (Some (fun _ -> Js.Global.clearTimeout handler) [@explicit_arity]))
      (focusedEntryText, delayInMs);
    div ~children:[] () [@JSX]
  [@@react.component]

Without -js flag, we add the browser_only transformation and browser_only applies the transformation to fail_impossible_action_in_ssr

  $ ./standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let state, dispatch = React.useReducer reducer initialState in
    React.useEffect2
      (fun () -> Runtime.fail_impossible_action_in_ssr "<unkwnown>")
      (focusedEntryText, delayInMs);
    div ~children:[] () [@JSX]
  [@@react.component]
