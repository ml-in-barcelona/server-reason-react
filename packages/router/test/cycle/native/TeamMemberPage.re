[@react.component]
let make = (~teamId: WorkspaceId.t, ~search as _, ~member: string) => {
  React.string("member:" ++ WorkspaceId.to_string(teamId) ++ ":" ++ member);
};
