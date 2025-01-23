let%browser_only mockInitWebsocket = () => [%mel.raw
  {|
  function mockInitWebsocket() {
    console.log("Load JS");
  }
|}
];

let _ = mockInitWebsocket();

let element = Webapi.Dom.Document.querySelector("#root", Webapi.Dom.document);

switch (element) {
| Some(el) =>
  let _ = ReactDOM.Client.hydrateRoot(el, <App />);
  ();
| None => Js.log("No root element found")
};
