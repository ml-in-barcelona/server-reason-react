window.__webpack_require__ = (id) => {
  let component = window.__exported_components[id];
  if (component == null)
    throw new Error(`unable to resolve client component "${id}"`);
  return { __esModule: true, default: component };
};

window.__webpack_chunk_load__ = (id) => {
  let chunk = window.__exported_chunks[id];
  if (chunk == null) throw new Error(`unable to resolve client chunk "${id}"`);
  return { __esModule: true, default: chunk };
};

const React = require("react");
const ReactDOM = require("react-dom/client");
const ReactServerDOMWebpack = require("react-server-dom-webpack/client");


function callServer(id, args) {
  throw new Error(`callServer(${id}, ...): not supported yet`);
}


function Page({ loading }) {
  let tree = React.use(loading);
  return tree;
}

let fetchXcomponent = () => {
  return fetch("/demo/server-components", {
    method: 'GET',
    headers: {
      Accept: "text/x-component",
    },
  });
};

let rsc = null;

function App({ tree }) {
  let jsx = React.use(tree);
  return jsx;
}

const root = ReactDOM.createRoot(document.getElementById("root"));

React.startTransition(() => {
  rsc = ReactServerDOMWebpack.createFromFetch(fetchXcomponent(), { callServer });
  console.log("createFromFetch", rsc);

  root.render(
    <App tree={rsc} />
  );
});
