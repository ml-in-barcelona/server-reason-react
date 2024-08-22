// import this to be defined before we import React/ReactDOM
window.__webpack_require__ = (id) => {
  let component = window.__exported_components[id];
  if (component == null)
    throw new Error(`unable to resolve client component "${id}"`);
  return { __esModule: true, default: component };
};

let React = require('react');
let ReactDOM = require('react-dom/client');
let ReactServerDOMWebpack = require("react-server-dom-webpack/client.browser");

let rsc = null;

function App() {
  if (!rsc) {
    rsc = ReactServerDOMWebpack.createFromFetch(
      fetch("/demo/server-components", {
        headers: {
          Accept: "text/x-component",
        },
      })
    );
  }

  return rsc;
}

let root = ReactDOM.createRoot(document.getElementById("root"));

root.render(
  <React.Suspense fallback="Loading...">
    <App />
  </React.Suspense>
);
