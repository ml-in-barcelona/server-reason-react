const React = require("react");
const ReactDOM = require("react-dom/server");

let aaa = React.createElement("button", { value: "aaa" });
let clon = React.cloneElement(aaa, { value: "bbb" });

console.log(ReactDOM.renderToString(clon));
