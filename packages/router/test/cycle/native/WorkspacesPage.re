[@react.component]
let make = (~page: int, ~searchText: option(string)) => {
  ignore(page);
  ignore(searchText);
  React.string("workspaces");
};
