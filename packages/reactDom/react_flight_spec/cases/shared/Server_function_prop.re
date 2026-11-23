let app = () => {
  let save = Spec.server_function(~id="spec/actions#save");
  Spec.client_component(
    ~importModule="spec/Form.js",
    ~importName="Form",
    ~props=[Spec.server_function_prop("onSave", save)],
    (),
  );
};
