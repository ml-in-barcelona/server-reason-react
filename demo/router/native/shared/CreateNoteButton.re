[@react.client.component]
let make = (~children: React.element) => {
  let { Router.searchText } = Router.useSearch();
  <Router.NewNote.Link ?searchText className=Theme.button>
    children
  </Router.NewNote.Link>;
};
