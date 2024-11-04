const React = require("react");
const ReactServerDOM = require("react-server-dom-webpack/server");

let sleep = (ms, value) => new Promise(resolve => setTimeout(() => resolve(value), ms));

let Text = async ({children}) => {
  let value = await sleep(2000, "lola");
  return value;
};

let App = () => {
  return React.createElement(React.Suspense, {fallback: "Loading..."}, [
    React.createElement(Text, {key: "hi"}, "hi"),
  ]);
};

let main = React.createElement(App, {}, []);

let {pipe} = ReactServerDOM.renderToPipeableStream(main);

pipe(process.stdout);
