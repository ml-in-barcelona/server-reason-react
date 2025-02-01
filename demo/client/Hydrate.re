let%browser_only mockInitWebsocket: unit => unit =
  () => [%mel.raw
    {|
  function mockInitWebsocket() {
    console.log("Load JS");
  }
|}
  ];

mockInitWebsocket();

let element = Webapi.Dom.Document.querySelector("#root", Webapi.Dom.document);

switch (element) {
| Some(el) =>
  let _ = ReactDOM.Client.hydrateRoot(el, <App />);
  ();
| None => Js.log("No root element found")
};
