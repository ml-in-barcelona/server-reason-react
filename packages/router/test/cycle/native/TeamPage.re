[@react.component]
let make = (~teamId: WorkspaceId.t, ~page: int, ~searchText: option(string)) => {
  ignore(page);
  ignore(searchText);
  React.string("team:" ++ WorkspaceId.to_string(teamId));
};
