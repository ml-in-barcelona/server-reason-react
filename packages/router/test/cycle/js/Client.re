let noteHref =
  Router.Note.href(
    ~workspaceId=WorkspaceId.make(7),
    ~id=NoteId.make(42),
    ~filter=Filter.make("active/" ++ Js.String.fromCharCode(252)),
    (),
  );

let quoteHref =
  Router.Note.href(
    ~workspaceId=WorkspaceId.make(7),
    ~id=NoteId.make(42),
    ~filter=Filter.make("it's"),
    (),
  );

let useGeneratedClientHooks = () => {
  let { Router.page, searchText: _ } = Router.useSearch();
  let isActive =
    Router.Note.useIsActive(
      ~workspaceId=WorkspaceId.make(7),
      ~id=NoteId.make(42),
      ~includeDescendants=true,
      (),
    );
  let updateResult =
    switch (Router.useUpdateSearch()) {
    | Some(updateSearch) =>
      Some(updateSearch(~page=page + 1, ~searchText=None, ()))
    | None => None
    };
  (isActive, updateResult, Router.useUpdateHash());
};
