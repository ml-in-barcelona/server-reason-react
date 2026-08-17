[@react.client.component]
let make = (~noteId: NoteId.t, ~children: React.element) => {
  let ({ Router.text }, _) = Router.useSearch();
  <Router.EditNote id=noteId ?text className=Theme.button>
    children
  </Router.EditNote>;
};
