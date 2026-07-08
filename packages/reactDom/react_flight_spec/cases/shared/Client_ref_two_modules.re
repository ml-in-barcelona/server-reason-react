/* Two DIFFERENT client components: two I rows, numbered in the order the
   references are first encountered during serialization. */
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
