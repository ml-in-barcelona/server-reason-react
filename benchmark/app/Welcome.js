const React = require("react");

const Link = require("./Link.js").default;
const PageContainer = require("./PageContainer.js").default;

function PageWelcome() {
  return React.createElement(PageContainer, {
    children: React.createElement(
      React.Fragment,
      undefined,
      React.createElement(
        "h1",
        {
          className: "font-semibold text-xl tracking-tight mb-8",
        },
        "OCaml native webapp with SSR + React hydration"
      ),
      React.createElement("h2", undefined, "Hello"),
      React.createElement(
        "ul",
        {
          className: "list-disc list-inside mb-8",
        },
        [
          React.createElement(Link, {
            url: "/hello",
            txt: "hiya",
          }),
          React.createElement(Link, {
            url: "/hello/中文",
            txt: "中文",
          }),
          React.createElement(Link, {
            url: "/hello/Deutsch",
            txt: "Deutsch",
          }),
          React.createElement(Link, {
            url: "/hello/English",
            txt: "English",
          }),
        ].map((_i, x) =>
          React.createElement(
            "li",
            {
              key: String(_i),
            },
            x
          )
        )
      ),
      React.createElement("h2", undefined, "Excerpts"),
      React.createElement(
        "ul",
        {
          className: "list-disc list-inside mb-8",
        },
        [
          React.createElement(Link, {
            url: "/excerpts/add",
            txt: "Add Excerpt",
          }),
          React.createElement(Link, {
            url: "???",
            txt: "Authors with excerpts",
          }),
        ].map(function (_i, x) {
          return React.createElement(
            "li",
            {
              key: String(_i),
            },
            x
          );
        })
      ),
      React.createElement("h2", undefined, "Other examples"),
      React.createElement(
        "ul",
        {
          className: "list-disc list-inside mb-8",
        },
        React.createElement(
          React.Fragment,
          undefined,
          React.createElement(
            "li",
            undefined,
            React.createElement(Link, {
              url: "counter!:",
              txt: "Counter",
            })
          )
        )
      )
    ),
  });
}

exports.default = PageWelcome;
