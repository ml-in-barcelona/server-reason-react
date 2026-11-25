let firstSeen = (cell, value) =>
  switch (cell^) {
  | Some(first) => first === value
  | None =>
    cell := Some(value);
    true;
  };

let seenNavigate = ref(None);
let seenUpdateSearch = ref(None);
let seenUpdateHash = ref(None);
let seenInvalidate = ref(None);

let%melange_only describe = result =>
  switch (result) {
  | RouterRuntime.Navigation.Result.Committed(committed) =>
    "committed " ++ committed.location.pathname ++ committed.location.search
  | RouterRuntime.Navigation.Result.Redirected(url) => "redirected " ++ url
  | RouterRuntime.Navigation.Result.Canceled => "canceled"
  | RouterRuntime.Navigation.Result.Failed(message) => "failed " ++ message
  };

[@react.client.component]
let make = () => {
  let (navigate, _) = Router.useNavigation();
  let (_, updateRouteSearch) = Router.useSearch();
  let (_, updateSearch) = RouterReact.useSearch();
  let updateHash = Router.useUpdateHash();
  let invalidate = RouterReact.useInvalidate();
  let (navigateResult, setNavigateResult) = RR.useStateValue("");
  let (identity, setIdentity) = RR.useStateValue("stable");
  let (renders, setRenders) = RR.useStateValue(0);
  let ((seenUpdateRouteSearch, seenProceed), _) =
    React.useState(() => (ref(None), ref(None)));
  let (blocking, setBlocking) = RR.useStateValue(false);
  let (actionState, setActionState) = RR.useStateValue("idle");
  let blocker = RouterReact.useBlocker(blocking);
  React.useEffect(() => {
    let proceedStable =
      switch (blocker) {
      | RouterReact.Blocked({ proceed, _ }) =>
        firstSeen(seenProceed, proceed)
      | RouterReact.Unblocked =>
        seenProceed := None;
        true;
      };
    let changed =
      [
        ("navigate", firstSeen(seenNavigate, navigate)),
        ("updateSearch", firstSeen(seenUpdateSearch, updateSearch)),
        (
          "Router.useSearch",
          firstSeen(seenUpdateRouteSearch, updateRouteSearch),
        ),
        ("updateHash", firstSeen(seenUpdateHash, updateHash)),
        ("invalidate", firstSeen(seenInvalidate, invalidate)),
        ("blocker", proceedStable),
      ]
      |> List.filter_map(((name, stable)) => stable ? None : Some(name));
    switch (changed) {
    | [] => ()
    | names => setIdentity("changed " ++ String.concat(" ", names))
    };
    None;
  });
  let%melange_only onCurrent = (~revalidate, _) => {
    setNavigateResult("pending");
    navigate(~revalidate, Router.E2e.destination())
    |> Js.Promise.then_(result => {
         setNavigateResult(describe(result));
         Js.Promise.resolve();
       })
    |> ignore;
  };
  let%melange_only onSearch = _ =>
    updateRouteSearch({ Router.text: Some("identity") }) |> ignore;
  let%melange_only onRerender = _ => setRenders(renders + 1);
  let%melange_only onRedirect = _ =>
    navigate(Router.unsafeDestination("/demo/router/e2e/old")) |> ignore;
  let%melange_only onHash = _ =>
    navigate(Router.E2e.destination(~hash="section", ())) |> ignore;
  let%melange_only onAction = _ => {
    setActionState("running");
    ServerFunctions.Notes.edit.call(
      ~id=0,
      ~title="Edited by the router checks",
      ~content="Edited by the router checks",
    )
    |> Js.Promise.then_(_ => {
         setActionState("done");
         Js.Promise.resolve();
       })
    |> ignore;
  };
  let%melange_only onEditNoteOne = _ => {
    setActionState("running");
    ServerFunctions.Notes.edit.call(
      ~id=1,
      ~title="Edited note 1",
      ~content="Edited note 1",
    )
    |> Js.Promise.then_(_ => {
         setActionState("done");
         Js.Promise.resolve();
       })
    |> ignore;
  };
  let%melange_only onBlock = _ => setBlocking(!blocking);
  let%melange_only onRedirectAction = _ =>
    E2eActions.redirectToLong.call() |> ignore;
  <div className="flex flex-col gap-2">
    <button id="navigate-redirect" type_="button" onClick=onRedirect>
      {React.string("Navigate to a redirect")}
    </button>
    <button id="navigate-hash" type_="button" onClick=onHash>
      {React.string("Navigate to the section")}
    </button>
    <button
      id="navigate-current"
      type_="button"
      onClick={onCurrent(~revalidate=false)}>
      {React.string("Navigate to this page")}
    </button>
    <button
      id="navigate-current-revalidate"
      type_="button"
      onClick={onCurrent(~revalidate=true)}>
      {React.string("Navigate to this page and revalidate")}
    </button>
    <span id="navigate-result"> {React.string(navigateResult)} </span>
    <button id="search-update" type_="button" onClick=onSearch>
      {React.string("Update the search")}
    </button>
    <button id="rerender" type_="button" onClick=onRerender>
      {React.string("Render again")}
    </button>
    <span id="hook-identity"> {React.string(identity)} </span>
    <button id="server-action" type_="button" onClick=onAction>
      {React.string("Run a server function")}
    </button>
    <button id="server-action-1" type_="button" onClick=onEditNoteOne>
      {React.string("Edit note 1")}
    </button>
    <span id="action-state"> {React.string(actionState)} </span>
    <button id="redirect-action" type_="button" onClick=onRedirectAction>
      {React.string("Run a server function that redirects")}
    </button>
    <button id="toggle-blocker" type_="button" onClick=onBlock>
      {React.string(blocking ? "Stop blocking" : "Block navigation")}
    </button>
    {switch (blocker) {
     | RouterReact.Unblocked =>
       <span id="blocker-state"> {React.string("unblocked")} </span>
     | RouterReact.Blocked({ target, proceed, cancel, _ }) =>
       <span id="blocker-state">
         {React.string("blocked " ++ target)}
         <button id="blocker-proceed" type_="button" onClick={_ => proceed()}>
           {React.string("Leave")}
         </button>
         <button id="blocker-cancel" type_="button" onClick={_ => cancel()}>
           {React.string("Stay")}
         </button>
       </span>
     }}
  </div>;
};
