module App = {
  [@react.component]
  let make = () => {
    <Layout background=Theme.Color.black> <Router.Menu /> </Layout>;
  };
};

let handler = request =>
  Dream_rsc.createFromRequest(
    <App />,
    "/static/demo/client/router.js",
    request,
  );
