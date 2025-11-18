open Melange_json.Primitives;

type t = React.element;

let context = React.createContext(React.null);
/*

 /* visitor tree */
 /* history virtual */

 {
   path: "/",
   loader: (_) => {},
 },
 {
   path: "/student",
   loader: (_) => {},
 },
           /* fetch student/123?rsc=123 */
           /* new_outlet = <Route path="/student/:id" layout={<AppLayout />} outlet={<Student />} /> */
           /* loader(new_outlet) */
           /* render */
 {
   path: "/student/:id",
   loader: (_) => {},
 },
 */

module Outlet = {
  [@react.client.component]
  let make = () => {
    let value = React.useContext(context);

    value;
  };
};

module Provider = {
  let provider = React.Context.provider(context);
  [@react.client.component]
  let make = (~value: React.element, ~children: React.element) => {
    switch%platform (Runtime.platform) {
    | Client =>
      React.createElement(
        provider,
        {
          "value": value,
          "children": children,
        },
      )
    | Server => provider(~value, ~children, ())
    };
  };
};

/**
* Route is the component that renders and registers the route.
* It also provides the loader to update page/subroutes when the route is navigated to.
*/
[@react.client.component]
let make =
    (~path: string, ~layout: React.element, ~outlet: option(React.element)) => {
  let (outlet, setOutlet) =
    React.useState(() => outlet |> Option.value(~default=React.null));
  let isFirstRender = React.useRef(true);
  let (cachedNodeKey, setCachedNodeKey) = React.useState(() => path);

  let%browser_only loader = routeElement => {
    setOutlet(_ => routeElement);
    // This is a hack to force a re-render of the route by changing the key
    // Is there a better way to do this?
    setCachedNodeKey(_ => Js.Date.now() |> string_of_float);
  };

  /**
  * Register the route and the loader function.
  * The loader function is used to update the page/subroutes.
  */
  (
    if (isFirstRender.current) {
      isFirstRender.current = false;
      RouteRegistry.register(~path, ~loader);
    }
  );

  /**
  * outlet is the component that will be rendered as
  * the child of the current route, representing the page/subroute content. It's the value of 'children' on
  * the layout component.
  * layout is the component that remains the same across all subroutes.
  * Ref: https://nextjs.org/docs/pages/building-your-application/routing/pages-and-layouts
  */
  <Provider
    value={<React.Fragment key=cachedNodeKey> outlet </React.Fragment>}>
    layout
  </Provider>;
};
