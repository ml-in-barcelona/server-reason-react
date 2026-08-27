[@react.component]
let make = (~scalarId: ScalarId.t, ~page: int, ~searchText: option(string)) => {
  ignore(page);
  ignore(searchText);
  React.string(scalarId);
};
