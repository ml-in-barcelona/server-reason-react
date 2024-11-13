const React = require("react");
const ReactServerDOM = require("react-server-dom-webpack/server");

let sleep = (ms, value) => new Promise(resolve => setTimeout(() => resolve(value), ms));


let Text = ({children}) => React.createElement("span", {}, children);
/* let App = () => {
  return React.createElement("div", null, [
    React.createElement("span", {key: "home"}, ["Home"]),
    React.createElement("span", {key: "nohome"}, ["Nohome"]),
  ]);
}; */

/* let Text = async ({children}) => {
  let value = await sleep(2000, "lola");
  return value;
};

let ClientComponent = {
  $$typeof: Symbol.for("react.client.reference"),
  $$id: "ClientComponent",
  $$async: false,
  default: () => "Hello from the client!",
  name: "ClientComponent",
};

let App = () => {
  return React.createElement(React.Suspense, {fallback: "Loading..."}, [
    React.createElement(Text, {key: "hi"}, "hi"),
    React.createElement(ClientComponent.default, {key: "cc"}, []),
  ]);
};

let main = React.createElement(App, {}, []);
 */

/* let App = () => {
  return React.createElement("div", {dangerouslySetInnerHTML: {__html: "console.log(\"hi\")"}}, []);
}; */

  /* let app codition =
    React.Upper_case_component
      (fun () ->
        let text = if codition then "foo" else "bar" in
        React.createElement "span" [] [ React.string text ])
  in */

/* let Foo = () => {
  return React.createElement("span", {}, "foo");
};

let App = () => {
  return React.createElement(Foo, {}, []);
}; */

/* let Text = ({children}) => React.createElement("span", {}, children);

let App = () => ([
  React.createElement(Text, {}, "hi"),
  React.createElement(Text, {}, "hola"),
]); */

// 2:["$","span",null,{"children":"hi"},"$3"]
// 4:["$","span",null,{"children":"hola"},"$5"]
// 0:["$2","$4"]

/* let Layout = ({children}) => React.createElement("div", {}, children);


let App = () =>
  React.createElement(
    Layout,
    {},
    [
      React.createElement(Text, {key: "hi"}, "hi"),
      React.createElement(Text, {key: "hola"}, "hola"),
    ],
  ); */

  /* let app () =
    React.Suspense.make
      ~fallback:(React.string "Loading...")
      ~children:
        (React.createElement "div" []
           [
             React.Upper_case_component (text ~children:[ React.string "hi" ]);
             React.Upper_case_component (text ~children:[ React.string "hola" ]);
           ])
      ()
  in
  let main = React.Upper_case_component app in
  let%lwt stream = ReactServerDOM.render_to_model main in */

let App = () => {
  return React.createElement(React.Suspense, {fallback: "Loading..."}, [
    React.createElement("div", null, [
      React.createElement(Text, null, "hi"),
      React.createElement(Text, null, "hola"),
]),
  ]);
};

let {pipe} = ReactServerDOM.renderToPipeableStream(App());

pipe(process.stdout);
