window.__webpack_require__ = async (id) => {
  let component = window.__exported_components[id];
  console.log("REQUIRE", id, component);
  if (component === undefined) {
    throw new Error(`Component "${id}" not found`);
  }
  return component;
};

let React = require("react");
let ReactDOM = require("react-dom/client");
/* let ReactServerDOMWebpack = require("react-server-dom-webpack/client"); */
let Noter = require("./app/demo/universal/js/Noter.js");

try {
  ReactDOM.hydrateRoot(document.getElementById("root"), <Noter.make />);
} catch (e) {
  console.error(e);
}
