let home = "/";
let renderToStaticMarkup = "/demo/renderToStaticMarkup";
let renderToString = "/demo/renderToString";
let renderToStream = "/demo/renderToStream";
let serverOnlyRSC = "/demo/serverOnlyRSC";
let singlePageRSC = "/demo/singlePageRSC";
let dummyRouterRSC = "/demo/dummyRouterRSC";
let dummyRouterRSCNoSSR = "/demo/dummyRouterRSC?ssr=false";
let router = "/demo/router";
let styleOrderHydration = "/demo/styleOrderHydration";

let links = [|
  (
    "renderToString",
    "Server side render a component (React.element) defining a static document into a string, the client rerenders the component (createRoot / render)",
    renderToString,
  ),
  (
    "renderToStaticMarkup",
    "Server side render a component (React.element) defining a document into a markup string (contains a few differences on the output compared to the renderToString version). The client hydrates it with the same component (hydrateRoot)",
    renderToStaticMarkup,
  ),
  (
    "renderToStream",
    "Server side render into a stream. A comments page that loads without any additional client-side code and just Suspense + streaming the HTML",
    renderToStream,
  ),
  (
    "serverOnlyRSC",
    "A client fetching a single react server component with createFromFetch",
    serverOnlyRSC,
  ),
  (
    "singlePageRSC",
    "A single page to with server components and SSR (with hydration), client components to test all props serialisation, including React.element and Js.Promise. Also renders Js.String/Js.Date JavaScript-identical values on the server (UTF-16 string semantics, local-time date parsing).",
    singlePageRSC,
  ),
  (
    "dummyRouterRSC",
    "A dummy implementation of a router (only a few queryStrings) as a single page app. Server components with SSR, client components and Suspense + React.use",
    dummyRouterRSC,
  ),
  (
    "dummyRouterRSC - without SSR",
    "The same demo as dummyRouterRSC but without SSR. It SSR the shell of the page (head, body, etc), but not the app itself.",
    dummyRouterRSCNoSSR,
  ),
  (
    "styleOrderHydration",
    "Minimal reproduction of a hydration mismatch (React #418) when inline-style CSS custom properties serialize in a different order on the server than on the client, as styled-ppx's CSS-extraction runtime surfaced (ahrefs/WEB-844). Must hydrate clean.",
    styleOrderHydration,
  ),
  (
    "nestedRouterRSC",
    "A nested router with server components and SSR, client components and Suspense + React.use. It uses the same design as the dummyRouterRSC but with a more complex structure that can handle nested routes and dynamic segments.",
    router,
  ),
|];

module Menu = {
  [@react.component]
  let make = () => {
    <ul className="flex flex-col gap-4 w-[500px]">
      {links
       |> Array.mapi((index, (title, description, href)) =>
            <li className="mb-4">
              <Link.WithArrow href>
                <div className="flex flex-col flex-1 gap-1 min-w-full">
                  <h2 className="text-xxl font-bold">
                    {React.int(index + 1)}
                    {React.string(". ")}
                    {React.string(title)}
                  </h2>
                  <p className="text-sm text-gray-500">
                    {React.string(description)}
                  </p>
                </div>
              </Link.WithArrow>
            </li>
          )
       |> React.array}
    </ul>;
  };
};
