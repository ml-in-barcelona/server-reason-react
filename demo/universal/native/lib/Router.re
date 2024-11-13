let home = "/";
let renderToStaticMarkup = "/demo/renderToStaticMarkup";
let renderToString = "/demo/renderToString";
let renderToStream = "/demo/renderToStream";
let serverComponentsWithoutClient = "/demo/server-components-without-client";
let serverComponents = "/demo/server-components";

let links = [|
  ("Render to static markup (SSR)", renderToStaticMarkup),
  ("Render to string (SSR)", renderToString),
  ("Render to Stream (SSR)", renderToStream),
  (
    "Server components without client (createFromFetch)",
    serverComponentsWithoutClient,
  ),
  ("Server components (RSC + SSR)", serverComponents),
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
