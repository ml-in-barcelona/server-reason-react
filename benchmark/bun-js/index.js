const React = require("react");
const ReactDOMServer = require("react-dom/server");
const page = require("../app/app");

export default {
  port: 7070,
  fetch() {
    return new Response(
      `<div id="root">${ReactDOMServer.renderToString(
        React.createElement(page, null)
      )}</div>`
    );
  },
};
