let shouldFail = ref(false);
let fail = () => shouldFail := true;
let reset = () => shouldFail := false;

let render = (~workspaceId, ~id, ~search, ~workspace, ~noteAccess) =>
  if (shouldFail^) {
    raise(Failure("private page failure"));
  } else {
    React.string(
      workspace
      ++ ":"
      ++ Int.to_string(noteAccess)
      ++ ":"
      ++ Router.Note.href(~workspaceId, ~id, ~search, ()),
    );
  };

[@react.component]
let make =
    (
      ~workspaceId: WorkspaceId.t,
      ~id: NoteId.t,
      ~search: Router.Note.search,
      ~workspace: string,
      ~noteAccess: int,
    ) =>
  render(~workspaceId, ~id, ~search, ~workspace, ~noteAccess);

module Edit = {
  [@react.component]
  let make =
      (
        ~workspaceId: WorkspaceId.t,
        ~id: NoteId.t,
        ~search: Router.EditNote.search,
        ~workspace: string,
        ~noteAccess: int,
      ) =>
    render(
      ~workspaceId,
      ~id,
      ~search=
        Router.Note.search(
          ~page=search.page,
          ~searchText=?search.searchText,
          ~filter=?search.filter,
          (),
        ),
      ~workspace,
      ~noteAccess,
    );
};
