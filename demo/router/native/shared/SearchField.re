[@react.client.component]
let make = () => {
  let ({ Router.text }, updateSearch) = Router.useSearch();
  let routerText = text |> Option.value(~default="");
  let (text, setText) =
    React.Experimental.useOptimistic(routerText, (_current, next) => next);
  let (isSearching, startSearching) = React.useTransition();

  let onSubmit = event => {
    React.Event.Form.preventDefault(event);
  };

  let%browser_only onChange = event => {
    let target = React.Event.Form.target(event);
    let nextText = target##value;
    let next = nextText == "" ? None : Some(nextText);
    startSearching(() => {
      setText(nextText);
      let _ = updateSearch(~text=next, ());
      ();
    });
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
    <Spinner active=isSearching label="Filtering notes" />
  </form>;
};
