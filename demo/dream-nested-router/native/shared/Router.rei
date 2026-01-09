exception NoProvider(string);

type t =
  (~replace: bool=?, ~revalidate: bool=?, ~shallow: bool=?, string) => unit;
let use: unit => t;

[@react.client.component]
let make: (~children: React.element) => React.element;
