[@warning "-26-27"];

open Melange_json.Primitives;

[@react.client.component]
let make = (~searchText: string, ~selectedId: option(int), ~isEditing: bool) => {
  let navigate = DummyClientRouter.useNavigate();
  let (text, setText) = RR.useStateValue(searchText);
  let (isSearching, startSearching) = React.useTransition();

  let onSubmit = event => {
    React.Event.Form.preventDefault(event);
  };

  let%browser_only onChange = event => {
    let target = React.Event.Form.target(event);
    let nextText = target##value;
    setText(nextText);
    startSearching(() =>
      navigate({
        searchText: Some(nextText),
        selectedId,
        isEditing,
      })
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
