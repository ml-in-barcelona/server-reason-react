let home = "/";
let demoRenderToStaticMarkup = "/demo/renderToStaticMarkup";
let demoRenderToString = "/demo/renderToString";
let demoRenderToStream = "/demo/renderToStream";
let demoCreateFromFetch = "/demo/server-components-without-client";
let demoCreateFromReadableStream = "/demo/server-components";
let demoRouter = "/demo/router";

let links = [|
  ("Render to static markup (SSR)", demoRenderToStaticMarkup),
  ("Render to string (SSR)", demoRenderToString),
  ("Render to stream (SSR)", demoRenderToStream),
  ("Server components without client (createFromFetch)", demoCreateFromFetch),
  (
    "Server components with createFromReadableStream (RSC + SSR)",
    demoCreateFromReadableStream,
  ),
  ("Router", demoRouter),
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
