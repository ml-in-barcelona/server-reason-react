const React = require("react");
const utils = require("util");
const ReactDOM = require("react-dom/server");

let first = React.createElement(
  "div",
  { key: "fi", value1: "aaa", style: { margin: "1px" } },
  ["first"]
);
let clon = React.cloneElement(
  first,
  { value: "bbb", more: 22, style: { margin: "1", padding: "0px" } },
  ["asdf"]
);

const { Provider, Consumer } = React.createContext(10);

let app = () => {
  return React.createElement("div", null, [
    React.createElement(
      Provider,
      {
        key: 1,
        value: "correct",
      },
      React.createElement(Consumer, null, (value) =>
        React.createElement("section", null, "value is: ")
      )
    ),
  ]);
};

console.log(ReactDOM.renderToStaticMarkup(app()));
