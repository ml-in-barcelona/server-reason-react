const React = require("react");
const ReactDOM = require("react-dom/server");

let first = React.createElement("div", { key: "fi", value1: "aaa", style: { "margin": "1px" } }, ["first"]);
let clon = React.cloneElement(first, { value: "bbb", more: 22, style: { "margin": "1", "padding": "0px" } }, ["asdf"]);

/* console.log(ReactDOM.renderToString(clon)); */

let ctx = React.createContext("3");
let Provider = ctx.Provider;

let component = () => {
  let what = React.useContext(ctx);
  console.log(what);
  return React.createElement(Provider, { key: "fi", value1: "aaa", style: { "margin": "1px" } }, ["first"])
}

console.log(ReactDOM.renderToString(component()));
