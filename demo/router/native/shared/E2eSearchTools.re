[@react.client.component]
let make = () => {
  let (navigate, _) = Router.useNavigation();
  let (search, _) = Router.E2eSearch.useSearch();
  let updateSearch = Router.E2eSearch.useUpdateSearch();
  let%melange_only go = next =>
    navigate(Router.E2eSearch.destination(~search=next, ())) |> ignore;
  let%melange_only onPanel = _ =>
    go({
      ...search,
      panel: Some("p1"),
    });
  let%melange_only onView = _ =>
    go({
      ...search,
      view: Some("v2"),
    });
  let%melange_only append = (current: Router.E2eSearch.search) => {
    ...current,
    panel: Some(Option.value(current.panel, ~default="") ++ "x"),
  };
  let%melange_only onBatch = _ => {
    updateSearch(~history=Router.Navigation.Push, append) |> ignore;
    updateSearch(~history=Router.Navigation.Push, append) |> ignore;
  };
  <div className="flex flex-row gap-2">
    <span id="client-panel">
      {React.string(Option.value(search.panel, ~default="none"))}
    </span>
    <button id="navigate-panel" type_="button" onClick=onPanel>
      {React.string("Change the panel")}
    </button>
    <button id="navigate-view" type_="button" onClick=onView>
      {React.string("Change the view")}
    </button>
    <button id="batch-panel" type_="button" onClick=onBatch>
      {React.string("Append to the panel twice")}
    </button>
  </div>;
};
