[@react.component]
let make =
    (
      ~workspaceId: WorkspaceId.t,
      ~page: int,
      ~searchText: option(string),
      ~filter: option(Filter.t),
      ~view: option(NoteId.t),
      ~workspace: string,
    ) => {
  ignore(workspaceId);
  ignore(page);
  ignore(searchText);
  ignore(filter);
  ignore(view);
  React.string(workspace);
};
