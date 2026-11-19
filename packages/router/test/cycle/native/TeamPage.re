[@react.component]
let make = (~teamId: WorkspaceId.t, ~search as _) => {
  React.string("team:" ++ WorkspaceId.to_string(teamId));
};
