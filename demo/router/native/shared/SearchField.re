[@react.client.component]
let make = () => {
  let ({ Router.text: initialText }, updateSearch) = Router.useSearch();
  let (text, setText) =
    RR.useStateValue(initialText |> Option.value(~default=""));
  let (isSearching, startSearching) = React.useTransition();

  let onSubmit = event => {
    React.Event.Form.preventDefault(event);
  };

  let%browser_only onChange = event => {
    let target = React.Event.Form.target(event);
    let nextText = target##value;
    let next = nextText == "" ? None : Some(nextText);
    setText(nextText);
    startSearching(() => {
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
