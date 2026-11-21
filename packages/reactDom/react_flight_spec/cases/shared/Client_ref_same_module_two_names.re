let app = () =>
  <>
    {Spec.client_component(
       ~importModule="spec/Button.js",
       ~importName="Primary",
       (),
     )}
    {Spec.client_component(
       ~importModule="spec/Button.js",
       ~importName="Secondary",
       (),
     )}
  </>;
