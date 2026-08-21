[@react.component]
let make =
    (
      ~teamId: WorkspaceId.t,
      ~page: int,
      ~searchText: option(string),
      ~member: string,
    ) => {
  ignore(page);
  ignore(searchText);
  React.string("member:" ++ WorkspaceId.to_string(teamId) ++ ":" ++ member);
};
