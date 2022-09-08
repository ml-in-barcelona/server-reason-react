open React.Dom.Dsl;
open Html;

let s = React.string;

[@react.component]
let make = (~title, ~children) => {
  <div> ...{[<span> {title |> s} </span>, ...children]} </div>;
};
