const React = require("react");
const ReactDOM = require("react-dom/server");

let aaa = React.createElement("div", { value1: "aaa", style: { "margin": "1px" } }, ["first"]);
let clon = React.cloneElement(aaa, { value: "bbb", more: 22, style: { "margin": "1", "padding": "0px" } }, ["asdf"]);

console.log(ReactDOM.renderToString(clon));
