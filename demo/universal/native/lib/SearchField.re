[@warning "-26-27"];

[@react.component]
let make = () => {
  let (text, setText) = React.useState(() => None);
  let (isSearching, startSearching) = React.useTransition();
  let {navigate, _}: ClientRouter.t = ClientRouter.useRouter();

  let onSubmit = event => {
    React.Event.Form.preventDefault(event);
  };

  let%browser_only onChange = event => {
    let target = React.Event.Form.target(event);
    let newText = target##value;
    Js.log(newText);
    /* setText(() => Some(newText)); */
    /* startSearching(() => navigate({searchText: newText})); */
  };

  let value = {
    switch (text) {
    | Some(text) => text
    | None => ""
    };
  };

  <form className="search" role="search" onSubmit>
    <label className="offscreen" htmlFor="sidebar-search-input">
      <Text> "Search for a note by title" </Text>
    </label>
    <input
      id="sidebar-search-input"
      placeholder="Search"
      defaultValue=value
      onChange
    />
    <Spinner active=isSearching />
  </form>;
};
