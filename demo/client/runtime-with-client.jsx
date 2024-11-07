window.__webpack_require__ = (id) => {
  let component = window.__client_manifest_map[id];
  console.log("REQUIRE ---");
  console.log(id);
  console.log(component);
  console.log("---");
  if (component === undefined) {
    throw new Error(`Component "${id}" not found`);
  }
  /* return {__esModule: true, default: component}; */
  return component;
};

let React = require("react");
let ReactDOM = require("react-dom/client");
let ReactServerDOM = require("react-server-dom-webpack/client");

window.__client_manifest_map = {};

let register = (name, render) => {
  window.__client_manifest_map[name] = render;
};

register("Note_editor", () => {
  return "null"
});

register("Counter", () => {
  return "null"
});

/* register("Note_editor", () => {
  return React.lazy(() => import("./app/demo/universal/js/Note_editor.js").then(v => v.make));
});

register("Counter", () => {
  return React.lazy(() => import("./app/demo/universal/js/Counter.js").then(v => v.make));
}); */

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
    console.error(error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return <h1>Something went wrong</h1>;
    }

    return this.props.children;
  }
}

function Use({ promise }) {
  try {
    let tree = React.use(promise);
    return tree;
} catch (e) {
    if (e instanceof Promise) throw e; // Suspense boundary catch
    console.error(e);
    return <h1>Something went wrong</h1>;
  }
}

try {
  /* let _ = ReactDOM.hydrateRoot(document.getElementById("root"), <Noter.make />); */

  /* let loading
  if (window.srr_stream) {
    loading = ReactServerDOM.createFromReadableStream(
      window.srr_stream.readable_stream,
      {
        callServer: function callServer(id, args) {
          throw new Error(`callServer(${id}, ...): not supported yet`);
        }
      }
    );
    React.startTransition(() => {
      root = ReactDOM.hydrateRoot(document,
        <React.StrictMode>
          <Page loading={loading} />
        </React.StrictMode>
      );
    });
  } */

  /* function fetchRSC(path) {
    return fetch(path, {
      method: 'GET',
      headers: { Accept: 'application/react.component' },
    });
  };

  let loading = ReactServerDOM.createFromFetch(fetchRSC(window.location.href),
    {
      callServer: function callServer(id, args) {
        throw new Error(`callServer(${id}, ...): not supported yet`);
      }
    });
  let root = ReactDOM.createRoot(document);
  root.render(
    <React.StrictMode>
      <Page loading={loading} />
    </React.StrictMode>
  ); */

  /* console.log(window.srr_stream.readable_stream); */

  /* const mockPayload = [`1:"$Sreact.suspense"\n
0:["$","html",null,{"children":[["$","head",null,{"children":["$","title",null,{"children":"Test"}]}],["$","body",null,{"children":[["$","a",null,{"href":"/","children":"Go home"}]," | ",["$","a",null,{"href":"/about","children":"Go to about"}],["$","$1",null,{"children":["$","div",null,{"children":["$","h1",null,{"children":"Home"}]}]}]]}]]}]`]; */
  /* const mockPayload = ["0:["$","div",null,{"className":"foo"}]\n", "1:null\n"]; */
  /* const mockPayload = [`0:[null]\n`, `1:"$Sreact.suspense"\n`]; */
  /* <h1> {"Hello"} </h1> */
  /* window.srr_stream.push('0:I["$","div","0",{"children":[["$","h1","0",{"children":["Hellowww"]}]],"id":"root"}]'); */
  /* const mockPayload = [`0:["$","h1",null,{"children":["Hellowww"]}]\n`]; */
  /* const mockPayload = [`0:I["$","div","0",{"children":[["$","h1","0",{"children":["Hellowww"]}]],"id":"root"}]\n`]; */
  /* const mockPayload = [
    `0:I["$","div","0",{"children":[["$","div","0",{"children":[["$","div","0",{"children":["This is Light Server Component"]}],["$","div","0",{"children":[["$","div","0",{"children":[],"title":"Light Component"}]]}]]}],["$","div","0",{"children":["Heavy Server Component"]}]],"id":"root"}]\n`,
  ]; */

  /* const mockPayload = [
    `a:["$","div",null,{"children":["Sleep ",1,"s","$undefined"]}]\n`,
    `1:["$L7",["$","div",null,{"children":["Home Page",["$","$8",null,{"fallback":"Fallback 1","children":"$L9"}]]}],null]\n`,
    `9:["$","div",null,{"children":["Sleep ",1,"s",["$","$8",null,{"fallback":"Fallback 2","children":"$La"}]]}]\n`,
    `7:"$Sreact.suspense"\n`,
  ]; */
  /* const mockPayload = [
    `7:"$Sreact.suspense"\n`,
    `1:["$L7",["$","div",null,{"children":["Home Page",["$","$8",null,{"fallback":"Fallback 1","children":"$L9"}]]}],null]\n`,
    `9:["$","div",null,{"children":["Sleep ",1,"s",["$","$8",null,{"fallback":"Fallback 2","children":"$La"}]]}]\n`,
    `a:["$","div",null,{"children":["Sleep ",1,"s","$undefined"]}]\n`,
  ]; */
  /*  const rscPayload = [
     `7:"$Sreact.suspense"`,
     `1:["$L7",["$","div",null,{"children":["Home Page",["$","$8",null,{"fallback":"Fallback 1","children":"$L9"}]]}],null]`,
     `9:["$","div",null,{"children":["Sleep ",1,"s",["$","$8",null,{"fallback":"Fallback 2","children":"$La"}]]}]`,
     `a:["$","div",null,{"children":["Sleep ",1,"s","$undefined"]}]`
   ]; */

  /* const rscPayload = [
    "1:I[\"./client-component.js\",[],\"Client_component\"]",
    "0:[[\"$\",\"span\",null,{\"children\":\"Hello!!!\"}],[\"$\",\"$1\",null,{}]]",
  ]; */

  /* let result = MyReactServerDOM.to_model (xxxxxxxxx) */
  /* load into file (result) */
  /* node debug-rsc.js (result) */
  /* cram test */

  /** @type {ReadableStream<Uint8Array>} */
  /* let mockReadableStream = new ReadableStream({
    start(stream) {
      const textEncoder = new TextEncoder();

      for (let chunk of rscPayload) {
        stream.enqueue(textEncoder.encode(chunk + '\n'));
      }
      stream.close();
    }
  }); */

  const debug = readableStream => {
    const reader = readableStream.getReader();
    const debugReader = ({ done, value }) => {
      if (done) {
        console.log("Stream complete");
        return;
      }
      console.log(value);
      return reader.read().then(debugReader);
    };
    reader.read().then(debugReader);
  };

  const stream = window.srr_stream.readable_stream;
  const promise = ReactServerDOM.createFromReadableStream(stream);
  let app = <ErrorBoundary><Use promise={promise} /></ErrorBoundary>;
  let element = document.getElementById("root");
  ReactDOM.hydrateRoot(element, app);
} catch (e) {
  console.error(e);
}
