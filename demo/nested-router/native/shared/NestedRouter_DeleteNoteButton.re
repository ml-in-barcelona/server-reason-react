[@react.client.component]
let make = (~id: NoteId.t) => {
  let (isDeleting, setIsDeleting) = RR.useStateValue(false);
  let navigate = Router.useNavigate();
  let navigation = Router.useNavigation();
  let { Router.searchText } = Router.useSearch();
  let isNavigating =
    switch (navigation) {
    | Router.Navigation.Loading(_) => true
    | Router.Navigation.Idle
    | Router.Navigation.Failed(_) => false
    };
  let options: RouterRuntime.Link.options = {
    ...RouterRuntime.Link.defaultOptions,
    history: RouterRuntime.Navigation.Replace,
    revalidate: true,
  };

  let%browser_only onClick = _ => {
    setIsDeleting(true);
    ServerFunctions.Notes.delete_.call(~id=NoteId.toInt(id))
    |> Js.Promise.then_(_ => {
         setIsDeleting(false);
         switch (navigate) {
         | Some(navigate) =>
           navigate(~options, Router.Home.destination(~searchText?, ()))
           |> ignore
         | None => ()
         };
         Js.Promise.resolve();
       })
    |> ignore;
  };

  <button className=Theme.button disabled={isNavigating || isDeleting} onClick>
    {React.string("Delete")}
  </button>;
};
