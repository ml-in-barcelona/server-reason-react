let home = "/";
let renderToStaticMarkup = "/demo/renderToStaticMarkup";
let renderToString = "/demo/renderToString";
let renderToStream = "/demo/renderToStream";
let createFromFetch = "/demo/server-components-without-client";
let createFromReadableStream = "/demo/server-components";

let links = [|
  ("Render to static markup (SSR)", renderToStaticMarkup),
  ("Render to string (SSR)", renderToString),
  ("Render to stream (SSR)", renderToStream),
  ("Server components without client (createFromFetch)", createFromFetch),
  (
    "Server components with createFromReadableStream (RSC + SSR)",
    createFromReadableStream,
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
