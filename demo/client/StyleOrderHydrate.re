let element = Webapi.Dom.Document.querySelector("#root", Webapi.Dom.document);

switch (element) {
| Some(el) =>
  let _ = ReactDOM.Client.hydrateRoot(el, <StyleOrderRepro />);
  ();
| None => Js.log("No root element found")
};
