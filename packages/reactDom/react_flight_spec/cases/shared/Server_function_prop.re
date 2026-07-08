/* A server function as a client-component prop: one outlined
   {"id":"<id>","bound":null} row plus a "$F<hexid>" reference in the props.
   React outlines the row synchronously (outlineModel), so it flushes before
   the element row that references it. */
let app = () => {
  let save = Spec.server_function(~id="spec/actions#save");
  Spec.client_component(
    ~importModule="spec/Form.js",
    ~importName="Form",
    ~props=[Spec.server_function_prop("onSave", save)],
    (),
  );
};
