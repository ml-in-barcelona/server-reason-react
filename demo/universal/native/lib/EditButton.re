open Ppx_deriving_json_runtime.Primitives;

[@react.client.component]
let make = (~noteId: option(int), ~children: React.element) => {
  let (isPending, startTransition) = React.useTransition();
  let {navigate, _}: ClientRouter.t = ClientRouter.useRouter();
  let isDraft = Belt.Option.isNone(noteId);

  React.useEffect(() => {
    Js.log("EDIT BUTTON MOUNTED");
    None;
  });

  let className =
    Js.Array.join(
      ~sep=" ",
      [|
        "edit-button",
        Theme.text(Theme.Color.white),
        isDraft ? "edit-button--solid" : "edit-button--outline",
      |],
    );

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
