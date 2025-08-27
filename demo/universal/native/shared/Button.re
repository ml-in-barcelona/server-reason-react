open Melange_json.Primitives;

[@react.client.component]
let make = (~noteId: option(int), ~children: React.element) => {
  let (isPending, startTransition) = React.useTransition();
  let navigate = DummyClientRouter.useNavigate();

  <button
    className=Theme.button
    disabled=isPending
    onClick={_ => {
      startTransition(() => {
        navigate({
          selectedId: noteId,
          isEditing: true,
          searchText: None,
        })
      })
    }}
    role="menuitem">
    children
  </button>;
};
