open Melange_json.Primitives;

[@warning "-26-27-32"];
[@react.client.component]
let make = (~noteId: int) => {
  let (isNavigating, startNavigating) = React.useTransition();
  let (isDeleting, setIsDeleting) = RR.useStateValue(false);
  let {navigate, _}: ClientRouter.t = ClientRouter.useRouter();

  let className = Theme.button;

  <button
    className
    disabled={isNavigating || isDeleting}
    onClick=[%browser_only
      _ => {
        Actions.Notes.delete(noteId)
        |> Js.Promise.then_(_ => {
             setIsDeleting(false);
             startNavigating(() => {
               navigate({
                 selectedId: None,
                 isEditing: false,
                 searchText: None,
               })
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
