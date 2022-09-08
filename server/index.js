const React = require("react");
const ReactDOM = require("react-dom/server");

let aaa = React.createElement("input", {key:"p"})
let div = React.createElement("div", {key:"div"}, ["Hello World", aaa])
let body = React.createElement("body", null, div)

console.log(ReactDOM.renderToString(aaa));
