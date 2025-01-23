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

type t = {
  location,
  navigate: location => unit,
  /* refresh: Fetch.Response.t => unit, */
  refresh: unit => unit,
};

let initialLocation = {
  selectedId: None,
  isEditing: false,
  searchText: None,
};

let useRouter = () => {
  location: initialLocation,
  navigate: _ => (),
  refresh: _ => (),
};

/* module RouterContext = {
     let context = React.createContext(None);

     module Provider = {
       let make = React.Context.provider(context);
     };
   };

   let initialCache = JsMap.make();

   [@react.component]
   let make = () => {
     let (cache, setCache) = React.useState(() => initialCache);
     let (location, setLocation) =
       React.useState(() =>
         {
           selectedId: None,
           isEditing: false,
           searchText: "",
         }
       );

     let locationKey = location;
     let content = cache->JsMap.get(locationKey);

     let content =
       switch (content) {
       | Some(c) => c
       | None =>
         let url = "/react?location=" ++ locationToString(locationKey);
         let content = ReactServer.createFromFetch(Webapi.Fetch.fetch(url));
         cache->JsMap.set(locationKey, content);
         content;
       };

     let%browser_only refresh = response => {
       React.startTransition(() => {
         let nextCache = JsMap.make();
         switch (response) {
         | Some(response) =>
           let locationKey =
             Webapi.Fetch.Response.headers(response)
             ->Webapi.Fetch.Headers.get("X-Location");
           let nextLocation =
             switch (locationKey) {
             | Some(key) => key->Js.Json.parseExn
             | None => location
             };
           let nextContent =
             ReactServer.createFromReadableStream(
               Webapi.Fetch.Response.body(response),
             );
           nextCache->JsMap.set(Js.Json.stringify(nextLocation), nextContent);
           setLocation(_ => nextLocation);
         | None => ()
         };
         setCache(_ => nextCache);
       });
     };

     let%browser_only navigate = nextLocation => {
       React.startTransition(() => setLocation(loc => nextLocation));
     };

     <RouterContext.Provider
       value={
         Some({
           location,
           navigate,
           refresh,
         })
       }>
       {ReactServer.use(content)}
     </RouterContext.Provider>;
   };
    */
