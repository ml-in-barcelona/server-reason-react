module Forward = {
  [@react.component]
  let make = (~children) => children;
};

let host = () =>
  <div>
    <span> {React.string("a")} </span>
    <span> {React.string("b")} </span>
  </div>;

let fragment = () =>
  <>
    <span> {React.string("a")} </span>
    <span> {React.string("b")} </span>
  </>;

let component = () =>
  <Forward>
    <span> {React.string("a")} </span>
    <span> {React.string("b")} </span>
  </Forward>;

let singleton = () => <Forward> <span> {React.string("a")} </span> </Forward>;

let dynamic = () => {
  let children =
    React.list([
      React.createElement("span", [], [React.string("a")]),
      React.createElement("span", [], [React.string("b")]),
    ]);
  <Forward> children </Forward>;
};

let fragment_dynamic = () => {
  let children =
    React.array([|
      React.createElement("span", [], [React.string("a")]),
      React.createElement("span", [], [React.string("b")]),
    |]);
  <> children </>;
};

let mixed = () => {
  let children =
    React.list([
      React.createElement("span", [], [React.string("a")]),
      React.createElement("span", [], [React.string("b")]),
    ]);
  <div> <strong> {React.string("fixed")} </strong> children </div>;
};
