type verticalAlign = [ | `top | `center | `bottom];
type horizontalAlign = [ | `left | `center | `right];

[@react.component]
let make:
  (~h: horizontalAlign, ~v: verticalAlign, ~children: React.element) =>
  React.element;
