[@react.client.component]
let make = (~fallback: React.element, ~children: React.element) =>
  RouterCatch.make(~fallback, ~children);
