window.__webpack_require__ = async (id) => {
  console.log("window.__webpack_require__", id);
  return import(id);
};

const ReactDOM = require("react-dom/client");
const ReactServerDOMWebpack = require("react-server-dom-webpack/client");

let fetchXcomponent = () => {
  return fetch("/demo/server-components-without-client", {
    method: 'GET',
    headers: {
      Accept: "text/x-component",
    },
  });
};

const root = ReactDOM.createRoot(document.getElementById("root"));
let rsc = ReactServerDOMWebpack.createFromFetch(fetchXcomponent());
console.log("createFromFetch", rsc);
root.render(rsc);
