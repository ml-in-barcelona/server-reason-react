[@react.client.component]
let make = (~noteId: NoteId.t, ~children: React.element) => {
  let (search, _) = Router.useSearch();
  <Router.EditNote id=noteId search className=Theme.button>
    children
  </Router.EditNote>;
};
