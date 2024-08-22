let _ = MelRaw.mockInitWebsocket();

switch (ReactDOM.querySelector("#root")) {
| Some(el) =>
  let _ = ReactDOM.Client.hydrateRoot(el, <App />);
  ();
| None => ()
};
