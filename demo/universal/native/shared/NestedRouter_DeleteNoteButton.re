open Melange_json.Primitives;
module DOM = Webapi.Dom;
module Location = DOM.Location;
module Window = DOM.Window;

[@react.client.component]
let make = (~noteId: int) => {
  let (isNavigating, startNavigating) = React.useTransition();
  let (isDeleting, setIsDeleting) = RR.useStateValue(false);
  let navigate = Router.use();
  let className = Theme.button;

  <button
    className
    disabled={isNavigating || isDeleting}
    onClick=[%browser_only
      _ => {
        ServerFunctions.Notes.delete_.call(~id=noteId)
        |> Js.Promise.then_(_ => {
             setIsDeleting(false);
             let url =
               URL.makeExn(Location.href(DOM.window->DOM.Window.location));
             let queryParams =
               switch (url |> URL.searchParams |> URL.SearchParams.toString) {
               | "" => ""
               | queryParams => "?" ++ queryParams
               };

             startNavigating(() => {
               navigate(
                 ~revalidate=true,
                 ~replace=true,
                 "/demo/router" ++ queryParams,
               )
             });
             Js.Promise.resolve();
           })
        |> ignore;
      }
    ]
    role="menuitem">
    {React.string("Delete")}
  </button>;
};
