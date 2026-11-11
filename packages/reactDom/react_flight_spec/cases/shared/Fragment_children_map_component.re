/* A component returned from a Children.map callback passes its key path
   down: through an unkeyed fragment to a single child, and as the key of a
   fragment that wraps a multi-child fragment or a collection. */
module Single = {
  [@react.component]
  let make = () => <React.Fragment> <div /> </React.Fragment>;
};

module Shorthand = {
  [@react.component]
  let make = () => <> <div /> </>;
};

module Pair = {
  [@react.component]
  let make = () => <> <div /> <hr /> </>;
};

module Collection = {
  [@react.component]
  let make = () => React.array([|<div key="d" />, <hr key="h" />|]);
};

module Map_single = {
  [@react.component]
  let make = (~children) => React.Children.map(children, _ => <Single />);
};

module Map_shorthand = {
  [@react.component]
  let make = (~children) => React.Children.map(children, _ => <Shorthand />);
};

module Map_pair = {
  [@react.component]
  let make = (~children) => React.Children.map(children, _ => <Pair />);
};

module Map_collection = {
  [@react.component]
  let make = (~children) => React.Children.map(children, _ => <Collection />);
};

let app = () =>
  <section>
    <Map_single> <span /> </Map_single>
    <Map_shorthand> <span /> </Map_shorthand>
    <Map_pair> <span /> </Map_pair>
    <Map_collection> <span /> </Map_collection>
  </section>;
