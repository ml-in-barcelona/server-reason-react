import React from "react";
import ReactDOM from "react-dom/client";
import ReactServerDOM from "react-server-dom-webpack/client";

function Page({ promise }) {
	return React.use(promise);
}

let abortController = null;

const App = ({ promise }) => {
  return (
    <React.StrictMode><Page promise={promise} /></React.StrictMode>
  );
};

const fetchRSC = (path) => {
  return fetch(path, {
    method: 'GET',
    headers: {
      Accept: "text/x-component",
    },
    signal: abortController.signal,
  });
};

const renderPage = (pathname, search) => {
  React.startTransition(() => {
    if (abortController != null) {
      abortController.abort();
    }
    abortController = new AbortController();

    ReactServerDOM.createFromFetch(fetchRSC(pathname + search)).then(element => {
      let root = ReactDOM.createRoot(element);

      root.render(<App promise={promise} />);
  });
    /* let {pathname, search} = window.location;
    if (pathname + search !== path)
      window.history.pushState({}, null, path); */
  });
}

const callServer = (_id, _args) => {
  throw new Error(`callServer is not supported yet`);
}

const element = document.getElementById("root");
const stream = window.srr_stream && window.srr_stream.readable_stream;

if (stream) {
  const promise = ReactServerDOM.createFromReadableStream(stream, { callServer });
  React.startTransition(() => {
    ReactDOM.hydrateRoot(element, <App promise={promise} />);
  });
} else {
  let { pathname, search } = window.location;
  renderPage(pathname + search);
}

window.addEventListener("popstate", (_event) => {
  let {pathname, search} = window.location;
  renderPage(pathname + search);
});
