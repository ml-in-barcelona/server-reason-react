[@react.client.component]
let make = (~children: React.element) => {
  let { Router.searchText } = Router.useSearch();
  Router.NewNote.link(
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
