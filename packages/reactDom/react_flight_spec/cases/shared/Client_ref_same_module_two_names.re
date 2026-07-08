/* Same module, two different export names: dedup must be per (module, name),
   not per module — two I rows. React keys writtenClientReferences on the full
   "<module>#<name>" id; srr keys on (import_module, import_name). */
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
