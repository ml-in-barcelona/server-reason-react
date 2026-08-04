let load =
    (
      ~workspaceId as _,
      ~id,
      ~page as _,
      ~searchText as _,
      ~filter as _,
      ~workspace,
      (),
    )
    : Lwt.t(RouterRuntime.Loader.result(int, string)) => {
  WorkspaceLoader.record("note:" ++ workspace);
  Lwt.return(RouterRuntime.Loader.Data(NoteId.toInt(id)));
};
