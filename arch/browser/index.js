const React = window.React;
const ReactDOM = window.ReactDOM;

const app = () => {
  return React.createElement("div", { key: "fi", style: { color: "blue" } }, [
    "first",
  ]);
};

const root = document.querySelector("#root");
ReactDOM.hydrate(React.createElement(app, null, null), root);

/*  */

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
