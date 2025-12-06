/**
* Route is the component that renders the route and provides the renderPage function to update page/subroutes when the route is navigated to.
* It push the route to the virtual history when mounted.\
*
* As the <Route/> is a client component, we cannot pass to the component the layout as a function component (~children: React.element) => React.element,
* so we need to pass the layout as a React.element and use the Provider to pass the children to the layout.
* That workaround allow us to update the page/subroutes when the route is nested.
*
* Path: /about/contact
*
* Example:
* <Route
*   path="/"
*   layout={<MainLayout />}
*   pageconsumer={
*     <Route
*       path="/about"
*       layout={<AboutLayout />}
*       pageconsumer={
*         <Route
*           path="/contact"
*           layout={<ContactLayout />}
*           pageconsumer={<ContactPage />}
*         />
*       }
*     />
*   }
*
* Visual representation of the route tree:
* <MainLayout>
*   <AboutLayout>
*     <ContactLayout>
*       <ContactPage />
*     </ContactLayout>
*   </AboutLayout>
* </MainLayout>
*/
open Melange_json.Primitives;

type t = React.element;

let context = React.createContext(React.null);

module PageConsumer = {
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

[@react.client.component]
let make =
    (
      ~path: string,
      ~layout: React.element,
      ~pageconsumer: option(React.element),
    ) => {
  let (pageconsumer, setPageConsumer) =
    React.useState(() => pageconsumer |> Option.value(~default=React.null));
  let isFirstRender = React.useRef(true);
  let (cachedNodeKey, setCachedNodeKey) = React.useState(() => path);

  let%browser_only renderPage = pageElement => {
    setPageConsumer(_ => pageElement);
    // This is a hack to force a re-render of the route by changing the key
    // Is there a better way to do this?
    setCachedNodeKey(_ => Js.Date.now() |> string_of_float);
  };

  /**
  * push the route to the virtual history.
  * The renderPage function is used to update the page/subroutes.
  */
  (
    switch%platform (Runtime.platform) {
    | Client =>
      if (isFirstRender.current) {
        isFirstRender.current = false;
        VirtualHistory.push(~path, ~renderPage);
      }
    | Server => ()
    }
  );

  /**
  * pageconsumer is the component that will be rendered as
  * the child of the current route, representing the page/subroute content. It's the value of 'children' on
  * the layout component.
  * layout is the component that remains the same across all subroutes.
  * Ref: https://nextjs.org/docs/pages/building-your-application/routing/pages-and-layouts
  */
  <Provider
    value={<React.Fragment key=cachedNodeKey> pageconsumer </React.Fragment>}>
    layout
  </Provider>;
};
