let _ = Shared.MelRaw.mockInitWebsocket();

switch (ReactDOM.querySelector("#root")) {
| Some(el) =>
  let _root = ReactDOM.Client.hydrateRoot(el, <Shared.App />);
  ();
| None => ()
};
