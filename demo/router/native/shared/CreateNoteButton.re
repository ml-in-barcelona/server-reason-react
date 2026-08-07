[@react.client.component]
let make = (~children: React.element) => {
  let ({ Router.searchText }, _) = Router.useSearch();
  <Router.NewNote ?searchText className=Theme.button>
    children
  </Router.NewNote>;
};
