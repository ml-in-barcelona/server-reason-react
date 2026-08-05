[@react.client.component]
let make = (~noteId: NoteId.t, ~children: React.element) => {
  let { Router.searchText } = Router.useSearch();
  <Router.EditNote.Link id=noteId ?searchText className=Theme.button>
    children
  </Router.EditNote.Link>;
};
