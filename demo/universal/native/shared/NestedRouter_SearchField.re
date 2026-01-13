[@react.client.component]
let make = () => {
  let { Router.navigate, url, _ } = Router.use();
  let queryParams = url |> URL.searchParams;
  let searchText =
    URL.SearchParams.get(queryParams, "searchText")
    |> Option.value(~default="");
  let (text, setText) = RR.useStateValue(searchText);
  let (isSearching, startSearching) = React.useTransition();

  let onSubmit = event => {
    React.Event.Form.preventDefault(event);
  };

  let%browser_only onChange = event => {
    let target = React.Event.Form.target(event);
    let nextText = target##value;
    let searchParams =
      URL.SearchParams.makeWithArray([|("searchText", nextText)|]);
    let path = url |> URL.pathname;
    setText(nextText);
    startSearching(() =>
      navigate(
        ~shallow=true,
        path ++ "?" ++ URL.SearchParams.toString(searchParams),
      )
    );
  };

  <form className="search" role="search" onSubmit>
    <label className="offscreen mr-4" htmlFor="sidebar-search-input">
      <Text> "Search for a note by title" </Text>
    </label>
    <InputText
      id="sidebar-search-input"
      placeholder="Search"
      value=text
      onChange
    />
    <Spinner active=isSearching />
  </form>;
};
