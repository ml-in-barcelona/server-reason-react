open Melange_json.Primitives;

[@react.client.component]
let make = (~noteId: int) => {
  let (isNavigating, startNavigating) = React.useTransition();
  let (isDeleting, setIsDeleting) = RR.useStateValue(false);
  let {Router.navigate, url, _} = Router.use();
  let className = Theme.button;

  <button
    className
    disabled={isNavigating || isDeleting}
    onClick={_ => {
      ServerFunctions.Notes.delete_.call(~id=noteId)
      |> Js.Promise.then_(_ => {
           setIsDeleting(false);
           let queryParams =
             switch (url |> URL.searchParams |> URL.SearchParams.toString) {
             | "" => ""
             | queryParams => "?" ++ queryParams
             };

           startNavigating(() => {
             navigate(~revalidate=true, "/demo/router" ++ queryParams)
           });
           Js.Promise.resolve();
         })
      |> ignore
    }}
    role="menuitem">
    {React.string("Delete")}
  </button>;
};
