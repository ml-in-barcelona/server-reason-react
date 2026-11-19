[@react.client.component]
let make = (~children: React.element) => {
  let (search, _) = Router.useSearch();
  <Router.NewNote search className=Theme.button> children </Router.NewNote>;
};
