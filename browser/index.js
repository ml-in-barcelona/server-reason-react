const React = window.React;
const ReactDOM = window.ReactDOM;

let app = (value) => {
  return React.createElement("div", { key: "fi", style: { color: "blue" } }, [
    "first",
  ]);
};

let root = document.querySelector("#root");
ReactDOM.hydrate(React.createElement(app, null, null), root);
