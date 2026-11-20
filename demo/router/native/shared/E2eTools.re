[@react.client.component]
let make = () => {
  let (navigate, _) = Router.useNavigation();
  let (blocking, setBlocking) = RR.useStateValue(false);
  let (actionState, setActionState) = RR.useStateValue("idle");
  let blocker = RouterReact.useBlocker(blocking);
  let%melange_only onRedirect = _ =>
    navigate(Router.unsafeDestination("/demo/router/e2e/old")) |> ignore;
  let%melange_only onHash = _ =>
    navigate(Router.E2e.destination(~hash="section", ())) |> ignore;
  let%melange_only onRefreshInPlace = _ =>
    navigate(
      ~history=Replace,
      ~revalidate=true,
      ~resetScroll=false,
      Router.E2e.destination(),
    )
    |> ignore;
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
    <button id="refresh-in-place" type_="button" onClick=onRefreshInPlace>
      {React.string("Refresh in place")}
    </button>
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
