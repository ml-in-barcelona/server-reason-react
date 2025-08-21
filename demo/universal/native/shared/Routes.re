let home = "/";
let renderToStaticMarkup = "/demo/render-to-static-markup";
let renderToString = "/demo/render-to-string";
let renderToStream = "/demo/render-to-stream";
let serverOnlyRSC = "/demo/server-only-rsc";
let singlePageRSC = "/demo/single-page-rsc";
let routerRSC = "/demo/router-rsc";
let dummyRouterRSC = "/demo/dummy-router-rsc";
let routerRSCNoSSR = "/demo/router-rsc-no-ssr";

let links = [|
  ("Server side render to string (renderToString)", renderToString),
  (
    "Server side render to static markup (renderToStaticMarkup)",
    renderToStaticMarkup,
  ),
  ("Server side render to stream (renderToStream)", renderToStream),
  ("React Server components without client (createFromFetch)", serverOnlyRSC),
  (
    "React Server components with createFromReadableStream (RSC + SSR)",
    singlePageRSC,
  ),
  (
    "React Server components with single page router (createFromFetch + createFromReadableStream)",
    routerRSC,
  ),
  (
    "React Server components without SSR with single page ro(createFromFetch + createFromReadableStream)",
    dummyRouterRSC,
  ),
  (
    "React Server components with single page router (createFromFetch + createFromReadableStream) + No SSR",
    routerRSCNoSSR,
  ),
|];

module Menu = {
  [@react.component]
  let make = () => {
    <ul className="flex flex-col gap-4">
      {links
       |> Array.map(((title, href)) =>
            <li> <Link.WithArrow href> title </Link.WithArrow> </li>
          )
       |> React.array}
    </ul>;
  };
};
