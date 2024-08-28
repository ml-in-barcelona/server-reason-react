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

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error) {
    // Update state so the next render will show the fallback UI.
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    // You can also log the error to an error reporting service
    console.log(error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      // You can render any custom fallback UI
      return <h1>Something went wrong.</h1>;
    }

    return this.props.children;
  }
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
  }).then(response => response.text());
};

let rsc = null;

function App({ tree }) {
  let jsx = React.use(tree);
  return jsx;
}

const root = ReactDOM.createRoot(document.getElementById("root"));

React.startTransition(() => {
  rsc = ReactServerDOMWebpack.createFromFetch(fetchXcomponent(), { callServer });
  console.log("???", rsc);

  root.render(
    <React.StrictMode>
      <ErrorBoundary>
        <App tree={rsc} />
      </ErrorBoundary>
    </React.StrictMode>
  );
});
