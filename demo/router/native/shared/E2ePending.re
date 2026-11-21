[@react.client.component]
let make = () => {
  let pending = RouterReact.useIsPending(Router.E2eSlow.destination());
  let active =
    RouterReact.useIsActive(
      ~activeWhen=RouterReact.Subtree,
      Router.E2e.destination(),
    );
  let (clicks, setClicks) = RR.useStateValue(0);
  let (_, updateSearch) = Router.useSearch();
  let%melange_only onSearch = _ =>
    updateSearch({ Router.text: Some("pending") }) |> ignore;
  <div className="flex flex-row gap-2">
    <span id="slow-pending">
      {React.string(pending ? "pending" : "idle")}
    </span>
    <span id="checks-active">
      {React.string(active ? "active" : "inactive")}
    </span>
    <button
      id="pending-click" type_="button" onClick={_ => setClicks(clicks + 1)}>
      {React.string("Clicked " ++ string_of_int(clicks))}
    </button>
    <button id="pending-search" type_="button" onClick=onSearch>
      {React.string("Update the search")}
    </button>
  </div>;
};
