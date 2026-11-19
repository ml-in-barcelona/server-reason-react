[@react.component]
let make = (~scalarId: ScalarId.t, ~search as _) => {
  React.string(scalarId);
};
