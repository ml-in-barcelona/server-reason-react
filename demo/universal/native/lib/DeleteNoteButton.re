open Ppx_deriving_json_runtime.Primitives;

let%browser_only deleteNote = (~id) => {
  let currentURL = Router.demoActionDeleteNote;
  let encodeArgs =
    "{"
    ++ String.concat(
         ",",
         List.map(
           ((key, value)) => key ++ ":" ++ value,
           [
             (
               "id",
               // This to_string and string_to_json is not necessary
               // I'm just simulating encoding args
               Ppx_deriving_json_runtime.to_string(int_to_json(id)),
             ),
           ],
         ),
       )
    ++ "}";
  FetchHelpers.fetchAction(currentURL, encodeArgs);
};

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
        setIsDeleting(true);

        deleteNote(~id=noteId)
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
