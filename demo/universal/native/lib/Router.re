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

type location = {
  selectedId: option(string),
  isEditing: bool,
  searchText: option(string),
};

let locationToString = location =>
  "selectedId="
  ++ (
    switch (location.selectedId) {
    | Some(id) => id
    | None => "None"
    }
  )
  ++ "&isEditing="
  ++ (location.isEditing ? "true" : "false")
  ++ "&searchText="
  ++ (
    switch (location.searchText) {
    | Some(id) => id
    | None => "None"
    }
  );

let initialLocation = {
  selectedId: None,
  isEditing: false,
  searchText: None,
};

let locationFromString = str => {
  switch (URL.make(str)) {
  | Some(url) =>
    let searchParams = URL.searchParams(url);
    let selectedId = URL.SearchParams.get(searchParams, "selectedId");
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

/* a is melange-fetch's response in melange */
type t('a) = {
  location,
  navigate: location => unit,
  refresh: option('a) => unit,
};

let useRouter = () => {
  location: initialLocation,
  navigate: _ => (),
  refresh: _ => (),
};
