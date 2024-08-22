let home = "/";
let renderToStaticMarkup = "/demo/renderToStaticMarkup";
let renderToString = "/demo/renderToString";
let renderToLwtStream = "/demo/renderToLwtStream";
let serverComponents = "/demo/server-components";
let serverComponentsApi = "/api/server-components";

let links = [|
  ("Render to static markup (SSR)", renderToStaticMarkup),
  ("Render to string (SSR)", renderToString),
  ("Render to Lwt_stream (SSR)", renderToLwtStream),
  ("Server components", serverComponents),
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
