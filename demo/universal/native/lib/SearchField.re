[@warning "-26-27"];

open Ppx_deriving_json_runtime.Primitives;

[@react.client.component]
let make = (~searchText: string, ~selectedId: option(int), ~isEditing: bool) => {
  let {navigate, _}: ClientRouter.t = ClientRouter.useRouter();
  let (text, setText) =
    RR.useStateValue(searchText == "" ? None : Some(searchText));
  let (isSearching, startSearching) = React.useTransition();

  React.useEffect(() => {
    Js.log2("searchText", searchText);
    None;
  });

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
        selectedId,
        isEditing,
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
