const React = require("react");
const utils = require("util");
const ReactDOM = require("react-dom/server");

let first = React.createElement(
  "div",
  { key: "fi", value1: "aaa", style: { margin: "1px" } },
  ["first"]
);
let clon = React.cloneElement(
  first,
  { value: "bbb", more: 22, style: { margin: "1", padding: "0px" } },
  ["asdf"]
);

const { Provider, Consumer } = React.createContext(10);

var app = () => {
  /* https://fb.me/react-uselayouteffect-ssr */
  React.useLayoutEffect(() => {
    console.log("asdfdsf");

    return () => {
      console.log("asdfsdf");
    };
  });
  return React.createElement("div", { className: "contenido" }, []);
};

var app = () => {
  let [state, setState] = React.useState(0);

  React.useEffect(() => {
    setState(state + 1);
    console.log("asdfdsf");

    return () => {
      console.log("asdfsdf");
    };
  });
  return React.createElement("div", { className: "contenido" }, []);
};

var app = () => {
  let [state, setState] = React.useState(0);
  let ref = React.useRef(true);
  console.log(state);
  if (ref.current) {
    setState(state + 1);
    ref.current = false;
  }
  React.useEffect(() => {
    console.log("asfsdafsafsadf");
  });
  React.useEffect(() => {
    console.log("asfsdafsafsadf");
  }, [state]);
  console.log(state);
  return React.createElement("div", null, [state]);
};

/* var app = () => {
  return React.createElement("div", {
    dangerouslySetInnerHTML: { __html: "asdf" },
  });
}; */

var ctx = React.createContext(10);

var context_user = () => {
  let a = React.useContext(ctx);
  console.log(a);
  return React.createElement("div", { key: 1 }, [a]);
};

var app = () => {
  let ref = React.useRef(333);
  console.log(ref);
  return React.createElement(
    ctx.Provider,
    { value: 0, ref: ref },
    React.createElement(context_user)
  );
};

var app = React.forwardRef(() => {
  let ref = React.useRef(333);
  console.log(ref);
  return React.createElement(
    ctx.Provider,
    { value: 0, ref: ref },
    React.createElement(context_user)
  );
});

console.log(ReactDOM.renderToStaticMarkup(React.createElement(app, null)));
