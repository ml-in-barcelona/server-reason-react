const React = require("react");
const ReactServerDOM = require("react-server-dom-webpack/server");

var app = () => {
  return "hi";
};

let {pipe, abort} = ReactServerDOM.renderToPipeableStream("hi");

pipe(process.stdout);
