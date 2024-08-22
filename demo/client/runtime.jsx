const React = require('react');
const ReactDOM = require('react-dom/client');
const ReactServerDOMWebpack = require("react-server-dom-webpack/client.browser");

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

const root = ReactDOM.createRoot(document.getElementById("root"));

root.render(
  <React.Suspense fallback="Loading...">
    <App />
  </React.Suspense>
);
