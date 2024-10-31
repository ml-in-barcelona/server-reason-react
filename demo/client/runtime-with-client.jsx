window.__webpack_require__ = (id) => {
  let component = window.__exported_components[id];
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
let Noter = require("./app/demo/universal/js/Noter.js");

function Use({ promise }) {
  let tree = React.use(promise);
  return tree;
};

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

  const rscPayload = [
    /* `0:["$","div",null,{"children":["Hello"]}]`, */
    /* "0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"span\",null,{\"children\":\"Home\"}],[\"$\",\"span\",null,{\"children\":\"Nohome\"}]]}]", */
    "1:I[\"./client-component.js\",[],\"Client_component\"]",
    "0:[[\"$\",\"span\",null,{\"children\":\"Hello!!!\"}],[\"$\",\"$1\",null,{}]]",
  ];

  /* let result = MyReactServerDOM.to_model (xxxxxxxxx) */
  /* load into file (result) */
  /* node debug-rsc.js (result) */
  /* cram test */

  /** @type {ReadableStream<Uint8Array>} */
  let mockReadableStream = new ReadableStream({
    start(stream) {
      const textEncoder = new TextEncoder();

      for (let chunk of rscPayload) {
        stream.enqueue(textEncoder.encode(chunk + '\n'));
      }
      stream.close();
    }
  });

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

  const promise = ReactServerDOM.createFromReadableStream(mockReadableStream);
  console.log(promise);

  window.__exported_components["./client-component.js"] = { Client_component: () => <div>Client</div> };

  const element = document.getElementById("root");
  root = ReactDOM.createRoot(element);
  root.render(<React.Suspense fallback={"LOADING?!?!?!?!"}>
    <Use promise={promise} />
  </React.Suspense>);

} catch (e) {
  console.error(e);
}