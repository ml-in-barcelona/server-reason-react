open Melange_json.Primitives;

[@react.client.component]
let make = (~noteId: int, ~children: React.element) => {
  let (isPending, startTransition) = React.useTransition();
  let navigate = Router.use();

  <button
    className=Theme.button
    disabled=isPending
    onClick={_ => {
      startTransition(() => {
        navigate("/demo/router/" ++ Int.to_string(noteId) ++ "/edit")
      })
    }}
    role="menuitem">
    children
  </button>;
};
