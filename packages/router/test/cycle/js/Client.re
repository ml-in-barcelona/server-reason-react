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

let assetHref =
  Router.Asset.href(
    ~parts=["img", "caf" ++ Js.String.fromCharCode(233), "a+b"],
    (),
  );

let scalarHref = value =>
  Router.Scalar.href(~scalarId=ScalarId.make(value), ());

let useGeneratedClientHooks = () => {
  let ({ Router.page, searchText: _ }, updateSearch) = Router.useSearch();
  let route = Router.useRoute();
  let updateResult = updateSearch(~page=page + 1, ~searchText=None, ());
  (route, updateResult, Router.useUpdateHash());
};
