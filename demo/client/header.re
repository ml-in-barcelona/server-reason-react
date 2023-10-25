switch (ReactDOM.querySelector("#root")) {
| Some(el) =>
  let _root = ReactDOM.Client.hydrateRoot(el, <Shared_js.Ahrefs />);
  ();
| None => ()
};
