[@react.component]
let make = (~noteId: option(string), ~children) => {
  let (isPending, startTransition) = React.useTransition();
  let {navigate, _}: Router.t = Router.useRouter();
  let isDraft = Belt.Option.isNone(noteId);

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
