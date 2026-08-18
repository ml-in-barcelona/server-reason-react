[@react.component]
let make = (~parts: list(string), ~page: int, ~searchText: option(string)) => {
  ignore(page);
  ignore(searchText);
  React.string(Router.Asset.href(~parts, ()));
};
