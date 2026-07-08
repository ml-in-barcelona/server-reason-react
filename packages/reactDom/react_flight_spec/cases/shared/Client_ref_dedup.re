/* The SAME client reference (same module + export name) used twice: exactly
   one I row is emitted, and both elements reference it. React dedups on the
   reference id ("<module>#<name>"); srr on (import_module, import_name). */
let button = () =>
  Spec.client_component(
    ~importModule="spec/Button.js",
    ~importName="default",
    (),
  );

let app = () => <> {button()} {button()} </>;
