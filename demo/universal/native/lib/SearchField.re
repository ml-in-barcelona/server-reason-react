[@warning "-26-27"];

[@react.client.component]
let make = () => {
  let (text, setText) = RR.useStateValue(None);
  let {navigate, location, _}: ClientRouter.t = ClientRouter.useRouter();
  let (isSearching, startSearching) = React.useTransition();

  let onSubmit = event => {
    React.Event.Form.preventDefault(event);
  };

  let%browser_only onChange = event => {
    let target = React.Event.Form.target(event);
    let newText = target##value;
    setText(Some(newText));
    startSearching(() =>
      navigate({
        searchText: Some(newText),
        selectedId: location.selectedId,
        isEditing: location.isEditing,
      })
    );
  };

  let value = {
    switch (text) {
    | Some(text) => text
    | None => ""
    };
  };

  <form className="search" role="search" onSubmit>
    <label className="offscreen mr-4" htmlFor="sidebar-search-input">
      <Text> "Search for a note by title" </Text>
    </label>
    <InputText id="sidebar-search-input" placeholder="Search" value onChange />
    <Spinner active=isSearching />
  </form>;
};
