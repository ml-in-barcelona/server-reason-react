[@react.client.component]
let make = (~children: React.element) => {
  let ({ Router.text }, _) = Router.useSearch();
  <Router.NewNote ?text className=Theme.button> children </Router.NewNote>;
};
