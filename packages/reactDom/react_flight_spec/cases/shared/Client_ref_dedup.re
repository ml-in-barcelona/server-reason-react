let button = () =>
  Spec.client_component(
    ~importModule="spec/Button.js",
    ~importName="default",
    (),
  );

let app = () => <> {button()} {button()} </>;
