[@warning "-26-27"];

[@react.component]
let make = () => {
  let (text, setText) = React.useState(() => None);
  let (isSearching, startSearching) = React.useTransition();
  let {navigate, _}: Router.t = Router.useRouter();

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
      {React.string("Search for a note by title")}
    </label>
    /* <input id="sidebar-search-input" placeholder="Search" value onChange /> */
    <Spinner active=isSearching />
  </form>;
};
