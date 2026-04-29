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

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let state, dispatch = React.useReducer reducer initialState in
    React.useEffect0 (fun () ->
        dispatch @@ UsersRequestStarted;
        None);
    div ~children:[] () [@JSX]
  [@@react.component]

Without -js flag, we add the browser_only transformation and browser_only applies the transformation to fail_impossible_action_in_ssr

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let state, dispatch = React.useReducer reducer initialState in
    React.useEffect0 (fun () ->
        let _ = dispatch in
        Runtime.fail_impossible_action_in_ssr
          "fun () -> dispatch @@ UsersRequestStarted; None");
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

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    React.useEffect2
      (fun () ->
        let _ = uiState in
        let _ = dispatch in
        let _ = currentPassword in
        let _ = newPassword in
        let _ = passwordReset in
        let _ = onConfirmed in
        Runtime.fail_impossible_action_in_ssr
          "fun () ->\n\
          \  if uiState = Submitted\n\
          \  then\n\
          \    (dispatch @@\n\
          \       ((CurrentPasswordUpdated\n\
          \           ((match currentPassword with\n\
          \             | ((WithValue value)[@explicit_arity ]) when value = \
           \"\" -> Empty\n\
          \             | _ -> currentPassword)))\n\
          \       [@explicit_arity ]);\n\
          \     (match (currentPassword, newPassword) with\n\
          \      | (((WithValue currentPassword)[@explicit_arity ]), ((Valid\n\
          \         newPassword)[@explicit_arity ])) when currentPassword <> \
           \"\" ->\n\
          \          passwordReset { oldPassword = currentPassword; newPassword }\n\
          \            dispatch onConfirmed\n\
          \      | _ -> dispatch @@ ((SubmitTriggered Idle)[@explicit_arity ])));\n\
          \  None")
      (uiState, newPassword);
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

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
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

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let state, dispatch = React.useReducer reducer initialState in
    React.useEffect2
      (fun () ->
        let _ = setDebouncedValue in
        let _ = focusedEntryText in
        let _ = delayInMs in
        Runtime.fail_impossible_action_in_ssr
          "fun () ->\n\
          \  let handler =\n\
          \    Js.Global.setTimeout ~f:(fun _ -> setDebouncedValue \
           focusedEntryText)\n\
          \      delayInMs in\n\
          \  ((Some (fun _ -> Js.Global.clearTimeout handler))[@explicit_arity ])")
      (focusedEntryText, delayInMs);
    div ~children:[] () [@JSX]
  [@@react.component]
  $ cat > input.re << EOF
  >  [@react.component]
  >  let make = () => {
  >    let (state, dispatch) = React.useReducer(reducer, initialState);
  > 
  >    React.useEffect1(
  >      () => {
  >        isFocused ? onFocusedItemChange(domRef) : ();
  >        None;
  >      },
  >      [|isFocused|],
  >    );
  > 
  >    <div />;
  >  };
  > EOF

  $ refmt --parse re --print ml input.re > input.ml

With -js flag everything keeps as it is

  $ ../standalone.exe -impl input.ml -js | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let state, dispatch = React.useReducer reducer initialState in
    React.useEffect1
      (fun () ->
        (match isFocused with true -> onFocusedItemChange domRef | false -> ());
        None)
      [| isFocused |];
    div ~children:[] () [@JSX]
  [@@react.component]

Without -js flag, we add the browser_only transformation and browser_only applies the transformation to fail_impossible_action_in_ssr

  $ ../standalone.exe -impl input.ml | ocamlformat - --enable-outside-detected-project --impl
  let make () =
    let state, dispatch = React.useReducer reducer initialState in
    React.useEffect1
      (fun () ->
        let _ = isFocused in
        let _ = onFocusedItemChange in
        let _ = domRef in
        Runtime.fail_impossible_action_in_ssr
          "fun () ->\n\
          \  (match isFocused with | true -> onFocusedItemChange domRef | false \
           -> ());\n\
          \  None")
      [| isFocused |];
    div ~children:[] () [@JSX]
  [@@react.component]
