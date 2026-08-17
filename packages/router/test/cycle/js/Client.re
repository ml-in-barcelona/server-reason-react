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
  let ({ Router.page, searchText: _ }, updateSearch) = Router.useSearch();
  let route = Router.useRoute();
  let updateResult = updateSearch(~page=page + 1, ~searchText=None, ());
  (route, updateResult, Router.useUpdateHash());
};
