[@react.client.component]
let make = (~noteId: NoteId.t, ~children: React.element) => {
  let { Router.searchText } = Router.useSearch();
  Router.EditNote.link(
    ~id=noteId,
    ~searchText?,
    ~options={
      className: Some(Theme.button),
      target: None,
      download: None,
      ariaCurrent: None,
      history: Router.Navigation.Push,
      revalidate: false,
    },
    ~children,
    (),
  );
};
