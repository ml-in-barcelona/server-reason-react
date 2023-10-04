switch (ReactDOM.querySelector("#root")) {
| Some(el) => ReactDOM.hydrate(<Shared_js.Ahrefs />, el)
| None => ()
};
