/* Two DIFFERENT server functions as props: each gets its own outlined row,
   numbered in serialization order. */
let app = () => {
  let save = Spec.server_function(~id="spec/actions#save");
  let remove = Spec.server_function(~id="spec/actions#remove");
  Spec.client_component(
    ~importModule="spec/Form.js",
    ~importName="Form",
    ~props=[
      Spec.server_function_prop("onSave", save),
      Spec.server_function_prop("onRemove", remove),
    ],
    (),
  );
};
