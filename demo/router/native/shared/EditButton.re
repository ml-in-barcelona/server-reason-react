[@react.client.component]
let make = (~noteId: NoteId.t, ~children: React.element) => {
  let ({ Router.searchText }, _) = Router.useSearch();
  <Router.EditNote id=noteId ?searchText className=Theme.button>
    children
  </Router.EditNote>;
};
