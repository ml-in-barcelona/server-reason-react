[@react.client.component]
let make = (~children: React.element) => {
  let navigate = Router.use();
  let (isPending, startTransition) = React.useTransition();

  <button
    className=Theme.button
    disabled=isPending
    onClick={_ => {startTransition(() => {navigate("/demo/router/new")})}}
    role="menuitem">
    children
  </button>;
};
