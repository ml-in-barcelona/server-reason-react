const React = require("react");
const ReactDOMServer = require("react-dom/server");
const express = require("express");
const page = require("../app/app");

const app = express();

app.get("/", (_req, res) => {
  return res.send(
    `<div id="root">${ReactDOMServer.renderToStaticMarkup(
      React.createElement(page, null)
    )}</div>`
  );
});

const PORT = 1337;

app.listen(PORT, () => {
  console.log(`Server is listening on port ${PORT}`);
});
