/* A server function nested inside an object prop: the containing object is
   inlined into the props while the function itself is still outlined as an
   {"id","bound"} row referenced with "$F". */
let app = () => {
  let save = Spec.server_function(~id="spec/actions#save");
  Spec.client_component(
    ~importModule="spec/Form.js",
    ~importName="Form",
    ~props=[
      Spec.object_(
        "handlers",
        [
          ("save", Spec.model_server_function(save)),
          ("label", Spec.model_string("Save")),
        ],
      ),
    ],
    (),
  );
};
