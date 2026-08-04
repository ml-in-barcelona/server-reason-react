let shouldFail = ref(false);
let fail = () => shouldFail := true;
let reset = () => shouldFail := false;

let make =
    (
      ~workspaceId: WorkspaceId.t,
      ~id: NoteId.t,
      ~page: int,
      ~searchText: option(string),
      ~filter: option(Filter.t),
      ~workspace: string,
      ~noteAccess: int,
      (),
    ) =>
  if (shouldFail^) {
    raise(Failure("private page failure"));
  } else {
    React.string(
      workspace
      ++ ":"
      ++ Int.to_string(noteAccess)
      ++ ":"
      ++ Router.Note.href(
           ~workspaceId,
           ~id,
           ~page,
           ~searchText?,
           ~filter?,
           (),
         ),
    );
  };
