[@react.client.component]
let make = (~search: Router.Inspector.search) =>
  <span> {React.string(search.target)} </span>;
