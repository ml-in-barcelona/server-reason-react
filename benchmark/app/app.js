const React = require("react")

const Shared = require("../../_build/default/client/app/shared/js/App.js");

const page = () =>
  React.createElement(
    "html",
    null,
    React.createElement(
      "head",
      null,
      " ",
      React.createElement("title", null, " ", "SSR React", " "),
      " "
    ),
    React.createElement(
      "body",
      null,
      React.createElement(
        "div",
        {
          id: "root",
        },
        React.createElement(Shared.make, null)
      ),
      React.createElement("script", {
        src: "/static/client.js",
      })
    )
  );

module.exports = page
