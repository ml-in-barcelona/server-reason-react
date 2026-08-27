[@react.client.component]
let make = (~id: NoteId.t) => {
  let (isDeleting, setIsDeleting) = RR.useStateValue(false);
  let (navigate, navigation) = Router.useNavigation();
  let ({ Router.text }, _) = Router.useSearch();
  let isNavigating =
    switch (navigation) {
    | Router.Navigation.Loading(_) => true
    | Router.Navigation.Idle
    | Router.Navigation.Failed(_) => false
    };
  let%browser_only onClick = _ => {
    setIsDeleting(true);
    ServerFunctions.Notes.delete_.call(~id)
    |> Js.Promise.then_(_ => {
         setIsDeleting(false);
         navigate(
           ~history=Router.Navigation.Replace,
           ~revalidate=true,
           Router.Home.destination(~text?, ()),
         )
         |> ignore;
         Js.Promise.resolve();
       })
    |> ignore;
  };

  <button className=Theme.button disabled={isNavigating || isDeleting} onClick>
    {React.string("Delete")}
  </button>;
};
