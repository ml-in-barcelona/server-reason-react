window.__webpack_require__ = async (_id) => {
  throw new Error("This should never be called in this demo");
};

let ReactDOM = require("react-dom/client");
let ReactServerDOMWebpack = require("react-server-dom-webpack/client");

let fetchXcomponent = () => {
  return fetch("/demo/server-components-without-client", {
    method: 'GET',
    headers: {
      Accept: "text/x-component",
    },
  });
};

let root = ReactDOM.createRoot(document.getElementById("root"));

ReactServerDOMWebpack.createFromFetch(fetchXcomponent()).then(element => {
  root.render(element);
});
