let app = () =>
  <>
    {Spec.client_component(
       ~importModule="spec/Button.js",
       ~importName="default",
       (),
     )}
    {Spec.client_component(
       ~importModule="spec/Link.js",
       ~importName="default",
       (),
     )}
  </>;
