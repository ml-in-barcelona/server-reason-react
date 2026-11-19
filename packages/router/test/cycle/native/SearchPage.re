[@react.component]
let make =
    (
      ~workspaceId: WorkspaceId.t,
      ~search: Router.SearchResults.search,
      ~workspace: string,
    ) => {
  ignore(workspaceId);
  ignore(search.view);
  React.string(workspace);
};
