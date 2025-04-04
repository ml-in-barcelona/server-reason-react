open Melange_json.Primitives;

[@react.client.component]
let make = (~noteId: option(int), ~children: React.element) => {
  let (isPending, startTransition) = React.useTransition();
  let {navigate, _}: ClientRouter.t = ClientRouter.useRouter();
  let isDraft = Belt.Option.isNone(noteId);

  let className =
    Cx.make([
      Theme.button,
      isDraft ? "edit-button--solid" : "edit-button--outline",
    ]);

  <button
    className
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
