/* include Router;

   module React = {
     include React;

     [@mel.module "react"]
     external startTransition: (unit => unit) => unit = "startTransition";
   };

   module ReactServerDom = {
     [@mel.module "react-server-dom-webpack/client"]
     external createFromFetch:
       Js.Promise.t(Fetch.response) => Js.Promise.t(React.element) =
       "createFromFetch";
     [@mel.module "react-server-dom-webpack/client"]
     external createFromReadableStream:
       Webapi.ReadableStream.t => Js.Promise.t(React.element) =
       "createFromReadableStream";
   };

   module RouterContext = {
     let context = React.createContext(None);

     module Provider = {
       include React.Context;
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
           searchText: None,
         }
       );

     let locationKey = locationToString(location);
     let content = React.useRef(cache->JsMap.get(locationKey));

     switch (content.current) {
     | Some(_c) => ()
     | None =>
       let url = "/demo/router?location=" ++ locationKey;
       let headers =
         Fetch.HeadersInit.make({"Accept": "application/react.component"});
       let fetch =
         Fetch.fetchWithInit(url, Fetch.RequestInit.make(~headers, ()));
       let element = ReactServerDom.createFromFetch(fetch);
       Js.log(locationKey);
       cache->JsMap.set(locationKey, element);
       Js.log(cache);
       content.current = Some(element);
     };

     let%browser_only refresh = response => {
       React.startTransition(() => {
         let nextCache = JsMap.make();
         switch (response) {
         | Some(response) =>
           let xLocation =
             Fetch.Response.headers(response) |> Fetch.Headers.get("X-Location");
           let nextLocation =
             switch (xLocation) {
             | Some(key) => key
             | None => locationKey
             };
           let readableStream = Fetch.Response.body(response);
           let nextContent =
             ReactServerDom.createFromReadableStream(readableStream);
           nextCache->JsMap.set(nextLocation, nextContent);
           setLocation(_ => locationFromString(nextLocation));
         | None => ()
         };
         setCache(_ => nextCache);
       });
     };

     let%browser_only navigate = nextLocation => {
       React.startTransition(() => setLocation(_loc => nextLocation));
     };

     <RouterContext.Provider
       value={
         Some({
           location,
           navigate,
           refresh,
         })
       }>
       {switch (content.current) {
        | Some(c) => React.Experimental.use(c)
        | None => React.null
        }}
     </RouterContext.Provider>;
   };
    */

type t = Router.t(Fetch.Response.t);

external navigate: string => unit = "window.__navigate_rsc";

let useRouter: unit => t =
  () => {
    {
      location: Router.initialLocation,
      refresh: str => Js.log(str),
      navigate: str => {
        navigate(Router.locationToString(str));
      },
    };
  };
