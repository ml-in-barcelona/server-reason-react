module Dom = Webapi.Dom;

let element = Dom.Document.querySelector("#root", Dom.document);

switch (element) {
| Some(el) =>
  let root = ReactDOM.Client.createRoot(el);
  ReactDOM.Client.render(root, <App />);
| None => Js.log("No root element found")
};
