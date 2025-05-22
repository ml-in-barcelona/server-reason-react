let home = "/";
let demoRenderToStaticMarkup = "/demo/renderToStaticMarkup";
let demoRenderToString = "/demo/renderToString";
let demoRenderToStream = "/demo/renderToStream";
let demoServerOnlyRSC = "/demo/server-components-without-client";
let demoSinglePageRSC = "/demo/server-components";
let demoRouterSPA = "/demo/server-components-with-spa-router";

let links = [|
  ("Render to string (renderToString)", demoRenderToString),
  (
    "Render to static markup (renderToStaticMarkup)",
    demoRenderToStaticMarkup,
  ),
  ("Render to stream (renderToStream)", demoRenderToStream),
  ("Server components without client (createFromFetch)", demoServerOnlyRSC),
  (
    "Server components with createFromReadableStream (RSC + SSR)",
    demoSinglePageRSC,
  ),
  (
    "Single page router with navigations (createFromFetch + createFromReadableStream)",
    demoRouterSPA,
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
type location = {
  selectedId: option(int),
  isEditing: bool,
  searchText: option(string),
};

let locationToString = location =>
  [
    switch (location.selectedId) {
    | Some(id) => "selectedId=" ++ Int.to_string(id)
    | None => ""
    },
    "isEditing=" ++ (location.isEditing ? "true" : "false"),
    switch (location.searchText) {
    | Some(text) => "searchText=" ++ text
    | None => ""
    },
  ]
  |> List.filter(s => s != "")
  |> String.concat("&");

let initialLocation = {
  selectedId: None,
  isEditing: false,
  searchText: None,
};

let locationFromString = str => {
  switch (URL.make(str)) {
  | Some(url) =>
    let searchParams = URL.searchParams(url);
    let selectedId =
      URL.SearchParams.get(searchParams, "selectedId")
      |> Option.map(id => int_of_string(id));
    let searchText = URL.SearchParams.get(searchParams, "searchText");

    let isEditing =
      URL.SearchParams.get(searchParams, "isEditing")
      |> Option.map(v =>
           switch (v) {
           | "true" => true
           | "false" => false
           | _ => false
           }
         )
      |> Option.value(~default=false);

    {
      selectedId,
      isEditing,
      searchText,
    };

  | None => initialLocation
  };
};

type payload = {
  body: string,
  title: string,
};

/* 'a is melange-fetch's response in melange */
type t('a) = {
  location,
  navigate: location => unit,
  useAction: (string, string) => ((payload, location, unit) => unit, bool),
  refresh: option('a) => unit,
};

let useRouter = () => {
  location: initialLocation,
  navigate: _ => (),
  useAction: (_, _) => ((_, _, _) => (), false),
  refresh: _ => (),
};
