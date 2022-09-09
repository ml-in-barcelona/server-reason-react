const React = require("react");
const ReactDOM = require("react-dom/server");

let ref = React.createRef();
let aaa = React.createElement("button", { value: "aaa", ref });

console.log(ReactDOM.renderToString(aaa));
