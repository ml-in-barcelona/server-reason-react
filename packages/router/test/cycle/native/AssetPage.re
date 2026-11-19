[@react.component]
let make = (~parts: list(string), ~search as _) => {
  React.string(Router.Asset.href(~parts, ()));
};
